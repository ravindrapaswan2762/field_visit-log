import 'dart:async';
import '../core/network/connectivity_service.dart';
import '../features/visits/domain/usecases/sync_pending_visits.dart';
import '../features/visits/domain/repositories/visit_repository.dart';

/// Orchestrates foreground synchronization.
/// Listens for connectivity changes and triggers sync accordingly.
/// Background sync is handled separately by [SyncWorker] via WorkManager.
class SyncManager {
  SyncManager({
    required SyncPendingVisits syncPendingVisits,
    required VisitRepository repository,
    required ConnectivityService connectivityService,
  })  : _syncPendingVisits = syncPendingVisits,
        _repository = repository,
        _connectivityService = connectivityService;

  final SyncPendingVisits _syncPendingVisits;
  final VisitRepository _repository;
  final ConnectivityService _connectivityService;

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;

  /// Initialises the manager: recovers stale records and subscribes
  /// to connectivity events.
  Future<void> init() async {
    await _repository.recoverStaleSyncingVisits();

    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        syncNow();
      }
    });

    // Attempt an immediate sync on startup if online.
    final isOnline = await _connectivityService.isConnected;
    if (isOnline) {
      await syncNow();
    }
  }

  /// Triggers a synchronization pass. Skips if one is already running.
  Future<int> syncNow() async {
    if (_isSyncing) return 0;
    _isSyncing = true;
    try {
      return await _syncPendingVisits();
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
