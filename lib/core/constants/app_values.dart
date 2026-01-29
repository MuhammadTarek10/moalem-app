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
    // Total: 30
    'primary_homework': 5,
    'primary_activity': 5,
    'primary_weekly': 5,
    'primary_performance': 10,
    'primary_attendance': 5,
  };

  static const Map<String, int> secondaryEvaluationScores = {
    // Total: 40
    'weekly_review': 20,
    'homework_book': 10,
    'attendance_and_diligence': 10,
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
