import 'package:injectable/injectable.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';

@injectable
class GetStudentByIdUseCase {
  final StudentRepository _repository;

  GetStudentByIdUseCase(this._repository);

  Future<StudentEntity?> call(String studentId) {
    return _repository.getStudentById(studentId);
  }
}
