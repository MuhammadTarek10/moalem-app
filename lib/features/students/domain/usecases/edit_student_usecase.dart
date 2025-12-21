import 'package:injectable/injectable.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';

@injectable
class EditStudentUseCase {
  final StudentRepository _repository;

  EditStudentUseCase(this._repository);

  Future<StudentEntity> call(StudentEntity student) {
    return _repository.editStudent(student);
  }
}
