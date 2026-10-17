import '../repositories/visit_repository.dart';

class SyncPendingVisits {
  const SyncPendingVisits(this._repository);
  final VisitRepository _repository;

  /// Fetches pending visits and attempts to upload each one.
  /// Returns the number of successfully synced visits.
  Future<int> call() async {
    final pending = await _repository.getPendingVisits();
    int synced = 0;
    for (final visit in pending) {
      try {
        await _repository.syncVisit(visit);
        synced++;
      } catch (_) {
        // syncVisit handles local status updates; continue with remaining.
      }
    }
    return synced;
  }
}
