import 'package:uuid/uuid.dart';
import '../entities/visit.dart';
import '../repositories/visit_repository.dart';
import '../../../../sync/sync_status.dart';

class CreateVisit {
  const CreateVisit(this._repository);
  final VisitRepository _repository;

  Future<Visit> call({
    required String customerName,
    required String notes,
    String? photoPath,
  }) async {
    final visit = Visit(
      id: const Uuid().v4(), // stable, client-generated idempotency key
      customerName: customerName.trim(),
      notes: notes.trim(),
      createdAt: DateTime.now().toUtc(),
      photoPath: photoPath,
      syncStatus: SyncStatus.pending,
    );
    await _repository.createVisit(visit);
    return visit;
  }
}
