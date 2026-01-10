import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/features/students/domain/entities/student_details_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';

@injectable
class GetStudentDetailsWithScoresUseCase {
  final StudentRepository _repository;

  GetStudentDetailsWithScoresUseCase(this._repository);

  Future<StudentDetailsWithScores?> call(
    String studentId,
    PeriodType periodType,
    int periodNumber,
  ) {
    return _repository.getStudentDetailsWithScores(
      studentId,
      periodType,
      periodNumber,
    );
  }
}
