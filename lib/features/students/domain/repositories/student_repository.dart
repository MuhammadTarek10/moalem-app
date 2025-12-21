import 'package:moalem/features/students/domain/entities/student_entity.dart';

abstract class StudentRepository {
  Future<List<StudentEntity>> getStudentsByClassId(String classId);
  Future<StudentEntity?> getStudentById(String id);
  Future<StudentEntity> addStudent(StudentEntity student);
  Future<StudentEntity> editStudent(StudentEntity student);
  Future<void> deleteStudent(String id);
}
