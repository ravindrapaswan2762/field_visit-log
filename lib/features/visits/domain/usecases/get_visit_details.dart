import '../entities/visit.dart';
import '../repositories/visit_repository.dart';

class GetVisitDetails {
  const GetVisitDetails(this._repository);
  final VisitRepository _repository;

  Future<Visit?> call(String id) => _repository.getVisitById(id);
}
