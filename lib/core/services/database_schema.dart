/// SQL schema for database initialization
class DatabaseSchema {
  DatabaseSchema._();

  static const List<String> createTableQueries = [
    _createClassesTable,
    _createStudentsTable,
    _createSubjectsTable,
    _createEvaluationsTable,
    _insertEvaluationAspects,
    _createStudentsScoresTable,
    _createDailyAttendanceTable,
  ];

  static const String _createClassesTable = '''
    CREATE TABLE IF NOT EXISTS classes (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      grade TEXT NOT NULL,
      subject TEXT NOT NULL,
      semester TEXT NOT NULL,
      school TEXT NOT NULL,
      evaluation_group TEXT NOT NULL DEFAULT 'prePrimary' CHECK(evaluation_group IN ('prePrimary', 'primary', 'secondary', 'high')),
      created_at TEXT NOT NULL,
      updated_at TEXT,
      deleted_at TEXT
    )
  ''';

  static const String _createStudentsTable = '''
    CREATE TABLE IF NOT EXISTS students (
      id TEXT PRIMARY KEY,
      class_id TEXT,
      name TEXT NOT NULL,
      number TEXT NOT NULL,
      qr_code TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      deleted_at TEXT,
      FOREIGN KEY (class_id) REFERENCES classes (id)
    )
  ''';

  static const String _createSubjectsTable = '''
    CREATE TABLE IF NOT EXISTS subjects (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      deleted_at TEXT
    )
  ''';

  static const String _createEvaluationsTable = '''
    CREATE TABLE IF NOT EXISTS evaluations (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      is_binary INTEGER DEFAULT 0,
      max_score INTEGER NOT NULL DEFAULT 20,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      deleted_at TEXT
    )
  ''';

  static const String _insertEvaluationAspects = '''
    INSERT OR IGNORE INTO evaluations (id, name, is_binary, max_score, created_at) VALUES
      ('classroom_performance', 'classroom_performance', 0, 20, datetime('now')),
      ('homework_book', 'homework_book', 0, 20, datetime('now')),
      ('activity_book', 'activity_book', 0, 20, datetime('now')),
      ('weekly_review', 'weekly_review', 0, 20, datetime('now')),
      ('oral_tasks', 'oral_tasks', 0, 10, datetime('now')),
      ('skill_tasks', 'skill_tasks', 0, 5, datetime('now')),
      ('skills_performance', 'skills_performance', 0, 10, datetime('now')),
      ('months_exam_average', 'months_exam_average', 0, 10, datetime('now')),
      ('attendance_and_diligence', 'attendance_and_diligence', 1, 10, datetime('now')),
      ('first_month_exam', 'first_month_exam', 0, 15, datetime('now')),
      ('second_month_exam', 'second_month_exam', 0, 15, datetime('now'))
  ''';

  static const String _createStudentsScoresTable = '''
    CREATE TABLE IF NOT EXISTS students_scores (
      id TEXT PRIMARY KEY,
      student_id TEXT NOT NULL,
      evaluation_id TEXT NOT NULL,
      score INTEGER NOT NULL,
      period_type TEXT NOT NULL,
      period_number INTEGER NOT NULL,
      attendance_status TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      FOREIGN KEY (student_id) REFERENCES students (id),
      FOREIGN KEY (evaluation_id) REFERENCES evaluations (id)
    )
  ''';

  static const String _createDailyAttendanceTable = '''
    CREATE TABLE IF NOT EXISTS daily_attendance (
      id TEXT PRIMARY KEY,
      student_id TEXT NOT NULL,
      class_id TEXT NOT NULL,
      date TEXT NOT NULL,
      attendance_status TEXT NOT NULL CHECK(attendance_status IN ('present', 'absent', 'excused')),
      created_at TEXT NOT NULL,
      updated_at TEXT,
      FOREIGN KEY (student_id) REFERENCES students (id),
      FOREIGN KEY (class_id) REFERENCES classes (id),
      UNIQUE(student_id, date)
    )
  ''';

  /// Migration queries for version upgrades
  static const List<String> migrateV1ToV2 = [
    // Drop old table and create new one (data migration handled separately)
    'DROP TABLE IF EXISTS students_scores',
    _createStudentsScoresTable,
  ];

  /// Migration from v2 to v3: Fix evaluation_group enum type issue
  static const List<String> migrateV2ToV3 = [
    // Backup classes data
    '''CREATE TABLE IF NOT EXISTS classes_backup AS SELECT * FROM classes''',
    // Drop old table
    'DROP TABLE IF EXISTS classes',
    // Recreate with correct schema
    _createClassesTable,
    // Restore data (if any exists)
    '''INSERT OR IGNORE INTO classes (id, name, grade, subject, semester, school, evaluation_group, created_at, updated_at, deleted_at)
       SELECT id, name, grade, subject, semester, school, 
       CASE 
         WHEN evaluation_group = 'pre_primary' THEN 'prePrimary'
         ELSE evaluation_group
       END as evaluation_group,
       created_at, updated_at, deleted_at 
       FROM classes_backup''',
    // Drop backup table
    'DROP TABLE IF EXISTS classes_backup',
  ];

  /// Migration from v3 to v4: Add daily_attendance table
  static const List<String> migrateV3ToV4 = [_createDailyAttendanceTable];
}
