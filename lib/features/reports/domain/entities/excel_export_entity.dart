/// Entity representing Excel export request data
class ExcelExportEntity {
  final String id;
  final ExportType exportType;
  final EducationalStage stage;
  final SchoolInfo schoolInfo;
  final ClassInfo classInfo;
  final List<StudentExportData> students;
  final ExportOptions options;
  final DateTime createdAt;

  const ExcelExportEntity({
    required this.id,
    required this.exportType,
    required this.stage,
    required this.schoolInfo,
    required this.classInfo,
    required this.students,
    required this.options,
    required this.createdAt,
    this.weekStartDates,
  });

  final Map<int, DateTime>? weekStartDates;

  ExcelExportEntity copyWith({
    String? id,
    ExportType? exportType,
    EducationalStage? stage,
    SchoolInfo? schoolInfo,
    ClassInfo? classInfo,
    List<StudentExportData>? students,
    ExportOptions? options,
    DateTime? createdAt,
    Map<int, DateTime>? weekStartDates,
  }) {
    return ExcelExportEntity(
      id: id ?? this.id,
      exportType: exportType ?? this.exportType,
      stage: stage ?? this.stage,
      schoolInfo: schoolInfo ?? this.schoolInfo,
      classInfo: classInfo ?? this.classInfo,
      students: students ?? this.students,
      options: options ?? this.options,
      createdAt: createdAt ?? this.createdAt,
      weekStartDates: weekStartDates ?? this.weekStartDates,
    );
  }
}

/// Export types for Excel export
enum ExportType { scores, attendance, yearlyWork }

/// Educational stages for template selection
enum EducationalStage {
  prePrimary, // أولى وتانية ابتدائي (Primary 1-2)
  primary, // 3-6 ابتدائي (Primary 3-6)
  preparatory, // إعدادي (Prep 1-2)
  secondary, // ثانوي نظام شهور (Secondary)
}

/// School information for headers
class SchoolInfo {
  final String governorate; // مديرية التربية والتعليم
  final String administration; // الإدارة
  final String schoolName; // المدرسة

  const SchoolInfo({
    required this.governorate,
    required this.administration,
    required this.schoolName,
  });

  SchoolInfo copyWith({
    String? governorate,
    String? administration,
    String? schoolName,
  }) {
    return SchoolInfo(
      governorate: governorate ?? this.governorate,
      administration: administration ?? this.administration,
      schoolName: schoolName ?? this.schoolName,
    );
  }
}

/// Class information
class ClassInfo {
  final String className; // اسم الفصل
  final String grade; // الصف
  final String subject; // المادة
  final String? section; // الفصل الدراسي (للثانوي)

  const ClassInfo({
    required this.className,
    required this.grade,
    required this.subject,
    this.section,
  });

  ClassInfo copyWith({
    String? className,
    String? grade,
    String? subject,
    String? section,
  }) {
    return ClassInfo(
      className: className ?? this.className,
      grade: grade ?? this.grade,
      subject: subject ?? this.subject,
      section: section ?? this.section,
    );
  }
}

/// Student data for export
class StudentExportData {
  final String studentId;
  final String name;
  final int number;
  final Map<int, Map<String, int>> weeklyScores; // week -> evalId -> score
  final Map<int, int> weeklyTotals;
  final Map<String, int>? monthlyExamScores;
  final Map<int, Map<DateTime, AttendanceStatus>>? weeklyAttendance;

  const StudentExportData({
    required this.studentId,
    required this.name,
    required this.number,
    required this.weeklyScores,
    required this.weeklyTotals,
    this.monthlyExamScores,
    this.weeklyAttendance,
  });

  int getScoreForWeek(int week, String evaluationId) {
    return weeklyScores[week]?[evaluationId] ?? 0;
  }

  int getTotalForWeek(int week) {
    return weeklyTotals[week] ?? 0;
  }

  StudentExportData copyWith({
    String? studentId,
    String? name,
    int? number,
    Map<int, Map<String, int>>? weeklyScores,
    Map<int, int>? weeklyTotals,
    Map<String, int>? monthlyExamScores,
    Map<int, Map<DateTime, AttendanceStatus>>? weeklyAttendance,
  }) {
    return StudentExportData(
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      number: number ?? this.number,
      weeklyScores: weeklyScores ?? this.weeklyScores,
      weeklyTotals: weeklyTotals ?? this.weeklyTotals,
      monthlyExamScores: monthlyExamScores ?? this.monthlyExamScores,
      weeklyAttendance: weeklyAttendance ?? this.weeklyAttendance,
    );
  }
}

/// Attendance status for export
enum AttendanceStatus { present, absent, excused }

/// Export configuration options
class ExportOptions {
  final bool includeSemesterAverage;
  final bool includeMonthlyExams;
  final DateTime? exportDate;

  const ExportOptions({
    this.includeSemesterAverage = true,
    this.includeMonthlyExams = true,
    this.exportDate,
  });

  ExportOptions copyWith({
    bool? includeSemesterAverage,
    bool? includeMonthlyExams,
    DateTime? exportDate,
  }) {
    return ExportOptions(
      includeSemesterAverage:
          includeSemesterAverage ?? this.includeSemesterAverage,
      includeMonthlyExams: includeMonthlyExams ?? this.includeMonthlyExams,
      exportDate: exportDate ?? this.exportDate,
    );
  }
}
