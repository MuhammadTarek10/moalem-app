/// SQL schema for database initialization
class DatabaseSchema {
  DatabaseSchema._();

  static const List<String> createTableQueries = [
    _createClassesTable,
    _createStudentsTable,
    _createSubjectsTable,
    _createEvaluationsTable,
    _createStudentsScoresTable,
  ];

  static const String _createClassesTable = '''
    CREATE TABLE IF NOT EXISTS classes (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      grade TEXT NOT NULL,
      subject TEXT NOT NULL,
      semester TEXT NOT NULL,
      school TEXT NOT NULL,
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
      created_at TEXT NOT NULL,
      updated_at TEXT,
      deleted_at TEXT
    )
  ''';

  static const String _createStudentsScoresTable = '''
    CREATE TABLE IF NOT EXISTS students_scores (
      student_id TEXT NOT NULL,
      subject_id TEXT NOT NULL,
      evaluation_id TEXT NOT NULL,
      score INTEGER NOT NULL,
      score_date TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      deleted_at TEXT,
      PRIMARY KEY (student_id, subject_id, evaluation_id),
      FOREIGN KEY (student_id) REFERENCES students (id),
      FOREIGN KEY (subject_id) REFERENCES subjects (id),
      FOREIGN KEY (evaluation_id) REFERENCES evaluations (id)
    )
  ''';
}
