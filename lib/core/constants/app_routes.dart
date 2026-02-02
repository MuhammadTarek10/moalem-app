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

  /// Builds the path for bulk score entry with the given class [id]
  static String bulkScoreEntryPath(String id) => '/classes/$id/bulk-scores';

  // Students Screen
  static const String studentDetails = '/students';

  /// Builds the path for student details with the given [id]
  static String studentDetailsPath(String id) => '/students/$id';

  // Reports Screen
  static const String reports = '/reports';

  // Print Screen
  static const String print = '/print';
  static const String printOptions = '/print/options';
  static const String qrPrint = '/qr-print';
  static const String attendanceEntry = '/attendance/entry';

  /// Builds the path for print options with the given parameters
  static String printOptionsPath({
    required String classId,
    required String printType,
  }) => '/print/options?classId=$classId&printType=$printType';

  /// Builds the path for attendance entry with optional class ID
  static String attendanceEntryPath({String? classId}) =>
      classId != null && classId.isNotEmpty
      ? '/attendance/entry?classId=$classId'
      : '/attendance/entry';
}
