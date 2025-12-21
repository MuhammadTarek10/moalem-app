import 'package:injectable/injectable.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';

@injectable
class DeleteStudentUseCase {
  final StudentRepository _repository;

  DeleteStudentUseCase(this._repository);

  Future<void> call(String id) {
    return _repository.deleteStudent(id);
  }
}
