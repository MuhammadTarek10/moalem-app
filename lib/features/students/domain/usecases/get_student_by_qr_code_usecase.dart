import 'package:injectable/injectable.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';

@lazySingleton
class GetStudentByQrCodeUseCase {
  final StudentRepository repository;

  GetStudentByQrCodeUseCase(this.repository);

  Future<StudentEntity?> call(String qrCode) async {
    return await repository.getStudentByQrCode(qrCode);
  }
}
