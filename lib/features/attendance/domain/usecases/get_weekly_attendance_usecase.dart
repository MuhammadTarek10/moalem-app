import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/features/attendance/domain/entities/weekly_attendance_entity.dart';
import 'package:moalem/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';

/// Use case to get weekly attendance for all students in a class
@injectable
class GetWeeklyAttendanceUseCase {
  final AttendanceRepository _attendanceRepository;
  final StudentRepository _studentRepository;

  GetWeeklyAttendanceUseCase(
    this._attendanceRepository,
    this._studentRepository,
  );

  /// Execute the use case
  /// Returns a map of studentId -> WeeklyAttendanceEntity
  Future<Map<String, WeeklyAttendanceEntity>> call({
    required String classId,
    required DateTime weekStartDate,
  }) async {
    // Get all students in the class
    final students = await _studentRepository.getStudentsByClassId(classId);

    // Get week end date (Thursday)
    final weekEndDate = WeekHelper.getWeekEnd(weekStartDate);

    // Get all attendance records for the class in this week
    final attendanceRecords = await _attendanceRepository
        .getAttendanceByDateRange(
          classId: classId,
          startDate: weekStartDate,
          endDate: weekEndDate,
        );

    // Group records by student
    final Map<String, WeeklyAttendanceEntity> result = {};

    for (final student in students) {
      final studentRecords = attendanceRecords
          .where((record) => record.studentId == student.id)
          .toList();

      final Map<DateTime, AttendanceStatus> dailyAttendance = {};
      for (final record in studentRecords) {
        final normalizedDate = DateTime(
          record.date.year,
          record.date.month,
          record.date.day,
        );
        dailyAttendance[normalizedDate] = record.status;
      }

      result[student.id] = WeeklyAttendanceEntity(
        studentId: student.id,
        classId: classId,
        weekStartDate: weekStartDate,
        dailyAttendance: dailyAttendance,
      );
    }

    return result;
  }

  /// Get weekly attendance with student entities for display
  Future<List<StudentWeeklyAttendance>> getWithStudents({
    required String classId,
    required DateTime weekStartDate,
  }) async {
    final students = await _studentRepository.getStudentsByClassId(classId);
    final weeklyAttendance = await call(
      classId: classId,
      weekStartDate: weekStartDate,
    );

    return students.map((student) {
      return StudentWeeklyAttendance(
        student: student,
        weeklyAttendance:
            weeklyAttendance[student.id] ??
            WeeklyAttendanceEntity(
              studentId: student.id,
              classId: classId,
              weekStartDate: weekStartDate,
              dailyAttendance: {},
            ),
      );
    }).toList();
  }
}

/// Composite class for student with their weekly attendance
class StudentWeeklyAttendance {
  final StudentEntity student;
  final WeeklyAttendanceEntity weeklyAttendance;

  const StudentWeeklyAttendance({
    required this.student,
    required this.weeklyAttendance,
  });
}
