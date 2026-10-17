import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../sync/retry_policy.dart';
import '../../../../sync/sync_status.dart';
import '../../domain/entities/visit.dart';
import '../../domain/repositories/visit_repository.dart';
import '../datasources/visit_local_datasource.dart';
import '../datasources/visit_remote_datasource.dart';
import '../models/visit_model.dart';

class VisitRepositoryImpl implements VisitRepository {
  VisitRepositoryImpl({
    required VisitLocalDatasource localDatasource,
    required VisitRemoteDatasource remoteDatasource,
    RetryPolicy? retryPolicy,
  })  : _local = localDatasource,
        _remote = remoteDatasource,
        _retryPolicy = retryPolicy ?? const RetryPolicy();

  final VisitLocalDatasource _local;
  final VisitRemoteDatasource _remote;
  final RetryPolicy _retryPolicy;

  @override
  Future<List<Visit>> getVisits() async {
    final models = await _local.getAllVisits();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Visit>> getVisitsByStatus(SyncStatus status) async {
    final models = await _local.getVisitsByStatus(status);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Visit?> getVisitById(String id) async {
    final model = await _local.getVisitById(id);
    return model?.toEntity();
  }

  @override
  Future<void> createVisit(Visit visit) async {
    final model = VisitModel.fromEntity(visit);
    await _local.insertVisit(model);
  }

  @override
  Future<void> updateSyncStatus({
    required String id,
    required SyncStatus syncStatus,
    int? retryCount,
    DateTime? nextRetryAt,
    String? lastSyncError,
    DateTime? syncedAt,
  }) async {
    await _local.updateSyncStatus(
      id: id,
      syncStatus: syncStatus,
      retryCount: retryCount,
      nextRetryAt: nextRetryAt,
      lastSyncError: lastSyncError,
      syncedAt: syncedAt,
    );
  }

  @override
  Future<List<Visit>> getPendingVisits() async {
    final models = await _local.getPendingVisits();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> recoverStaleSyncingVisits() async {
    await _local.recoverStaleSyncingVisits();
  }

  @override
  Future<void> syncVisit(Visit visit) async {
    // Mark as syncing so concurrent workers skip it.
    await _local.updateSyncStatus(
      id: visit.id,
      syncStatus: SyncStatus.syncing,
    );

    try {
      final model = VisitModel.fromEntity(visit);
      await _remote.uploadVisit(model);

      // Server acknowledged — mark synced.
      await _local.updateSyncStatus(
        id: visit.id,
        syncStatus: SyncStatus.synced,
        syncedAt: DateTime.now().toUtc(),
      );
    } on AuthException catch (e) {
      // Auth failures are permanent; mark failed but cap retries.
      await _local.updateSyncStatus(
        id: visit.id,
        syncStatus: SyncStatus.failed,
        retryCount: visit.retryCount + 1,
        lastSyncError: e.message,
      );
      rethrow;
    } on ValidationServerException catch (e) {
      // Validation failures will not improve with retries — exhaust limit.
      await _local.updateSyncStatus(
        id: visit.id,
        syncStatus: SyncStatus.failed,
        retryCount: AppConstants.maxRetryCount,
        lastSyncError: e.message,
      );
      rethrow;
    } on RateLimitException catch (e) {
      final nextRetry = e.retryAfter != null
          ? DateTime.now().toUtc().add(e.retryAfter!)
          : _retryPolicy.nextRetryTime(visit.retryCount);
      await _local.updateSyncStatus(
        id: visit.id,
        syncStatus: SyncStatus.failed,
        retryCount: visit.retryCount + 1,
        nextRetryAt: nextRetry,
        lastSyncError: e.message,
      );
      rethrow;
    } on AppException catch (e) {
      final nextRetry = _retryPolicy.nextRetryTime(visit.retryCount);
      await _local.updateSyncStatus(
        id: visit.id,
        syncStatus: SyncStatus.failed,
        retryCount: visit.retryCount + 1,
        nextRetryAt: nextRetry,
        lastSyncError: _sanitizeError(e.message),
      );
      rethrow;
    } catch (_) {
      await _local.updateSyncStatus(
        id: visit.id,
        syncStatus: SyncStatus.failed,
        retryCount: visit.retryCount + 1,
        nextRetryAt: _retryPolicy.nextRetryTime(visit.retryCount),
        lastSyncError: 'Unexpected error during sync.',
      );
      rethrow;
    }
  }

  String _sanitizeError(String raw) {
    if (raw.length > 200) return '${raw.substring(0, 200)}…';
    return raw;
  }
}
