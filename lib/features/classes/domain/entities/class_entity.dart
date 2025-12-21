class ClassEntity {
  final String id;
  final String name;
  final String grade;
  final String subject;
  final String semester;
  final String school;
  final int studentsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const ClassEntity({
    required this.id,
    required this.name,
    required this.grade,
    required this.subject,
    required this.semester,
    required this.school,
    this.studentsCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  ClassEntity copyWith({
    String? id,
    String? name,
    String? grade,
    String? subject,
    String? semester,
    String? school,
    int? studentsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ClassEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      subject: subject ?? this.subject,
      semester: semester ?? this.semester,
      school: school ?? this.school,
      studentsCount: studentsCount ?? this.studentsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Converts to map for database insertion (excludes computed fields)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'subject': subject,
      'semester': semester,
      'school': school,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  /// Creates entity from database map (includes computed students_count)
  factory ClassEntity.fromMap(Map<String, dynamic> map) {
    return ClassEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      grade: map['grade'] as String,
      subject: map['subject'] as String,
      semester: map['semester'] as String,
      school: map['school'] as String,
      studentsCount: (map['students_count'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
