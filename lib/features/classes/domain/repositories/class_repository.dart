import 'package:moalem/features/classes/domain/entities/class_entity.dart';

abstract class ClassRepository {
  Future<List<ClassEntity>> getClasses();
  Future<ClassEntity?> getClassById(String id);
  Future<ClassEntity> addClass(ClassEntity classEntity);
  Future<ClassEntity> editClass(ClassEntity classEntity);
  Future<void> deleteClass(String id);
}
