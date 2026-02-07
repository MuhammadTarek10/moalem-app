import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/core/constants/app_values.dart';
import 'package:moalem/core/services/database_service.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/entities/evaluation_entity.dart';
import 'package:moalem/features/students/domain/entities/student_details_entity.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:moalem/features/students/domain/entities/student_score_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

@LazySingleton(as: StudentRepository)
class StudentRepositoryImpl implements StudentRepository {
  final DatabaseService _databaseService;

  StudentRepositoryImpl(this._databaseService);

  static const String _tableName = 'students';
  static const String _studentsScoresTable = 'students_scores';
  static const String _classesTable = 'classes';
  static const String _evaluationsTable = 'evaluations';

  @override
  Future<List<StudentEntity>> getStudentsByClassId(String classId) async {
    final db = await _databaseService.database;
    final result = await db.query(
      _tableName,
      where: 'class_id = ? AND deleted_at IS NULL',
      whereArgs: [classId],
      orderBy: 'number ASC',
    );
    return result.map((map) => StudentEntity.fromMap(map)).toList();
  }

  @override
  Future<StudentEntity?> getStudentById(String id) async {
    final db = await _databaseService.database;
    final result = await db.query(
      _tableName,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return StudentEntity.fromMap(result.first);
  }

  @override
  Future<StudentEntity?> getStudentByQrCode(String qrCode) async {
    final db = await _databaseService.database;
    final result = await db.query(
      _tableName,
      where: 'qr_code = ? AND deleted_at IS NULL',
      whereArgs: [qrCode],
    );

    if (result.isEmpty) return null;
    return StudentEntity.fromMap(result.first);
  }

  @override
  Future<StudentDetailsWithScores?> getStudentDetailsWithScores(
    String studentId,
    PeriodType periodType,
    int periodNumber,
  ) async {
    final db = await _databaseService.database;

    // Get student
    final studentResult = await db.query(
      _tableName,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [studentId],
    );

    if (studentResult.isEmpty) return null;
    final student = StudentEntity.fromMap(studentResult.first);

    // Get class info
    final classResult = await db.query(
      _classesTable,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [student.classId],
    );

    if (classResult.isEmpty) return null;
    final classInfo = ClassEntity.fromMap(classResult.first);

    // High School Monthly Logic - Only for virtual UI view
    if (classInfo.evaluationGroup == EvaluationGroup.high &&
        periodType == PeriodType.monthly) {
      return _getHighSchoolDetailsWithScores(
        db,
        student,
        classInfo,
        periodNumber,
      );
    }

    // Get evaluation scores map based on class evaluation group
    final Map<String, int> evaluationScoresMap;
    switch (classInfo.evaluationGroup) {
      case EvaluationGroup.prePrimary:
        evaluationScoresMap = EvaluationValues.prePrimaryEvaluationScores;
        break;
      case EvaluationGroup.primary:
        evaluationScoresMap = EvaluationValues.primaryEvaluationScores;
        break;
      case EvaluationGroup.secondary:
        evaluationScoresMap = EvaluationValues.secondaryEvaluationScores;
        break;
      case EvaluationGroup.high:
        evaluationScoresMap = EvaluationValues.highSchoolEvaluationScores;
        break;
    }

    // Get only the evaluations that are relevant for this evaluation group
    List<String> evaluationIds = evaluationScoresMap.keys.toList();

    // CUSTOM FILTERING FOR EACH PERIOD TYPE
    if (classInfo.evaluationGroup == EvaluationGroup.primary ||
        classInfo.evaluationGroup == EvaluationGroup.secondary) {
      if (periodType == PeriodType.monthly) {
        // In Monthly mode, only show the relevant exam
        if (periodNumber == 2) {
          evaluationIds = ['first_month_exam'];
        } else if (periodNumber == 3) {
          evaluationIds = ['second_month_exam'];
        } else {
          evaluationIds = []; // No monthly exam for other months
        }
      } else if (periodType == PeriodType.weekly) {
        // In Weekly mode, hide monthly exams
        evaluationIds.remove('first_month_exam');
        evaluationIds.remove('second_month_exam');
      }
    }

    final placeholders = evaluationIds.isEmpty
        ? 'NULL'
        : evaluationIds.map((_) => '?').join(',');

    final evaluationsResult = evaluationIds.isEmpty
        ? []
        : await db.query(
            _evaluationsTable,
            where: 'name IN ($placeholders) AND deleted_at IS NULL',
            whereArgs: evaluationIds,
          );

    final evaluations = evaluationsResult.map((map) {
      final evaluationName = map['name'] as String;
      // Override max_score with the value from EvaluationValues
      final maxScore =
          evaluationScoresMap[evaluationName] ?? map['max_score'] as int;

      return EvaluationEntity.fromMap({
        ...map,
        'is_binary': (map['is_binary'] as int) == 1,
        'max_score': maxScore,
      });
    }).toList();

    // Sort evaluations to match the order in EvaluationValues
    evaluations.sort((a, b) {
      final indexA = evaluationIds.indexOf(a.name);
      final indexB = evaluationIds.indexOf(b.name);
      return indexA.compareTo(indexB);
    });

    // Map displayed Month (2, 3) to logical Monthly Period (1, 2)
    int scorePeriodNumber = periodNumber;
    if (periodType == PeriodType.monthly &&
        (classInfo.evaluationGroup == EvaluationGroup.primary ||
            classInfo.evaluationGroup == EvaluationGroup.secondary)) {
      if (periodNumber == 2) scorePeriodNumber = 1;
      if (periodNumber == 3) scorePeriodNumber = 2;
    }

    // Get scores for this student, period type, and period number
    final scoresResult = await db.query(
      _studentsScoresTable,
      where: 'student_id = ? AND period_type = ? AND period_number = ?',
      whereArgs: [studentId, periodType.name, scorePeriodNumber],
    );

    final Map<String, StudentScoreEntity> scores = {};
    for (final row in scoresResult) {
      final score = StudentScoreEntity.fromMap(row);
      scores[score.evaluationId] = score;
    }

    return StudentDetailsWithScores(
      student: student,
      classInfo: classInfo,
      evaluations: evaluations,
      scores: scores,
      currentPeriodType: periodType,
      currentPeriodNumber: periodNumber,
    );
  }

  @override
  Future<StudentEntity> addStudent(StudentEntity student) async {
    final db = await _databaseService.database;
    await db.insert(_tableName, student.toMap());
    return student;
  }

  @override
  Future<StudentEntity> editStudent(StudentEntity student) async {
    final db = await _databaseService.database;
    final updatedStudent = student.copyWith(updatedAt: DateTime.now());
    await db.update(
      _tableName,
      updatedStudent.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
    return updatedStudent;
  }

  @override
  Future<void> deleteStudent(String id) async {
    final db = await _databaseService.database;
    // Soft delete
    await db.update(
      _tableName,
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> upsertStudentScore(StudentScoreEntity score) async {
    final db = await _databaseService.database;

    if (score.evaluationId.startsWith('hv_')) {
      await _upsertHighSchoolScore(score, db);
      return;
    }

    // Map exams to their logically associated months for consistency in reports
    final evalResult = await db.query(
      _evaluationsTable,
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [score.evaluationId],
    );

    StudentScoreEntity finalScore = score;
    if (evalResult.isNotEmpty) {
      final String name = evalResult.first['name'] as String;
      if (name == 'first_month_exam') {
        finalScore = score.copyWith(
          periodType: PeriodType.monthly,
          periodNumber: 1,
        );
      } else if (name == 'second_month_exam') {
        finalScore = score.copyWith(
          periodType: PeriodType.monthly,
          periodNumber: 2,
        );
      }
    }

    await _performStandardUpsert(finalScore, db);
  }

  Future<void> _performStandardUpsert(
    StudentScoreEntity score,
    Database db,
  ) async {
    // Check if score exists for this student, evaluation, period type, and period number
    final existing = await db.query(
      _studentsScoresTable,
      where:
          'student_id = ? AND evaluation_id = ? AND period_type = ? AND period_number = ?',
      whereArgs: [
        score.studentId,
        score.evaluationId,
        score.periodType.name,
        score.periodNumber,
      ],
    );

    if (existing.isEmpty) {
      // Insert new score with generated ID if not provided
      final scoreToInsert = score.id.isEmpty
          ? score.copyWith(id: const Uuid().v4())
          : score;
      await db.insert(_studentsScoresTable, scoreToInsert.toMap());
    } else {
      // Update existing score
      final updatedScore = score.copyWith(
        id: existing.first['id'] as String,
        updatedAt: DateTime.now(),
      );
      await db.update(
        _studentsScoresTable,
        updatedScore.toMap(),
        where: 'id = ?',
        whereArgs: [updatedScore.id],
      );
    }
  }

  @override
  Future<void> deleteStudentScore(String scoreId) async {
    final db = await _databaseService.database;
    await db.delete(
      _studentsScoresTable,
      where: 'id = ?',
      whereArgs: [scoreId],
    );
  }

  Future<StudentDetailsWithScores> _getHighSchoolDetailsWithScores(
    Database db,
    StudentEntity student,
    ClassEntity classInfo,
    int month,
  ) async {
    // 1. Get raw evaluations
    final rawEvals = await db.query(
      _evaluationsTable,
      where: 'deleted_at IS NULL',
    );
    // Find the real IDs
    final evalMap = {for (var e in rawEvals) e['name']: e};

    final evWeekly = evalMap['weekly_review'];
    final evBeh = evalMap['attendance_and_diligence'];
    final evBook = evalMap['homework_book'];
    final evEx1 = evalMap['first_month_exam'];
    final evEx2 = evalMap['second_month_exam'];

    // 2. Build Virtual Evaluations
    final List<EvaluationEntity> virtualEvals = [];

    // Behavior (Monthly)
    if (evBeh != null) {
      virtualEvals.add(
        EvaluationEntity.fromMap({
          ...evBeh,
          'id': 'hv_beh_${evBeh['id']}',
          'name': 'attendance_and_diligence',
          'max_score': 10,
        }),
      );
    }
    // Notebook (Monthly)
    if (evBook != null) {
      virtualEvals.add(
        EvaluationEntity.fromMap({
          ...evBook,
          'id': 'hv_book_${evBook['id']}',
          'max_score': 15,
        }),
      );
    }

    // Exam (Depending on Month)
    if (month == 2 && evEx1 != null) {
      virtualEvals.add(
        EvaluationEntity.fromMap({
          ...evEx1,
          'id': 'hv_ex1_${evEx1['id']}',
          'max_score': 15,
        }),
      );
    } else if (month == 3 && evEx2 != null) {
      virtualEvals.add(
        EvaluationEntity.fromMap({
          ...evEx2,
          'id': 'hv_ex2_${evEx2['id']}',
          'max_score': 15,
        }),
      );
    }

    // Weekly Reviews 1-4
    if (evWeekly != null) {
      for (int i = 1; i <= 4; i++) {
        virtualEvals.add(
          EvaluationEntity.fromMap({
            ...evWeekly,
            'id': 'hv_wk${i}_${evWeekly['id']}',
            'name': 'weekly_review_w$i',
            'max_score': 15,
          }),
        );
      }
    }

    // 3. Fetch Scores
    final startWeek = (month - 1) * 4 + 1;
    final endWeek = startWeek + 3;

    final scoresResult = await db.rawQuery(
      '''
      SELECT * FROM $_studentsScoresTable 
      WHERE student_id = ? 
      AND (
        (period_number BETWEEN ? AND ?) OR
        (period_number = 1 AND period_type = 'monthly') OR
        (period_number = 2 AND period_type = 'monthly')
      )
      ''',
      [student.id, startWeek, endWeek],
    );

    final Map<String, StudentScoreEntity> scoresMap = {};

    for (final row in scoresResult) {
      final realEvalId = row['evaluation_id'];
      final realWeek = row['period_number'] as int;
      final weekOffset = realWeek - startWeek + 1; // 1..4

      // Match with virtual IDs
      if (evBeh != null && realEvalId == evBeh['id']) {
        scoresMap['hv_beh_${evBeh['id']}'] = StudentScoreEntity.fromMap(
          row,
        ).copyWith(evaluationId: 'hv_beh_${evBeh['id']}');
      } else if (evBook != null && realEvalId == evBook['id']) {
        scoresMap['hv_book_${evBook['id']}'] = StudentScoreEntity.fromMap(
          row,
        ).copyWith(evaluationId: 'hv_book_${evBook['id']}');
      } else if (evEx1 != null && realEvalId == evEx1['id']) {
        scoresMap['hv_ex1_${evEx1['id']}'] = StudentScoreEntity.fromMap(
          row,
        ).copyWith(evaluationId: 'hv_ex1_${evEx1['id']}');
      } else if (evEx2 != null && realEvalId == evEx2['id']) {
        scoresMap['hv_ex2_${evEx2['id']}'] = StudentScoreEntity.fromMap(
          row,
        ).copyWith(evaluationId: 'hv_ex2_${evEx2['id']}');
      } else if (evWeekly != null && realEvalId == evWeekly['id']) {
        // Only map if the week matches the virtual ID week offset
        // But I have wk1..wk4 virtual IDs.
        // weekOffset is 1..4.
        scoresMap['hv_wk${weekOffset}_${evWeekly['id']}'] =
            StudentScoreEntity.fromMap(
              row,
            ).copyWith(evaluationId: 'hv_wk${weekOffset}_${evWeekly['id']}');
      }
    }

    return StudentDetailsWithScores(
      student: student,
      classInfo: classInfo,
      evaluations: virtualEvals,
      scores: scoresMap,
      currentPeriodType: PeriodType.monthly,
      currentPeriodNumber: month,
    );
  }

  Future<void> _upsertHighSchoolScore(
    StudentScoreEntity score,
    Database db,
  ) async {
    // Parse Virtual ID
    final parts = score.evaluationId.split('_');
    final type = parts[1];
    // Reconstruct Real ID (everything after second underscore)
    final realEvalId = parts.sublist(2).join('_');

    // Calculate Target Weeks
    // score.periodNumber is the Month (1..3)
    final month = score.periodNumber;
    final startWeek = (month - 1) * 4 + 1;

    final List<int> targetWeeks = [];

    if (type == 'beh' || type == 'book') {
      // Save to all 4 weeks
      for (int i = 0; i < 4; i++) {
        targetWeeks.add(startWeek + i);
      }
    } else if (type.startsWith('wk')) {
      // wk1 -> offset 0
      // wk1 -> weekOffset 1.
      final offset = int.parse(type.substring(2)) - 1;
      targetWeeks.add(startWeek + offset);
    }
    if (type == 'ex1') {
      // Exam 1 physically belongs to Month 1 (Monthly)
      final scoreToSave = score.copyWith(
        evaluationId: realEvalId,
        periodType: PeriodType.monthly,
        periodNumber: 1,
        id: '',
      );
      await _performStandardUpsert(scoreToSave, db);
      return;
    } else if (type == 'ex2') {
      // Exam 2 physically belongs to Month 2 (Monthly)
      final scoreToSave = score.copyWith(
        evaluationId: realEvalId,
        periodType: PeriodType.monthly,
        periodNumber: 2,
        id: '',
      );
      await _performStandardUpsert(scoreToSave, db);
      return;
    }

    // Perform Upserts for weekly items
    for (final week in targetWeeks) {
      final realScore = score.copyWith(
        evaluationId: realEvalId,
        periodNumber: week,
        id: '', // Let upsert find existing by constraints
        periodType: PeriodType.weekly,
      );

      await _performStandardUpsert(realScore, db);
    }
  }
}
