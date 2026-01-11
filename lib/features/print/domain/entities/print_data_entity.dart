import 'package:moalem/core/constants/app_enums.dart';
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

  const PrintDataEntity({
    required this.printType,
    required this.classEntity,
    required this.governorate,
    required this.administration,
    required this.periodType,
    required this.periodNumber,
    required this.studentsData,
    this.evaluations,
  });

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
  final Map<String, int> scores; // evaluationId -> score (for scores type)
  final Map<String, AttendanceStatus>?
  attendance; // date -> status (for attendance type)
  final int totalScore;
  final int maxPossibleScore;

  const StudentPrintData({
    required this.student,
    required this.scores,
    this.attendance,
    required this.totalScore,
    required this.maxPossibleScore,
  });

  /// Calculate percentage
  double get percentage {
    if (maxPossibleScore == 0) return 0;
    return (totalScore / maxPossibleScore) * 100;
  }
}

/// Attendance status enum
enum AttendanceStatus { present, absent, excused }
