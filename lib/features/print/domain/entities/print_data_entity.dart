import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/features/attendance/domain/entities/weekly_attendance_entity.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/entities/evaluation_entity.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';

/// Type of print report
enum PrintType { scores, attendance, qrCode }

/// Entity containing all data needed for print export
class PrintDataEntity {
  final PrintType printType;
  final ClassEntity classEntity;
  final String governorate;
  final String administration;
  final PeriodType periodType;
  final int periodNumber;
  final List<StudentPrintData> studentsData;
  final List<EvaluationEntity>? evaluations; // For scores only
  final DateTime? weekStartDate; // For weekly attendance

  // Multi-week scores support
  final bool isMultiWeek; // True for multi-week scores export
  final int weekGroup; // 1 for weeks 1-5, 2 for weeks 6-10, 3 for weeks 11-15
  final Map<int, DateTime>? weekStartDates; // week number -> start date for headers

  const PrintDataEntity({
    required this.printType,
    required this.classEntity,
    required this.governorate,
    required this.administration,
    required this.periodType,
    required this.periodNumber,
    required this.studentsData,
    this.evaluations,
    this.weekStartDate,
    this.isMultiWeek = false,
    this.weekGroup = 1,
    this.weekStartDates,
  });

  /// Get week numbers for the current week group (e.g., [1,2,3,4,5] for group 1)
  List<int> get weekNumbers {
    final startWeek = (weekGroup - 1) * 5 + 1;
    return List.generate(5, (i) => startWeek + i);
  }

  /// Get week days for attendance (Sat-Thu)
  List<DateTime> get weekDays {
    if (weekStartDate == null) return [];
    return WeekHelper.getWeekDays(weekStartDate!);
  }

  /// Get week end date (Thursday)
  DateTime? get weekEndDate {
    if (weekStartDate == null) return null;
    return WeekHelper.getWeekEnd(weekStartDate!);
  }

  /// Get the appropriate template file name based on print type and class evaluation group
  String getTemplateFileName() {
    if (printType == PrintType.attendance) {
      return 'assets/files/attendance-evaluations.xlsx';
    }

    // For scores, use the evaluation group
    switch (classEntity.evaluationGroup) {
      case EvaluationGroup.prePrimary:
        return 'assets/files/pre-primary-evaluations.xlsx';
      case EvaluationGroup.primary:
        return 'assets/files/primary-evaluations.xlsx';
      case EvaluationGroup.secondary:
        return 'assets/files/secondary-evaluations.xlsx';
      case EvaluationGroup.high:
        return 'assets/files/secondary-evaluations.xlsx'; // Use secondary for high school
    }
  }
}

/// Student data for print
class StudentPrintData {
  final StudentEntity student;
  final Map<String, int> scores; // evaluationId -> score (for single week scores)
  final Map<String, AttendanceStatus>?
      attendance; // legacy: period key -> status
  final Map<DateTime, AttendanceStatus>?
      attendanceDaily; // date -> status (for weekly attendance)
  final int totalScore;
  final int maxPossibleScore;

  // Multi-week scores support
  final Map<int, Map<String, int>>?
      weeklyScores; // week number -> (evaluationId -> score)
  final Map<int, int>? weeklyTotals; // week number -> total score

  // Multi-week attendance support
  final Map<int, Map<DateTime, AttendanceStatus>>?
      weeklyAttendance; // week number -> (date -> status)

  const StudentPrintData({
    required this.student,
    required this.scores,
    this.attendance,
    this.attendanceDaily,
    required this.totalScore,
    required this.maxPossibleScore,
    this.weeklyScores,
    this.weeklyTotals,
    this.weeklyAttendance,
  });

  /// Calculate percentage
  double get percentage {
    if (maxPossibleScore == 0) return 0;
    return (totalScore / maxPossibleScore) * 100;
  }

  /// Get attendance status for a specific date
  AttendanceStatus? getAttendanceForDate(DateTime date) {
    if (attendanceDaily == null) return null;
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return attendanceDaily![normalizedDate];
  }

  /// Get attendance status for a specific date in a specific week (multi-week)
  AttendanceStatus? getAttendanceForWeekDate(int weekNumber, DateTime date) {
    if (weeklyAttendance == null) return null;
    final weekAttendance = weeklyAttendance![weekNumber];
    if (weekAttendance == null) return null;
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return weekAttendance[normalizedDate];
  }

  /// Get score for a specific evaluation in a specific week
  int getScoreForWeek(int weekNumber, String evaluationId) {
    if (weeklyScores == null) return 0;
    final weekScores = weeklyScores![weekNumber];
    if (weekScores == null) return 0;
    return weekScores[evaluationId] ?? 0;
  }

  /// Get total score for a specific week
  int getTotalForWeek(int weekNumber) {
    if (weeklyTotals == null) return 0;
    return weeklyTotals![weekNumber] ?? 0;
  }
}

/// Attendance status enum (for print - maps to app_enums.AttendanceStatus)
enum AttendanceStatus { present, absent, excused }
