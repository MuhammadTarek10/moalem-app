import 'package:moalem/features/students/domain/entities/student_entity.dart';

/// Entity representing a student's scores for the report
class StudentReportEntity {
  final StudentEntity student;
  final Map<String, int> scores; // evaluationId -> score
  final int totalScore;
  final int maxPossibleScore;
  final bool isSelected;

  const StudentReportEntity({
    required this.student,
    required this.scores,
    required this.totalScore,
    required this.maxPossibleScore,
    this.isSelected = false,
  });

  double get percentage {
    if (maxPossibleScore == 0) return 0;
    return (totalScore / maxPossibleScore) * 100;
  }

  int getScore(String evaluationId) {
    return scores[evaluationId] ?? 0;
  }

  StudentReportEntity copyWith({
    StudentEntity? student,
    Map<String, int>? scores,
    int? totalScore,
    int? maxPossibleScore,
    bool? isSelected,
  }) {
    return StudentReportEntity(
      student: student ?? this.student,
      scores: scores ?? this.scores,
      totalScore: totalScore ?? this.totalScore,
      maxPossibleScore: maxPossibleScore ?? this.maxPossibleScore,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
