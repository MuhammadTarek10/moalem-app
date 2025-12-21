import 'package:moalem/features/students/domain/entities/student_entity.dart';

class StudentFormData {
  final String? id;
  final String? name;
  final int? number;

  const StudentFormData({this.id, this.name, this.number});

  bool get isEditing => id != null;

  StudentFormData copyWith({String? id, String? name, int? number}) {
    return StudentFormData(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
    );
  }

  bool get isValid =>
      name != null && name!.trim().isNotEmpty && number != null && number! > 0;

  /// Creates a StudentFormData from a StudentEntity for editing
  factory StudentFormData.fromEntity(StudentEntity entity) {
    return StudentFormData(
      id: entity.id,
      name: entity.name,
      number: entity.number,
    );
  }

  /// Converts to StudentEntity for updating (requires existing entity for metadata)
  StudentEntity toEntity(StudentEntity existingEntity) {
    return existingEntity.copyWith(name: name, number: number);
  }
}
