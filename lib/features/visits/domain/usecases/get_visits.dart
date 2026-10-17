import '../entities/visit.dart';
import '../repositories/visit_repository.dart';
import '../../../../sync/sync_status.dart';

class GetVisits {
  const GetVisits(this._repository);
  final VisitRepository _repository;

  /// Pass [statusFilter] to limit results to a specific sync state.
  Future<List<Visit>> call({SyncStatus? statusFilter}) async {
    if (statusFilter != null) {
      return _repository.getVisitsByStatus(statusFilter);
    }
    return _repository.getVisits();
  }
}
