import 'package:injectable/injectable.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';

@injectable
class GetStudentsByClassIdUseCase {
  final StudentRepository _repository;

  GetStudentsByClassIdUseCase(this._repository);

  Future<List<StudentEntity>> call(String classId) {
    return _repository.getStudentsByClassId(classId);
  }
}
