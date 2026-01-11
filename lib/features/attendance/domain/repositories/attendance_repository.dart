import 'package:moalem/features/attendance/domain/entities/daily_attendance_entity.dart';

/// Repository interface for attendance operations
abstract class AttendanceRepository {
  /// Get attendance records for a class within a date range
  Future<List<DailyAttendanceEntity>> getAttendanceByDateRange({
    required String classId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get attendance record for a specific student on a specific date
  Future<DailyAttendanceEntity?> getAttendanceByStudentAndDate({
    required String studentId,
    required DateTime date,
  });

  /// Get all attendance records for a student within a date range
  Future<List<DailyAttendanceEntity>> getStudentAttendanceByDateRange({
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Save or update an attendance record
  Future<void> saveAttendance(DailyAttendanceEntity attendance);

  /// Save multiple attendance records in a batch
  Future<void> saveAttendanceBatch(List<DailyAttendanceEntity> records);

  /// Delete an attendance record
  Future<void> deleteAttendance(String id);

  /// Delete all attendance records for a specific date and class
  Future<void> deleteAttendanceByDateAndClass({
    required String classId,
    required DateTime date,
  });
}
