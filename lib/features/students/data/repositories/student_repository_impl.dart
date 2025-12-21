import 'package:injectable/injectable.dart';
import 'package:moalem/core/services/database_service.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';

@LazySingleton(as: StudentRepository)
class StudentRepositoryImpl implements StudentRepository {
  final DatabaseService _databaseService;

  StudentRepositoryImpl(this._databaseService);

  static const String _tableName = 'students';

  @override
  Future<List<StudentEntity>> getStudentsByClassId(String classId) async {
    final db = await _databaseService.database;
    final result = await db.query(
      _tableName,
      where: 'class_id = ? AND deleted_at IS NULL',
      whereArgs: [classId],
      orderBy: 'number ASC',
    );
    return result.map((map) => StudentEntity.fromMap(map)).toList();
  }

  @override
  Future<StudentEntity?> getStudentById(String id) async {
    final db = await _databaseService.database;
    final result = await db.query(
      _tableName,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return StudentEntity.fromMap(result.first);
  }

  @override
  Future<StudentEntity> addStudent(StudentEntity student) async {
    final db = await _databaseService.database;
    await db.insert(_tableName, student.toMap());
    return student;
  }

  @override
  Future<StudentEntity> editStudent(StudentEntity student) async {
    final db = await _databaseService.database;
    final updatedStudent = student.copyWith(updatedAt: DateTime.now());
    await db.update(
      _tableName,
      updatedStudent.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
    return updatedStudent;
  }

  @override
  Future<void> deleteStudent(String id) async {
    final db = await _databaseService.database;
    // Soft delete
    await db.update(
      _tableName,
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
