import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/features/attendance/domain/entities/daily_attendance_entity.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';

/// Entity representing a student's weekly attendance (Sat-Thu)
class WeeklyAttendanceEntity {
  final String studentId;
  final String classId;
  final DateTime weekStartDate; // Saturday of the week
  final Map<DateTime, AttendanceStatus> dailyAttendance; // date -> status

  const WeeklyAttendanceEntity({
    required this.studentId,
    required this.classId,
    required this.weekStartDate,
    required this.dailyAttendance,
  });

  /// Get attendance status for a specific date
  AttendanceStatus? getStatusForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return dailyAttendance[normalizedDate];
  }

  /// Get all days in this week (Sat to Thu)
  List<DateTime> get weekDays {
    return List.generate(6, (index) {
      return weekStartDate.add(Duration(days: index));
    });
  }

  /// Get the week end date (Thursday)
  DateTime get weekEndDate => weekStartDate.add(const Duration(days: 5));

  /// Check if a specific date has attendance recorded
  bool hasAttendanceFor(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return dailyAttendance.containsKey(normalizedDate);
  }

  /// Get total present days
  int get presentDays => dailyAttendance.values
      .where((status) => status == AttendanceStatus.present)
      .length;

  /// Get total absent days
  int get absentDays => dailyAttendance.values
      .where((status) => status == AttendanceStatus.absent)
      .length;

  /// Get total excused days
  int get excusedDays => dailyAttendance.values
      .where((status) => status == AttendanceStatus.excused)
      .length;

  WeeklyAttendanceEntity copyWith({
    String? studentId,
    String? classId,
    DateTime? weekStartDate,
    Map<DateTime, AttendanceStatus>? dailyAttendance,
  }) {
    return WeeklyAttendanceEntity(
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      dailyAttendance: dailyAttendance ?? this.dailyAttendance,
    );
  }

  /// Create from list of daily attendance records
  factory WeeklyAttendanceEntity.fromDailyRecords({
    required String studentId,
    required String classId,
    required DateTime weekStartDate,
    required List<DailyAttendanceEntity> records,
  }) {
    final Map<DateTime, AttendanceStatus> dailyMap = {};
    for (final record in records) {
      final normalizedDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      dailyMap[normalizedDate] = record.status;
    }
    return WeeklyAttendanceEntity(
      studentId: studentId,
      classId: classId,
      weekStartDate: weekStartDate,
      dailyAttendance: dailyMap,
    );
  }
}

/// Entity for printing/exporting weekly attendance for all students
class WeeklyAttendancePrintData {
  final StudentEntity student;
  final Map<DateTime, AttendanceStatus> dailyAttendance;

  const WeeklyAttendancePrintData({
    required this.student,
    required this.dailyAttendance,
  });

  /// Get attendance status for a specific date
  AttendanceStatus? getStatusForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return dailyAttendance[normalizedDate];
  }
}

/// Helper class for week calculation
class WeekHelper {
  WeekHelper._();

  /// Get the Saturday of the week containing the given date
  static DateTime getWeekStart(DateTime date) {
    // Find the most recent Saturday
    final dayOfWeek = date.weekday; // 1 = Monday, 7 = Sunday
    // Saturday is weekday 6
    int daysToSubtract;
    if (dayOfWeek == 6) {
      // Already Saturday
      daysToSubtract = 0;
    } else if (dayOfWeek == 7) {
      // Sunday
      daysToSubtract = 1;
    } else {
      // Monday to Friday (1-5)
      daysToSubtract = dayOfWeek + 1;
    }
    final saturday = date.subtract(Duration(days: daysToSubtract));
    return DateTime(saturday.year, saturday.month, saturday.day);
  }

  /// Get Thursday of the week starting from Saturday
  static DateTime getWeekEnd(DateTime weekStart) {
    return weekStart.add(const Duration(days: 5));
  }

  /// Get all week days (Sat-Thu) from a week start date
  static List<DateTime> getWeekDays(DateTime weekStart) {
    return List.generate(6, (index) {
      return weekStart.add(Duration(days: index));
    });
  }

  /// Get the day name in Arabic for a given weekday
  static String getDayNameArabic(int weekday) {
    switch (weekday) {
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      case DateTime.monday:
        return 'الاثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      default:
        return '';
    }
  }

  /// Get short day name in Arabic
  static String getShortDayNameArabic(int weekday) {
    switch (weekday) {
      case DateTime.saturday:
        return 'سبت';
      case DateTime.sunday:
        return 'أحد';
      case DateTime.monday:
        return 'اثنين';
      case DateTime.tuesday:
        return 'ثلاثاء';
      case DateTime.wednesday:
        return 'أربعاء';
      case DateTime.thursday:
        return 'خميس';
      case DateTime.friday:
        return 'جمعة';
      default:
        return '';
    }
  }
}
