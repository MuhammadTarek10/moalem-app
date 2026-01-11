import 'package:injectable/injectable.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_schema.dart';

@singleton
class DatabaseService {
  static const String _dbName = 'moalem.db';
  static const int _dbVersion = 4;

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
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    for (final query in DatabaseSchema.createTableQueries) {
      await db.execute(query);
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrate from v1 to v2: restructure students_scores table
      for (final query in DatabaseSchema.migrateV1ToV2) {
        await db.execute(query);
      }
    }

    if (oldVersion < 3) {
      // Migrate from v2 to v3: fix evaluation_group column type
      // Drop and recreate classes table to fix the enum type issue
      for (final query in DatabaseSchema.migrateV2ToV3) {
        await db.execute(query);
      }
    }

    if (oldVersion < 4) {
      // Migrate from v3 to v4: add daily_attendance table
      for (final query in DatabaseSchema.migrateV3ToV4) {
        await db.execute(query);
      }
    }
  }
}
