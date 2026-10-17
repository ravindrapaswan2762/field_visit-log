import 'package:flutter/foundation.dart';
import '../../../../sync/sync_status.dart';
import '../../domain/entities/visit.dart';
import '../../domain/usecases/create_visit.dart';
import '../../domain/usecases/get_visit_details.dart';
import '../../domain/usecases/get_visits.dart';
import '../../domain/usecases/sync_pending_visits.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../sync/sync_worker.dart';

enum VisitLoadState { initial, loading, loaded, error }

class VisitProvider extends ChangeNotifier {
  VisitProvider({
    required GetVisits getVisits,
    required CreateVisit createVisit,
    required GetVisitDetails getVisitDetails,
    required SyncPendingVisits syncPendingVisits,
    required ConnectivityService connectivityService,
  })  : _getVisits = getVisits,
        _createVisit = createVisit,
        _getVisitDetails = getVisitDetails,
        _syncPendingVisits = syncPendingVisits,
        _connectivityService = connectivityService;

  final GetVisits _getVisits;
  final CreateVisit _createVisit;
  final GetVisitDetails _getVisitDetails;
  final SyncPendingVisits _syncPendingVisits;
  final ConnectivityService _connectivityService;

  List<Visit> _visits = [];
  VisitLoadState _state = VisitLoadState.initial;
  String? _errorMessage;
  bool _isSyncing = false;
  bool _isOnline = false;
  SyncStatus? _statusFilter;
  bool _isSaving = false;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Visit> get visits => _statusFilter == null
      ? _visits
      : _visits.where((v) => v.syncStatus == _statusFilter).toList();

  VisitLoadState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  SyncStatus? get statusFilter => _statusFilter;
  bool get isSaving => _isSaving;

  int get totalCount => _visits.length;
  int get pendingCount =>
      _visits.where((v) => v.syncStatus == SyncStatus.pending || v.syncStatus == SyncStatus.failed).length;
  int get syncedCount =>
      _visits.where((v) => v.syncStatus == SyncStatus.synced).length;

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> init() async {
    _isOnline = await _connectivityService.isConnected;
    _connectivityService.onConnectivityChanged.listen((online) {
      _isOnline = online;
      notifyListeners();
      if (online) _triggerSync();
    });
    await loadVisits();
  }

  // ── Load visits ───────────────────────────────────────────────────────────

  Future<void> loadVisits() async {
    _state = VisitLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _visits = await _getVisits();
      _state = VisitLoadState.loaded;
    } catch (e) {
      _errorMessage = 'Failed to load visits. Please try again.';
      _state = VisitLoadState.error;
    }
    notifyListeners();
  }

  // ── Create visit ──────────────────────────────────────────────────────────

  Future<bool> addVisit({
    required String customerName,
    required String notes,
    String? photoPath,
  }) async {
    if (_isSaving) return false;
    _isSaving = true;
    notifyListeners();

    try {
      final visit = await _createVisit(
        customerName: customerName,
        notes: notes,
        photoPath: photoPath,
      );
      _visits = [visit, ..._visits];
      notifyListeners();

      // Schedule background sync — fire and forget.
      _triggerSync();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ── Sync ──────────────────────────────────────────────────────────────────

  Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      await _syncPendingVisits();
      await loadVisits();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void _triggerSync() {
    if (_isOnline) {
      syncNow();
      scheduleBackgroundSync();
    } else {
      scheduleBackgroundSync();
    }
  }

  // ── Filter ────────────────────────────────────────────────────────────────

  void setFilter(SyncStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  // ── Visit details ─────────────────────────────────────────────────────────

  Future<Visit?> getVisitDetails(String id) => _getVisitDetails(id);
}
