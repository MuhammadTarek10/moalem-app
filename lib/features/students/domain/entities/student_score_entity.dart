import 'package:moalem/core/constants/app_enums.dart';

class StudentScoreEntity {
  final String id;
  final String studentId;
  final String evaluationId;
  final int score;
  final PeriodType periodType;
  final int periodNumber;
  final AttendanceStatus? attendanceStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const StudentScoreEntity({
    required this.id,
    required this.studentId,
    required this.evaluationId,
    required this.score,
    required this.periodType,
    required this.periodNumber,
    this.attendanceStatus,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  StudentScoreEntity copyWith({
    String? id,
    String? studentId,
    String? evaluationId,
    int? score,
    PeriodType? periodType,
    int? periodNumber,
    AttendanceStatus? attendanceStatus,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentScoreEntity(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      evaluationId: evaluationId ?? this.evaluationId,
      score: score ?? this.score,
      periodType: periodType ?? this.periodType,
      periodNumber: periodNumber ?? this.periodNumber,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts to map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'evaluation_id': evaluationId,
      'score': score,
      'period_type': periodType.name,
      'period_number': periodNumber,
      'attendance_status': attendanceStatus?.name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Creates entity from database map
  factory StudentScoreEntity.fromMap(Map<String, dynamic> map) {
    return StudentScoreEntity(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      evaluationId: map['evaluation_id'] as String,
      score: map['score'] as int,
      periodType: PeriodType.values.byName(map['period_type'] as String),
      periodNumber: map['period_number'] as int,
      attendanceStatus: map['attendance_status'] != null
          ? AttendanceStatus.values.byName(map['attendance_status'] as String)
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentScoreEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
