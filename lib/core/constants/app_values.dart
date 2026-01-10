class EvaluationValues {
  static const String prePrimaryEvaluationGroupName = 'pre_primary';
  static const String primaryEvaluationGroupName = 'primary';
  static const String secondaryEvaluationGroupName = 'secondary';
  static const String highSchoolEvaluationGroupName = 'high_school';

  static const List<String> evaluationGroups = [
    prePrimaryEvaluationGroupName,
    primaryEvaluationGroupName,
    secondaryEvaluationGroupName,
    highSchoolEvaluationGroupName,
  ];

  static const Map<String, int> prePrimaryEvaluationScores = {
    // Total: 100
    'classroom_performance': 20,
    'homework_book': 20,
    'activity_book': 20,
    'weekly_review': 20,
    'oral_tasks': 10,
    'skill_tasks': 5,
    'attendance_and_diligence': 5,
  };

  static const Map<String, int> primaryEvaluationScores = {
    // Total: 40
    'homework_book': 5,
    'activity_book': 5,
    'weekly_review': 5,
    'attendance_and_diligence': 5,
    'skills_performance': 10,
    'months_exam_average': 10,
  };

  static const Map<String, int> secondaryEvaluationScores = {
    // Total: 70
    'weekly_review': 20,
    'homework_book': 10,
    'attendance_and_diligence': 10,
    'first_month_exam': 15,
    'second_month_exam': 15,
  };

  static const Map<String, int> highSchoolEvaluationScores = {
    // Total: 70 (same as secondary for now)
    'weekly_review': 20,
    'homework_book': 10,
    'attendance_and_diligence': 10,
    'first_month_exam': 15,
    'second_month_exam': 15,
  };
}
