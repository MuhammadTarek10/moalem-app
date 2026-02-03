import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';

class ClassFormData {
  final String? id;
  final String? educationalStage;
  final String? gradeLevel;
  final String? className;
  final String? subject;
  final String? semester;
  final String? school;

  final EvaluationGroup? evaluationGroup;

  const ClassFormData({
    this.id,
    this.educationalStage,
    this.gradeLevel,
    this.className,
    this.subject,
    this.semester,
    this.school,
    this.evaluationGroup,
  });

  bool get isEditing => id != null;

  ClassFormData copyWith({
    String? id,
    String? educationalStage,
    String? gradeLevel,
    String? className,
    String? subject,
    String? semester,
    String? school,
    EvaluationGroup? evaluationGroup,
  }) {
    return ClassFormData(
      id: id ?? this.id,
      educationalStage: educationalStage ?? this.educationalStage,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      className: className ?? this.className,
      subject: subject ?? this.subject,
      semester: semester ?? this.semester,
      school: school ?? this.school,
      evaluationGroup: evaluationGroup ?? this.evaluationGroup,
    );
  }

  bool get isValid =>
      educationalStage != null &&
      educationalStage!.isNotEmpty &&
      gradeLevel != null &&
      gradeLevel!.isNotEmpty &&
      className != null &&
      className!.isNotEmpty &&
      subject != null &&
      subject!.isNotEmpty &&
      semester != null &&
      semester!.isNotEmpty &&
      school != null &&
      school!.isNotEmpty &&
      evaluationGroup != null;

  /// Creates a ClassFormData from a ClassEntity for editing
  factory ClassFormData.fromEntity(ClassEntity entity) {
    return ClassFormData(
      id: entity.id,
      gradeLevel: entity.grade,
      educationalStage: null, // Will be derived in the UI from evaluationGroup
      className: entity.name,
      subject: entity.subject,
      semester: entity.semester,
      school: entity.school,
      evaluationGroup: entity.evaluationGroup,
    );
  }

  /// Converts to ClassEntity for updating (requires existing entity for metadata)
  ClassEntity toEntity(ClassEntity existingEntity) {
    return existingEntity.copyWith(
      name: className,
      grade: gradeLevel,
      subject: subject,
      semester: semester,
      school: school,
    );
  }
}
