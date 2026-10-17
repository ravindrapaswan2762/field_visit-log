import 'package:flutter/material.dart';
import '../../../../sync/sync_status.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key, required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, textColor, icon, label) = _config();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, IconData, String) _config() {
    switch (status) {
      case SyncStatus.synced:
        return (
          const Color(0xFFDCFCE7),
          const Color(0xFF15803D),
          Icons.check_circle,
          'Synced',
        );
      case SyncStatus.pending:
        return (
          const Color(0xFFFEF3C7),
          const Color(0xFFD97706),
          Icons.access_time_filled,
          'Pending',
        );
      case SyncStatus.syncing:
        return (
          const Color(0xFFE0F2FE),
          const Color(0xFF0284C7),
          Icons.sync,
          'Syncing',
        );
      case SyncStatus.failed:
        return (
          const Color(0xFFFEE2E2),
          const Color(0xFFDC2626),
          Icons.error,
          'Failed',
        );
    }
  }
}
