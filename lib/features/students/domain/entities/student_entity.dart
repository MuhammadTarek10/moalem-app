class StudentEntity {
  final String id;
  final String classId;
  final String name;
  final int number;
  final String qrCode;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const StudentEntity({
    required this.id,
    required this.classId,
    required this.name,
    required this.number,
    required this.qrCode,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  StudentEntity copyWith({
    String? id,
    String? classId,
    String? name,
    int? number,
    String? qrCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return StudentEntity(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      number: number ?? this.number,
      qrCode: qrCode ?? this.qrCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Converts to map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_id': classId,
      'name': name,
      'number': number.toString(),
      'qr_code': qrCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  /// Creates entity from database map
  factory StudentEntity.fromMap(Map<String, dynamic> map) {
    return StudentEntity(
      id: map['id'] as String,
      classId: map['class_id'] as String,
      name: map['name'] as String,
      number: int.parse(map['number'] as String),
      qrCode: map['qr_code'] as String,
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
    return other is StudentEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
