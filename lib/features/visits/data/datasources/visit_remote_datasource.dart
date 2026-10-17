import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/visit_model.dart';

/// Handles all remote API calls for visits.
/// Callers should handle [AppException] subtypes appropriately.
class VisitRemoteDatasource {
  VisitRemoteDatasource({ApiClient? apiClient})
      : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  /// Uploads [model] to POST /api/v1/visits.
  /// Uses the visit's stable [id] as the idempotency key so that
  /// retries after a lost response do not create duplicate server records.
  Future<Map<String, dynamic>> uploadVisit(VisitModel model) async {
    return _client.post(
      AppConstants.visitsEndpoint,
      body: model.toApiJson(),
      headers: {
        AppConstants.idempotencyKeyHeader: model.id,
      },
    );
  }
}
