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
    final evaluationIds = evaluationScoresMap.keys.toList();
    final placeholders = evaluationIds.map((_) => '?').join(',');

    final evaluationsResult = await db.query(
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

    // Get scores for this student, period type, and period number
    final scoresResult = await db.query(
      _studentsScoresTable,
      where: 'student_id = ? AND period_type = ? AND period_number = ?',
      whereArgs: [studentId, periodType.name, periodNumber],
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
}
