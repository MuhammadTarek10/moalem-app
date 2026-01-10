import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/features/classes/domain/entities/class_entity.dart';
import 'package:moalem/features/classes/domain/entities/evaluation_entity.dart';
import 'package:moalem/features/students/domain/entities/student_entity.dart';
import 'package:moalem/features/students/domain/entities/student_score_entity.dart';

/// Composite entity for student details screen with all related data
class StudentDetailsWithScores {
  final StudentEntity student;
  final ClassEntity classInfo;
  final List<EvaluationEntity> evaluations;
  final Map<String, StudentScoreEntity> scores; // key: evaluationId
  final PeriodType currentPeriodType;
  final int currentPeriodNumber;

  const StudentDetailsWithScores({
    required this.student,
    required this.classInfo,
    required this.evaluations,
    required this.scores,
    required this.currentPeriodType,
    required this.currentPeriodNumber,
  });

  /// Calculates the total score from all evaluations
  int get totalScore {
    int total = 0;
    for (final evaluation in evaluations) {
      final score = scores[evaluation.id];
      if (score != null) {
        total += score.score;
      }
    }
    return total;
  }

  /// Calculates the maximum possible score from all evaluations
  int get maxPossibleScore {
    int total = 0;
    for (final evaluation in evaluations) {
      total += evaluation.maxScore;
    }
    return total;
  }

  /// Calculates the percentage of total score
  double get percentage {
    if (maxPossibleScore == 0) return 0;
    return (totalScore / maxPossibleScore) * 100;
  }

  /// Gets the score for a specific evaluation
  int getScoreForEvaluation(String evaluationId) {
    return scores[evaluationId]?.score ?? 0;
  }

  /// Gets the attendance status (from attendance evaluation if exists)
  AttendanceStatus? get attendanceStatus {
    for (final score in scores.values) {
      if (score.attendanceStatus != null) {
        return score.attendanceStatus;
      }
    }
    return null;
  }

  /// Gets any notes from scores
  String? get notes {
    for (final score in scores.values) {
      if (score.notes != null && score.notes!.isNotEmpty) {
        return score.notes;
      }
    }
    return null;
  }

  StudentDetailsWithScores copyWith({
    StudentEntity? student,
    ClassEntity? classInfo,
    List<EvaluationEntity>? evaluations,
    Map<String, StudentScoreEntity>? scores,
    PeriodType? currentPeriodType,
    int? currentPeriodNumber,
  }) {
    return StudentDetailsWithScores(
      student: student ?? this.student,
      classInfo: classInfo ?? this.classInfo,
      evaluations: evaluations ?? this.evaluations,
      scores: scores ?? this.scores,
      currentPeriodType: currentPeriodType ?? this.currentPeriodType,
      currentPeriodNumber: currentPeriodNumber ?? this.currentPeriodNumber,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentDetailsWithScores &&
        other.student == student &&
        other.currentPeriodType == currentPeriodType &&
        other.currentPeriodNumber == currentPeriodNumber;
  }

  @override
  int get hashCode =>
      student.hashCode ^
      currentPeriodType.hashCode ^
      currentPeriodNumber.hashCode;
}
