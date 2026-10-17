/// Represents the synchronization lifecycle of a visit record.
enum SyncStatus {
  /// Not yet sent to the server.
  pending,

  /// Upload in progress (may become stale if the process is killed).
  syncing,

  /// Server confirmed receipt.
  synced,

  /// Upload failed; may be retried depending on [retryCount].
  failed;

  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncStatus.pending,
    );
  }

  String toDisplayString() {
    switch (this) {
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.syncing:
        return 'Syncing…';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.failed:
        return 'Failed';
    }
  }
}
