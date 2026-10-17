import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';
import 'database_migrations.dart';

/// Singleton wrapper for the SQLite database.
/// Initialises the database once and reuses the connection.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: DatabaseMigrations.onCreate,
      onUpgrade: DatabaseMigrations.onUpgrade,
      // Enable WAL mode for better concurrent read performance.
      onOpen: (db) async => await db.execute('PRAGMA journal_mode=WAL;'),
    );
  }

  /// Exposed for testing to allow injection of an in-memory database.
  void setDatabaseForTest(Database db) {
    _database = db;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
