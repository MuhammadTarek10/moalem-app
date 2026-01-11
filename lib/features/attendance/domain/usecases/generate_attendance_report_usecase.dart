import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_enums.dart' as app_enums;
import 'package:moalem/features/attendance/domain/entities/weekly_attendance_entity.dart';
import 'package:moalem/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:moalem/features/auth/domain/repositories/user_repository.dart';
import 'package:moalem/features/classes/domain/repositories/class_repository.dart';
import 'package:moalem/features/print/domain/entities/print_data_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';

/// Use case to generate attendance report data for export
@injectable
class GenerateWeeklyAttendanceReportUseCase {
  final AttendanceRepository _attendanceRepository;
  final ClassRepository _classRepository;
  final StudentRepository _studentRepository;
  final UserRepository _userRepository;

  GenerateWeeklyAttendanceReportUseCase(
    this._attendanceRepository,
    this._classRepository,
    this._studentRepository,
    this._userRepository,
  );

  /// Generate print data for weekly attendance report
  Future<PrintDataEntity?> call({
    required String classId,
    required DateTime weekStartDate,
  }) async {
    // Get class info
    final classEntity = await _classRepository.getClassById(classId);
    if (classEntity == null) return null;

    // Get user profile for governorate and administration
    final user = await _userRepository.getUser();
    final governorate = user.governorate ?? '';
    final administration = user.educationalAdministration ?? '';

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

    // Build student print data
    final List<StudentPrintData> studentsData = [];

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
        dailyAttendance[normalizedDate] = _convertStatus(record.status);
      }

      studentsData.add(
        StudentPrintData(
          student: student,
          scores: {},
          attendanceDaily: dailyAttendance,
          totalScore: 0,
          maxPossibleScore: 0,
        ),
      );
    }

    return PrintDataEntity(
      printType: PrintType.attendance,
      classEntity: classEntity,
      governorate: governorate,
      administration: administration,
      periodType: app_enums.PeriodType.weekly,
      periodNumber: _getWeekNumber(weekStartDate),
      studentsData: studentsData,
      weekStartDate: weekStartDate,
    );
  }

  /// Get week number in the year (approximate)
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(firstDayOfYear).inDays;
    return (daysDifference / 7).ceil() + 1;
  }

  /// Convert app_enums.AttendanceStatus to print AttendanceStatus
  AttendanceStatus _convertStatus(app_enums.AttendanceStatus status) {
    switch (status) {
      case app_enums.AttendanceStatus.present:
        return AttendanceStatus.present;
      case app_enums.AttendanceStatus.absent:
        return AttendanceStatus.absent;
      case app_enums.AttendanceStatus.excused:
        return AttendanceStatus.excused;
    }
  }
}
