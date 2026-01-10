import 'package:injectable/injectable.dart';
import 'package:moalem/features/students/domain/entities/student_score_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';

@injectable
class UpdateStudentScoreUseCase {
  final StudentRepository _repository;

  UpdateStudentScoreUseCase(this._repository);

  Future<void> call(StudentScoreEntity score) {
    return _repository.upsertStudentScore(score);
  }
}
