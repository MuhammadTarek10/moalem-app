import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:moalem/core/entities/failure.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';
import 'package:uuid/uuid.dart';

@injectable
class AddStudentUseCase {
  final StudentRepository _repository;

  AddStudentUseCase(this._repository);

  Future<Either<Failure, StudentEntity>> call({
    required String classId,
    required String name,
    required int number,
  }) async {
    try {
      final students = await _repository.getStudentsByClassId(classId);
      if (students.length >= 50) {
        return const Left(StudentLimitFailure());
      }

      final id = const Uuid().v4();
      final student = StudentEntity(
        id: id,
        classId: classId,
        name: name,
        number: number,
        qrCode: id, // Use same UUID for QR code
        createdAt: DateTime.now(),
      );
      final result = await _repository.addStudent(student);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
