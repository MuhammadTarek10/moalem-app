import 'package:injectable/injectable.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

@singleton
class DatabaseService {
  static const String _dbName = 'moalem.db';
  static const int _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Implement table creation here
    // Example:
    // await db.execute('''
    //   CREATE TABLE users (
    //     id INTEGER PRIMARY KEY AUTOINCREMENT,
    //     name TEXT,
    //     email TEXT
    //   )
    // ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Implement migration logic here
  }
}
