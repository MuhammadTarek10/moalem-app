import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/core/constants/app_values.dart';
import 'package:moalem/features/auth/domain/repositories/user_repository.dart';
import 'package:moalem/features/classes/domain/entities/evaluation_entity.dart';
import 'package:moalem/features/classes/domain/repositories/class_repository.dart';
import 'package:moalem/features/print/domain/entities/print_data_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';

/// Use case to generate multi-week scores report (5 weeks at a time)
@injectable
class GenerateMultiWeekScoresReportUseCase {
  final StudentRepository _studentRepository;
  final ClassRepository _classRepository;
  final UserRepository _userRepository;

  GenerateMultiWeekScoresReportUseCase(
    this._studentRepository,
    this._classRepository,
    this._userRepository,
  );

  /// Generate a multi-week scores report
  /// [classId] - The class to generate report for
  /// [weekGroup] - 1 for weeks 1-5, 2 for weeks 6-10, 3 for weeks 11-15
  /// [semesterStartDate] - The start date of the semester (first Saturday)
  Future<PrintDataEntity?> call({
    required String classId,
    required int weekGroup,
    DateTime? semesterStartDate,
  }) async {
    // Get class info
    final classEntity = await _classRepository.getClassById(classId);
    if (classEntity == null) return null;

    // Get user profile for governorate and administration
    final user = await _userRepository.getUser();
    final governorate = user.governorate ?? '';
    final administration = user.educationalAdministration ?? '';

    // Get all students in the class
    final students = await _studentRepository.getStudentsByClassId(classId);

    // Get evaluations for this class's group
    final evaluations = await _classRepository.getEvaluations();
    final filteredEvaluations = _filterEvaluationsByGroup(
      evaluations,
      classEntity.evaluationGroup,
    );

    // Calculate week numbers for this group
    final List<int> weekNumbers;
    final int startWeek;
    if (weekGroup == 0) {
      startWeek = 1;
      weekNumbers = List.generate(18, (i) => i + 1);
    } else {
      weekNumbers = PrintDataEntity.getWeekNumbersForGroup(
        weekGroup,
        classEntity.evaluationGroup,
      );
      startWeek = weekNumbers.first;
    }

    // Determine if we are in Semester 2 (Approx Feb - Aug)
    // Removed automatic offset logic to ensure we fetch exactly what is stored
    final int semesterOffset = 0;

    // Calculate week start dates
    final effectiveSemesterStart =
        semesterStartDate ?? _getDefaultSemesterStart();
    final weekStartDates = <int, DateTime>{};

    // Use weekNumbers directly
    for (final weekNum in weekNumbers) {
      weekStartDates[weekNum] = effectiveSemesterStart.add(
        Duration(days: (weekNum - 1) * 7),
      );
    }

    // Get scores for each student for all weeks
    final List<StudentPrintData> studentsData = [];

    for (final student in students) {
      final weeklyScores = <int, Map<String, int>>{};
      final weeklyTotals = <int, int>{};

      final bool isPrimaryPage4 =
          classEntity.evaluationGroup == EvaluationGroup.primary &&
          weekGroup == 4;

      final bool isPrePrimaryPage4 =
          classEntity.evaluationGroup == EvaluationGroup.prePrimary &&
          weekGroup == 4;

      // Ensure we fetch all weeks for Primary/PrePrimary Page 4 to calculate semester average
      final fetchWeeks = (isPrimaryPage4 || isPrePrimaryPage4)
          ? List.generate(18, (i) => i + 1)
          : weekNumbers;

      for (final weekNum in fetchWeeks) {
        final studentDetails = await _studentRepository
            .getStudentDetailsWithScores(
              student.id,
              PeriodType.weekly,
              weekNum,
            );

        final scores = <String, int>{};
        int totalScore = 0;

        if (studentDetails != null) {
          for (final evaluation in filteredEvaluations) {
            final score = studentDetails.getScoreForEvaluation(evaluation.id);
            scores[evaluation.id] = score;
            totalScore += score;
          }
        } else {
          // Initialize with zeros if no data
          for (final evaluation in filteredEvaluations) {
            scores[evaluation.id] = 0;
          }
        }

        weeklyScores[weekNum] = scores;
        weeklyTotals[weekNum] = totalScore;
      }

      // Fetch Monthly Exams for Primary Page 4 (March/April)
      final monthlyExamScores = <String, int>{};
      if (isPrimaryPage4) {
        // March Exam (Month 1)
        final marchDetails = await _studentRepository
            .getStudentDetailsWithScores(student.id, PeriodType.monthly, 1);
        if (marchDetails != null) {
          monthlyExamScores['first_month_exam'] = marchDetails
              .getScoreForEvaluation('first_month_exam');
        }

        // April Exam (Month 2)
        final aprilDetails = await _studentRepository
            .getStudentDetailsWithScores(student.id, PeriodType.monthly, 2);
        if (aprilDetails != null) {
          monthlyExamScores['second_month_exam'] = aprilDetails
              .getScoreForEvaluation('second_month_exam');
        }

        // Calculate or fetch average if stored?
        // Usually calculated from the two exams.
        // We'll calculate it in the Excel Config or let it be 0 if not stored.
        // If stored as 'months_exam_average', we might fetch it from PeriodType.semester?
        // Let's check PeriodType.semester for 'months_exam_average'
        final semesterDetails = await _studentRepository
            .getStudentDetailsWithScores(
              student.id,
              PeriodType.semester,
              2, // Semester 2
            );
        if (semesterDetails != null) {
          monthlyExamScores['months_exam_average'] = semesterDetails
              .getScoreForEvaluation('months_exam_average');
        }
      }

      studentsData.add(
        StudentPrintData(
          student: student,
          scores: {}, // Empty for multi-week (use weeklyScores instead)
          totalScore: 0, // Not used for multi-week
          maxPossibleScore: filteredEvaluations.fold(
            0,
            (sum, e) => sum + e.maxScore,
          ),
          weeklyScores: weeklyScores,
          weeklyTotals: weeklyTotals,
          monthlyExamScores: monthlyExamScores,
        ),
      );
    }

    return PrintDataEntity(
      printType: PrintType.scores,
      classEntity: classEntity,
      governorate: governorate,
      administration: administration,
      periodType: PeriodType.weekly,
      periodNumber: startWeek, // First week of the group
      studentsData: studentsData,
      evaluations: filteredEvaluations,
      isMultiWeek: true,
      weekGroup: weekGroup,
      weekStartDates: weekStartDates,
      semesterOffset: semesterOffset,
    );
  }

  /// Get the default semester start date (first Saturday of the current school year)
  DateTime _getDefaultSemesterStart() {
    final now = DateTime.now();
    // School year typically starts in September
    // If we're before September, use previous year's September
    final year = now.month >= 9 ? now.year : now.year - 1;
    final sept1 = DateTime(year, 9, 1);

    // Find the first Saturday on or after September 1
    int daysUntilSaturday = (DateTime.saturday - sept1.weekday) % 7;
    return sept1.add(Duration(days: daysUntilSaturday));
  }

  List<EvaluationEntity> _filterEvaluationsByGroup(
    List<EvaluationEntity> evaluations,
    EvaluationGroup group,
  ) {
    final Map<String, int> evaluationScoresMap;
    switch (group) {
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

    return evaluations
        .where((e) => evaluationScoresMap.containsKey(e.name))
        .map(
          (e) =>
              e.copyWith(maxScore: evaluationScoresMap[e.name] ?? e.maxScore),
        )
        .toList();
  }
}
