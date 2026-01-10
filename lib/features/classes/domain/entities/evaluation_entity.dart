class EvaluationEntity {
  final String id;
  final String name;
  final bool isBinary;
  final int maxScore;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  EvaluationEntity({
    required this.id,
    required this.name,
    required this.isBinary,
    required this.maxScore,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  EvaluationEntity copyWith({
    String? id,
    String? name,
    bool? isBinary,
    int? maxScore,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return EvaluationEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      isBinary: isBinary ?? this.isBinary,
      maxScore: maxScore ?? this.maxScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_binary': isBinary,
      'max_score': maxScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory EvaluationEntity.fromMap(Map<String, dynamic> map) {
    return EvaluationEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      isBinary: map['is_binary'] as bool,
      maxScore: map['max_score'] as int,
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
    return other is EvaluationEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
