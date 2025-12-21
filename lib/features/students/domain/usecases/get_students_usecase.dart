import 'package:injectable/injectable.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';

@injectable
class GetStudentsUseCase {
  final StudentRepository _repository;

  GetStudentsUseCase(this._repository);

  Future<List<StudentEntity>> call(String classId) {
    return _repository.getStudentsByClassId(classId);
  }
}
