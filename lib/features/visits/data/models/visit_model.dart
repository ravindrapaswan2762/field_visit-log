import '../../domain/entities/visit.dart';
import '../../../../sync/sync_status.dart';

/// Database/JSON mapping model. Converts between the SQLite row map
/// and the domain [Visit] entity.
class VisitModel {
  const VisitModel({
    required this.id,
    required this.customerName,
    required this.notes,
    required this.createdAt,
    required this.syncStatus,
    this.photoPath,
    this.retryCount = 0,
    this.nextRetryAt,
    this.lastSyncError,
    this.syncedAt,
  });

  final String id;
  final String customerName;
  final String notes;
  final DateTime createdAt;
  final String? photoPath;
  final SyncStatus syncStatus;
  final int retryCount;
  final DateTime? nextRetryAt;
  final String? lastSyncError;
  final DateTime? syncedAt;

  factory VisitModel.fromMap(Map<String, dynamic> map) {
    return VisitModel(
      id: map['id'] as String,
      customerName: map['customer_name'] as String,
      notes: map['notes'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      photoPath: map['photo_path'] as String?,
      syncStatus: SyncStatus.fromString(map['sync_status'] as String),
      retryCount: map['retry_count'] as int? ?? 0,
      nextRetryAt: map['next_retry_at'] != null
          ? DateTime.parse(map['next_retry_at'] as String)
          : null,
      lastSyncError: map['last_sync_error'] as String?,
      syncedAt: map['synced_at'] != null
          ? DateTime.parse(map['synced_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'notes': notes,
      'created_at': createdAt.toUtc().toIso8601String(),
      'photo_path': photoPath,
      'sync_status': syncStatus.name,
      'retry_count': retryCount,
      'next_retry_at': nextRetryAt?.toUtc().toIso8601String(),
      'last_sync_error': lastSyncError,
      'synced_at': syncedAt?.toUtc().toIso8601String(),
    };
  }

  factory VisitModel.fromEntity(Visit visit) {
    return VisitModel(
      id: visit.id,
      customerName: visit.customerName,
      notes: visit.notes,
      createdAt: visit.createdAt,
      photoPath: visit.photoPath,
      syncStatus: visit.syncStatus,
      retryCount: visit.retryCount,
      nextRetryAt: visit.nextRetryAt,
      lastSyncError: visit.lastSyncError,
      syncedAt: visit.syncedAt,
    );
  }

  Visit toEntity() {
    return Visit(
      id: id,
      customerName: customerName,
      notes: notes,
      createdAt: createdAt,
      photoPath: photoPath,
      syncStatus: syncStatus,
      retryCount: retryCount,
      nextRetryAt: nextRetryAt,
      lastSyncError: lastSyncError,
      syncedAt: syncedAt,
    );
  }

  /// Produces the JSON body for the POST /api/v1/visits request.
  /// Note: photo upload is not supported by the mock server.
  /// The photoReference field is included as null to satisfy the contract.
  Map<String, dynamic> toApiJson() {
    return {
      'clientVisitId': id,
      'customerName': customerName,
      'notes': notes,
      'visitedAt': createdAt.toUtc().toIso8601String(),
      'photoReference': null,
    };
  }
}
