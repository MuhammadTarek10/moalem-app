import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/core/constants/app_values.dart';
import 'package:moalem/features/auth/domain/repositories/user_repository.dart';
import 'package:moalem/features/classes/domain/entities/evaluation_entity.dart';
import 'package:moalem/features/classes/domain/repositories/class_repository.dart';
import 'package:moalem/features/print/domain/entities/print_data_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';

@injectable
class GenerateScoresReportUseCase {
  final StudentRepository _studentRepository;
  final ClassRepository _classRepository;
  final UserRepository _userRepository;

  GenerateScoresReportUseCase(
    this._studentRepository,
    this._classRepository,
    this._userRepository,
  );

  Future<PrintDataEntity?> call(
    String classId,
    PeriodType periodType,
    int periodNumber,
  ) async {
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

    // Get scores for each student
    final List<StudentPrintData> studentsData = [];

    for (final student in students) {
      final studentDetails = await _studentRepository
          .getStudentDetailsWithScores(student.id, periodType, periodNumber);

      if (studentDetails != null) {
        final scores = <String, int>{};
        int totalScore = 0;

        for (final evaluation in filteredEvaluations) {
          final score = studentDetails.getScoreForEvaluation(evaluation.id);
          scores[evaluation.id] = score;
          totalScore += score;
        }

        studentsData.add(
          StudentPrintData(
            student: student,
            scores: scores,
            totalScore: totalScore,
            maxPossibleScore: studentDetails.maxPossibleScore,
          ),
        );
      }
    }

    return PrintDataEntity(
      printType: PrintType.scores,
      classEntity: classEntity,
      governorate: governorate,
      administration: administration,
      periodType: periodType,
      periodNumber: periodNumber,
      studentsData: studentsData,
      evaluations: filteredEvaluations,
    );
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
