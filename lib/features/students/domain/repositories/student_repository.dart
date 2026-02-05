import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/features/students/domain/entities/student_details_entity.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:moalem/features/students/domain/entities/student_score_entity.dart';

abstract class StudentRepository {
  Future<List<StudentEntity>> getStudentsByClassId(String classId);
  Future<StudentEntity?> getStudentById(String id);
  Future<StudentEntity?> getStudentByQrCode(String qrCode);
  Future<StudentEntity> addStudent(StudentEntity student);
  Future<StudentEntity> editStudent(StudentEntity student);
  Future<void> deleteStudent(String id);

  /// Gets student details with scores filtered by period
  Future<StudentDetailsWithScores?> getStudentDetailsWithScores(
    String studentId,
    PeriodType periodType,
    int periodNumber,
  );

  /// Upserts a student score (creates or updates)
  Future<void> upsertStudentScore(StudentScoreEntity score);

  /// Deletes a student score by id
  Future<void> deleteStudentScore(String scoreId);
}
