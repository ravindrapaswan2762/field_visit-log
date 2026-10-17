import 'package:sqflite/sqflite.dart';

/// Contains DDL statements for each schema version.
/// Increment [AppConstants.dbVersion] and add a corresponding migration block
/// inside [onUpgrade] before ever changing column names or types.
class DatabaseMigrations {
  DatabaseMigrations._();

  static Future<void> onCreate(Database db, int version) async {
    await _createV1(db);
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Apply each migration in sequence.
    if (oldVersion < 2) {
      // Example: await _migrateV1ToV2(db);
    }
  }

  static Future<void> _createV1(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visits (
        id                TEXT    PRIMARY KEY NOT NULL,
        customer_name     TEXT    NOT NULL,
        notes             TEXT    NOT NULL,
        created_at        TEXT    NOT NULL,
        photo_path        TEXT,
        sync_status       TEXT    NOT NULL DEFAULT 'pending',
        retry_count       INTEGER NOT NULL DEFAULT 0,
        next_retry_at     TEXT,
        last_sync_error   TEXT,
        synced_at         TEXT
      )
    ''');

    // Speed up the most-common queries.
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visits_created_at ON visits(created_at DESC)',
    );
    await db.execute(
      "CREATE INDEX IF NOT EXISTS idx_visits_sync_status ON visits(sync_status) WHERE sync_status != 'synced'",
    );
  }
}
