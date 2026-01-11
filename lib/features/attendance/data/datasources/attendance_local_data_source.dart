import 'package:injectable/injectable.dart';
import 'package:moalem/core/services/database_service.dart';
import 'package:moalem/features/attendance/domain/entities/daily_attendance_entity.dart';

/// Local data source for attendance operations using SQLite
@injectable
class AttendanceLocalDataSource {
  final DatabaseService _databaseService;

  AttendanceLocalDataSource(this._databaseService);

  /// Get attendance records for a class within a date range
  Future<List<DailyAttendanceEntity>> getAttendanceByDateRange({
    required String classId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _databaseService.database;
    final startDateStr = _formatDate(startDate);
    final endDateStr = _formatDate(endDate);

    final results = await db.query(
      'daily_attendance',
      where: 'class_id = ? AND date >= ? AND date <= ?',
      whereArgs: [classId, startDateStr, endDateStr],
      orderBy: 'date ASC',
    );

    return results.map((map) => DailyAttendanceEntity.fromMap(map)).toList();
  }

  /// Get attendance record for a specific student on a specific date
  Future<DailyAttendanceEntity?> getAttendanceByStudentAndDate({
    required String studentId,
    required DateTime date,
  }) async {
    final db = await _databaseService.database;
    final dateStr = _formatDate(date);

    final results = await db.query(
      'daily_attendance',
      where: 'student_id = ? AND date = ?',
      whereArgs: [studentId, dateStr],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return DailyAttendanceEntity.fromMap(results.first);
  }

  /// Get all attendance records for a student within a date range
  Future<List<DailyAttendanceEntity>> getStudentAttendanceByDateRange({
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _databaseService.database;
    final startDateStr = _formatDate(startDate);
    final endDateStr = _formatDate(endDate);

    final results = await db.query(
      'daily_attendance',
      where: 'student_id = ? AND date >= ? AND date <= ?',
      whereArgs: [studentId, startDateStr, endDateStr],
      orderBy: 'date ASC',
    );

    return results.map((map) => DailyAttendanceEntity.fromMap(map)).toList();
  }

  /// Save or update an attendance record (upsert)
  Future<void> saveAttendance(DailyAttendanceEntity attendance) async {
    final db = await _databaseService.database;

    // Check if record exists
    final existing = await getAttendanceByStudentAndDate(
      studentId: attendance.studentId,
      date: attendance.date,
    );

    if (existing != null) {
      // Update existing record
      await db.update(
        'daily_attendance',
        attendance.copyWith(id: existing.id, updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      // Insert new record
      await db.insert('daily_attendance', attendance.toMap());
    }
  }

  /// Save multiple attendance records in a batch
  Future<void> saveAttendanceBatch(List<DailyAttendanceEntity> records) async {
    final db = await _databaseService.database;

    await db.transaction((txn) async {
      for (final record in records) {
        // Check if exists
        final existing = await txn.query(
          'daily_attendance',
          where: 'student_id = ? AND date = ?',
          whereArgs: [record.studentId, _formatDate(record.date)],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          // Update
          await txn.update(
            'daily_attendance',
            record
                .copyWith(
                  id: existing.first['id'] as String,
                  updatedAt: DateTime.now(),
                )
                .toMap(),
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
        } else {
          // Insert
          await txn.insert('daily_attendance', record.toMap());
        }
      }
    });
  }

  /// Delete an attendance record
  Future<void> deleteAttendance(String id) async {
    final db = await _databaseService.database;
    await db.delete('daily_attendance', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all attendance records for a specific date and class
  Future<void> deleteAttendanceByDateAndClass({
    required String classId,
    required DateTime date,
  }) async {
    final db = await _databaseService.database;
    final dateStr = _formatDate(date);

    await db.delete(
      'daily_attendance',
      where: 'class_id = ? AND date = ?',
      whereArgs: [classId, dateStr],
    );
  }

  /// Format date as YYYY-MM-DD for storage
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
