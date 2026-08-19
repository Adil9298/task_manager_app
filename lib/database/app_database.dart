import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._privateConstructor();

  static final AppDatabase instance =
  AppDatabase._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  // ---------------------------------------------------------------------------
  // INITIALIZE DATABASE
  // ---------------------------------------------------------------------------

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'task_manager.db',
    );

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // ---------------------------------------------------------------------------
  // CREATE TABLES
  // ---------------------------------------------------------------------------

  Future<void> _onCreate(
      Database db,
      int version,
      ) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,

        title TEXT NOT NULL,
        description TEXT NOT NULL,

        priority TEXT NOT NULL,
        dueDate TEXT,

        isCompleted INTEGER NOT NULL DEFAULT 0,
        isDeleted INTEGER NOT NULL DEFAULT 0,

        createdAt TEXT NOT NULL,
        updatedAt TEXT,

        isSynced INTEGER NOT NULL DEFAULT 1,
        syncAction TEXT NOT NULL DEFAULT 'none'
      )
    ''');
  }
}