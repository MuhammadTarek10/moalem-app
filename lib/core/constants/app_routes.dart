class AppRoutes {
  static const String splash = '/splash';
  static const String auth = '/auth';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String activation = '/activation';
  static const String home = '/';

  // Profile Screen
  static const String profile = '/profile';
  static const String advancedSettings = '/advanced-settings';
  static const String rateUs = '/rate-us';
  static const String contactUs = '/contact-us';

  // Classes Screen
  static const String classes = '/classes';

  /// Builds the path for class details with the given [id]
  static String classDetailsPath(String id) => '/classes/$id';

  // Students Screen
  static const String studentDetails = '/students';

  /// Builds the path for student details with the given [id]
  static String studentDetailsPath(String id) => '/students/$id';
}
