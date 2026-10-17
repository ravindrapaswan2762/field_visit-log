import 'package:sqflite/sqflite.dart' hide DatabaseException;
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../sync/sync_status.dart';
import '../models/visit_model.dart';

/// All direct SQLite access lives here.
/// Uses parameterised queries throughout to prevent SQL injection.
class VisitLocalDatasource {
  VisitLocalDatasource({AppDatabase? db}) : _appDb = db ?? AppDatabase.instance;

  final AppDatabase _appDb;
  static const _table = 'visits';

  Future<Database> get _db => _appDb.database;

  Future<List<VisitModel>> getAllVisits() async {
    try {
      final db = await _db;
      final rows = await db.query(_table, orderBy: 'created_at DESC');
      return rows.map(VisitModel.fromMap).toList();
    } catch (e) {
      throw AppDatabaseException('Failed to load visits: $e');
    }
  }

  Future<List<VisitModel>> getVisitsByStatus(SyncStatus status) async {
    try {
      final db = await _db;
      final rows = await db.query(
        _table,
        where: 'sync_status = ?',
        whereArgs: [status.name],
        orderBy: 'created_at DESC',
      );
      return rows.map(VisitModel.fromMap).toList();
    } catch (e) {
      throw AppDatabaseException('Failed to load visits by status: $e');
    }
  }

  Future<VisitModel?> getVisitById(String id) async {
    try {
      final db = await _db;
      final rows = await db.query(
        _table,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return VisitModel.fromMap(rows.first);
    } catch (e) {
      throw AppDatabaseException('Failed to load visit $id: $e');
    }
  }

  Future<void> insertVisit(VisitModel model) async {
    try {
      final db = await _db;
      await db.insert(
        _table,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } catch (e) {
      throw AppDatabaseException('Failed to insert visit: $e');
    }
  }

  Future<void> updateSyncStatus({
    required String id,
    required SyncStatus syncStatus,
    int? retryCount,
    DateTime? nextRetryAt,
    String? lastSyncError,
    DateTime? syncedAt,
  }) async {
    try {
      final db = await _db;
      final values = <String, dynamic>{'sync_status': syncStatus.name};
      if (retryCount != null) values['retry_count'] = retryCount;
      if (nextRetryAt != null) {
        values['next_retry_at'] = nextRetryAt.toUtc().toIso8601String();
      }
      if (lastSyncError != null) {
        values['last_sync_error'] = lastSyncError;
      }
      if (syncedAt != null) {
        values['synced_at'] = syncedAt.toUtc().toIso8601String();
        values['last_sync_error'] = null;
        values['next_retry_at'] = null;
      }
      await db.update(_table, values, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw AppDatabaseException('Failed to update sync status for $id: $e');
    }
  }

  Future<List<VisitModel>> getPendingVisits() async {
    try {
      final db = await _db;
      final now = DateTime.now().toUtc().toIso8601String();
      final rows = await db.rawQuery(
        '''
        SELECT * FROM $_table
        WHERE sync_status = 'pending'
           OR (sync_status = 'failed' AND (next_retry_at IS NULL OR next_retry_at <= ?))
        ORDER BY created_at ASC
        ''',
        [now],
      );
      return rows.map(VisitModel.fromMap).toList();
    } catch (e) {
      throw AppDatabaseException('Failed to get pending visits: $e');
    }
  }

  Future<void> recoverStaleSyncingVisits() async {
    try {
      final db = await _db;
      await db.update(
        _table,
        {'sync_status': SyncStatus.pending.name},
        where: "sync_status = 'syncing'",
      );
    } catch (e) {
      throw AppDatabaseException('Failed to recover stale syncing visits: $e');
    }
  }
}
