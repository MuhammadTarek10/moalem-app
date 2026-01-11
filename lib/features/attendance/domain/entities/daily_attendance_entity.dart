import 'package:moalem/core/constants/app_enums.dart';

/// Entity representing a single day attendance record for a student
class DailyAttendanceEntity {
  final String id;
  final String studentId;
  final String classId;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const DailyAttendanceEntity({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.date,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  DailyAttendanceEntity copyWith({
    String? id,
    String? studentId,
    String? classId,
    DateTime? date,
    AttendanceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyAttendanceEntity(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      date: date ?? this.date,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts to map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'class_id': classId,
      'date': _formatDate(date),
      'attendance_status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Creates entity from database map
  factory DailyAttendanceEntity.fromMap(Map<String, dynamic> map) {
    return DailyAttendanceEntity(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      classId: map['class_id'] as String,
      date: DateTime.parse(map['date'] as String),
      status: AttendanceStatus.values.firstWhere(
        (s) => s.name == map['attendance_status'],
        orElse: () => AttendanceStatus.present,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Format date as YYYY-MM-DD for storage
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyAttendanceEntity &&
        other.id == id &&
        other.studentId == studentId &&
        other.date == date;
  }

  @override
  int get hashCode => id.hashCode ^ studentId.hashCode ^ date.hashCode;
}
