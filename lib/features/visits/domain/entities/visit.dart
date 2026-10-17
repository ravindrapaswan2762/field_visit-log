import '../../../../sync/sync_status.dart';

/// Pure domain entity. Contains no Flutter or persistence dependencies.
class Visit {
  const Visit({
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

  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;

  Visit copyWith({
    String? id,
    String? customerName,
    String? notes,
    DateTime? createdAt,
    String? photoPath,
    SyncStatus? syncStatus,
    int? retryCount,
    DateTime? nextRetryAt,
    String? lastSyncError,
    DateTime? syncedAt,
    bool clearNextRetryAt = false,
    bool clearLastSyncError = false,
    bool clearSyncedAt = false,
  }) {
    return Visit(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      photoPath: photoPath ?? this.photoPath,
      syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: clearNextRetryAt ? null : (nextRetryAt ?? this.nextRetryAt),
      lastSyncError:
          clearLastSyncError ? null : (lastSyncError ?? this.lastSyncError),
      syncedAt: clearSyncedAt ? null : (syncedAt ?? this.syncedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Visit && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
