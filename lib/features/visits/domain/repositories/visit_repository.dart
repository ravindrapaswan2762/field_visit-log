import '../entities/visit.dart';
import '../../../../sync/sync_status.dart';

/// Abstract repository contract.
/// The domain layer depends on this interface, never on concrete implementations.
abstract interface class VisitRepository {
  /// Returns all visits sorted newest-first from local storage.
  Future<List<Visit>> getVisits();

  /// Returns visits filtered by [status].
  Future<List<Visit>> getVisitsByStatus(SyncStatus status);

  /// Returns a single visit by [id], or null if not found.
  Future<Visit?> getVisitById(String id);

  /// Persists a new visit locally. Sets [syncStatus] to [SyncStatus.pending].
  /// Must succeed without a network connection.
  Future<void> createVisit(Visit visit);

  /// Updates a visit's synchronization state transactionally.
  Future<void> updateSyncStatus({
    required String id,
    required SyncStatus syncStatus,
    int? retryCount,
    DateTime? nextRetryAt,
    String? lastSyncError,
    DateTime? syncedAt,
  });

  /// Returns visits eligible for synchronization:
  /// status is [pending] or [failed] with [nextRetryAt] <= now.
  Future<List<Visit>> getPendingVisits();

  /// Resets any [syncing] visits back to [pending].
  /// Call on startup to recover from interrupted sync workers.
  Future<void> recoverStaleSyncingVisits();

  /// Uploads a single visit to the remote API.
  /// Throws [AppException] on failure.
  Future<void> syncVisit(Visit visit);
}
