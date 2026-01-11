import 'package:injectable/injectable.dart';
import 'package:moalem/core/constants/app_enums.dart' as app_enums;
import 'package:moalem/features/attendance/domain/entities/weekly_attendance_entity.dart';
import 'package:moalem/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:moalem/features/auth/domain/repositories/user_repository.dart';
import 'package:moalem/features/classes/domain/repositories/class_repository.dart';
import 'package:moalem/features/print/domain/entities/print_data_entity.dart';
import 'package:moalem/features/students/domain/repositories/student_repository.dart';

/// Use case to generate multi-week attendance report (5 weeks at a time)
@injectable
class GenerateMultiWeekAttendanceReportUseCase {
  final AttendanceRepository _attendanceRepository;
  final ClassRepository _classRepository;
  final StudentRepository _studentRepository;
  final UserRepository _userRepository;

  GenerateMultiWeekAttendanceReportUseCase(
    this._attendanceRepository,
    this._classRepository,
    this._studentRepository,
    this._userRepository,
  );

  /// Generate a multi-week attendance report
  /// [classId] - The class to generate report for
  /// [weekGroup] - 1 for weeks 1-5, 2 for weeks 6-10, 3 for weeks 11-15
  /// [semesterStartDate] - The start date of the semester (first Saturday)
  Future<PrintDataEntity?> call({
    required String classId,
    required int weekGroup,
    DateTime? semesterStartDate,
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

    // Calculate week numbers for this group
    final startWeek = (weekGroup - 1) * 5 + 1;
    final weekNumbers = List.generate(5, (i) => startWeek + i);

    // Calculate week start dates
    final effectiveSemesterStart =
        semesterStartDate ?? _getDefaultSemesterStart();
    final weekStartDates = <int, DateTime>{};
    for (final weekNum in weekNumbers) {
      weekStartDates[weekNum] = effectiveSemesterStart.add(
        Duration(days: (weekNum - 1) * 7),
      );
    }

    // Get attendance for all 5 weeks for each student
    final List<StudentPrintData> studentsData = [];

    for (final student in students) {
      final weeklyAttendance = <int, Map<DateTime, AttendanceStatus>>{};

      for (final weekNum in weekNumbers) {
        final weekStartDate = weekStartDates[weekNum]!;
        final weekEndDate = WeekHelper.getWeekEnd(weekStartDate);

        // Get attendance records for this week
        final attendanceRecords =
            await _attendanceRepository.getAttendanceByDateRange(
          classId: classId,
          startDate: weekStartDate,
          endDate: weekEndDate,
        );

        // Filter records for this student
        final studentRecords = attendanceRecords
            .where((record) => record.studentId == student.id)
            .toList();

        final dailyAttendance = <DateTime, AttendanceStatus>{};
        for (final record in studentRecords) {
          final normalizedDate = DateTime(
            record.date.year,
            record.date.month,
            record.date.day,
          );
          dailyAttendance[normalizedDate] = _convertStatus(record.status);
        }

        weeklyAttendance[weekNum] = dailyAttendance;
      }

      studentsData.add(
        StudentPrintData(
          student: student,
          scores: {},
          totalScore: 0,
          maxPossibleScore: 0,
          weeklyAttendance: weeklyAttendance,
        ),
      );
    }

    return PrintDataEntity(
      printType: PrintType.attendance,
      classEntity: classEntity,
      governorate: governorate,
      administration: administration,
      periodType: app_enums.PeriodType.weekly,
      periodNumber: startWeek, // First week of the group
      studentsData: studentsData,
      isMultiWeek: true,
      weekGroup: weekGroup,
      weekStartDates: weekStartDates,
    );
  }

  /// Get the default semester start date (first Saturday of the current school year)
  DateTime _getDefaultSemesterStart() {
    final now = DateTime.now();
    // School year typically starts in September
    // If we're before September, use previous year's September
    final year = now.month >= 9 ? now.year : now.year - 1;
    final sept1 = DateTime(year, 9, 1);

    // Find the first Saturday on or after September 1
    int daysUntilSaturday = (DateTime.saturday - sept1.weekday) % 7;
    return sept1.add(Duration(days: daysUntilSaturday));
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
