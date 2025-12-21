import 'package:injectable/injectable.dart';
import 'package:moalem/core/services/database_service.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/repositories/class_repository.dart';

@LazySingleton(as: ClassRepository)
class ClassRepositoryImpl implements ClassRepository {
  final DatabaseService _databaseService;

  ClassRepositoryImpl(this._databaseService);

  static const String _tableName = 'classes';
  static const String _studentsTable = 'students';

  @override
  Future<List<ClassEntity>> getClasses() async {
    final db = await _databaseService.database;

    // Query classes with student count using LEFT JOIN
    final result = await db.rawQuery('''
      SELECT 
        c.*,
        COUNT(s.id) as students_count
      FROM $_tableName c
      LEFT JOIN $_studentsTable s ON s.class_id = c.id AND s.deleted_at IS NULL
      WHERE c.deleted_at IS NULL
      GROUP BY c.id
      ORDER BY c.created_at DESC
    ''');

    return result.map((map) => ClassEntity.fromMap(map)).toList();
  }

  @override
  Future<ClassEntity?> getClassById(String id) async {
    final db = await _databaseService.database;

    // Query single class with student count
    final result = await db.rawQuery(
      '''
      SELECT 
        c.*,
        COUNT(s.id) as students_count
      FROM $_tableName c
      LEFT JOIN $_studentsTable s ON s.class_id = c.id AND s.deleted_at IS NULL
      WHERE c.id = ? AND c.deleted_at IS NULL
      GROUP BY c.id
    ''',
      [id],
    );

    if (result.isEmpty) return null;
    return ClassEntity.fromMap(result.first);
  }

  @override
  Future<ClassEntity> addClass(ClassEntity classEntity) async {
    final db = await _databaseService.database;
    await db.insert(_tableName, classEntity.toMap());
    return classEntity;
  }

  @override
  Future<ClassEntity> editClass(ClassEntity classEntity) async {
    final db = await _databaseService.database;
    final updatedEntity = classEntity.copyWith(updatedAt: DateTime.now());
    await db.update(
      _tableName,
      updatedEntity.toMap(),
      where: 'id = ?',
      whereArgs: [classEntity.id],
    );
    return updatedEntity;
  }

  @override
  Future<void> deleteClass(String id) async {
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
