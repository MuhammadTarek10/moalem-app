import 'package:moalem/features/students/domain/entities/student_entity.dart';

/// Entity representing a student's score input state for bulk entry
class StudentScoreInput {
  final StudentEntity student;
  final int currentScore;
  final bool isSelected;

  StudentScoreInput({
    required this.student,
    required this.currentScore,
    this.isSelected = false,
  });

  StudentScoreInput copyWith({
    StudentEntity? student,
    int? currentScore,
    bool? isSelected,
  }) {
    return StudentScoreInput(
      student: student ?? this.student,
      currentScore: currentScore ?? this.currentScore,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
