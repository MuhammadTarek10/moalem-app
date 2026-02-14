import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/features/students/domain/entities/student_score_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';

@injectable
class GetScoresByClassAndEvaluationUseCase {
  final StudentRepository _repository;

  GetScoresByClassAndEvaluationUseCase(this._repository);

  Future<List<StudentScoreEntity>> call(
    String classId,
    String evaluationId,
    PeriodType periodType,
    int periodNumber,
  ) {
    return _repository.getScoresByClassAndEvaluation(
      classId,
      evaluationId,
      periodType,
      periodNumber,
    );
  }
}
