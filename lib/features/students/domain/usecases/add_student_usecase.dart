import 'package:injectable/injectable.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';
import 'package:uuid/uuid.dart';

@injectable
class AddStudentUseCase {
  final StudentRepository _repository;

  AddStudentUseCase(this._repository);

  Future<StudentEntity> call({
    required String classId,
    required String name,
    required int number,
  }) {
    final student = StudentEntity(
      id: const Uuid().v4(),
      classId: classId,
      name: name,
      number: number,
      qrCode: const Uuid().v4(), // Generate unique QR code
      createdAt: DateTime.now(),
    );
    return _repository.addStudent(student);
  }
}
