import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/features/attendance/domain/entities/daily_attendance_entity.dart';
import 'package:moalem/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:uuid/uuid.dart';

/// Use case to save attendance records
@injectable
class SaveAttendanceUseCase {
  final AttendanceRepository _attendanceRepository;

  SaveAttendanceUseCase(this._attendanceRepository);

  /// Save a single attendance record
  Future<void> call({
    required String studentId,
    required String classId,
    required DateTime date,
    required AttendanceStatus status,
  }) async {
    final attendance = DailyAttendanceEntity(
      id: const Uuid().v4(),
      studentId: studentId,
      classId: classId,
      date: DateTime(date.year, date.month, date.day),
      status: status,
      createdAt: DateTime.now(),
    );

    await _attendanceRepository.saveAttendance(attendance);
  }

  /// Save multiple attendance records for a day (all students in a class)
  Future<void> saveForDay({
    required String classId,
    required DateTime date,
    required Map<String, AttendanceStatus>
    studentStatuses, // studentId -> status
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final records = studentStatuses.entries.map((entry) {
      return DailyAttendanceEntity(
        id: const Uuid().v4(),
        studentId: entry.key,
        classId: classId,
        date: normalizedDate,
        status: entry.value,
        createdAt: DateTime.now(),
      );
    }).toList();

    await _attendanceRepository.saveAttendanceBatch(records);
  }

  /// Save multiple attendance records for a week (all students, all days)
  Future<void> saveForWeek({
    required String classId,
    required Map<String, Map<DateTime, AttendanceStatus>>
    studentDayStatuses, // studentId -> (date -> status)
  }) async {
    final List<DailyAttendanceEntity> records = [];

    for (final studentEntry in studentDayStatuses.entries) {
      final studentId = studentEntry.key;
      for (final dayEntry in studentEntry.value.entries) {
        final date = dayEntry.key;
        final status = dayEntry.value;

        records.add(
          DailyAttendanceEntity(
            id: const Uuid().v4(),
            studentId: studentId,
            classId: classId,
            date: DateTime(date.year, date.month, date.day),
            status: status,
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    await _attendanceRepository.saveAttendanceBatch(records);
  }
}
