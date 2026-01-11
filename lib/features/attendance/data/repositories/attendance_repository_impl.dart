import 'package:injectable/injectable.dart';
import 'package:moalem/features/attendance/data/datasources/attendance_local_data_source.dart';
import 'package:moalem/features/attendance/domain/entities/daily_attendance_entity.dart';
import 'package:moalem/features/attendance/domain/repositories/attendance_repository.dart';

/// Implementation of AttendanceRepository using local data source
@Injectable(as: AttendanceRepository)
class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceLocalDataSource _localDataSource;

  AttendanceRepositoryImpl(this._localDataSource);

  @override
  Future<List<DailyAttendanceEntity>> getAttendanceByDateRange({
    required String classId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _localDataSource.getAttendanceByDateRange(
      classId: classId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<DailyAttendanceEntity?> getAttendanceByStudentAndDate({
    required String studentId,
    required DateTime date,
  }) {
    return _localDataSource.getAttendanceByStudentAndDate(
      studentId: studentId,
      date: date,
    );
  }

  @override
  Future<List<DailyAttendanceEntity>> getStudentAttendanceByDateRange({
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _localDataSource.getStudentAttendanceByDateRange(
      studentId: studentId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<void> saveAttendance(DailyAttendanceEntity attendance) {
    return _localDataSource.saveAttendance(attendance);
  }

  @override
  Future<void> saveAttendanceBatch(List<DailyAttendanceEntity> records) {
    return _localDataSource.saveAttendanceBatch(records);
  }

  @override
  Future<void> deleteAttendance(String id) {
    return _localDataSource.deleteAttendance(id);
  }

  @override
  Future<void> deleteAttendanceByDateAndClass({
    required String classId,
    required DateTime date,
  }) {
    return _localDataSource.deleteAttendanceByDateAndClass(
      classId: classId,
      date: date,
    );
  }
}
