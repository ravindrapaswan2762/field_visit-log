import 'package:flutter/material.dart';
import '../../../../sync/sync_status.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key, required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, icon, label) = _config();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // (background, border, foreground, icon, label)
  (Color, Color, Color, IconData, String) _config() {
    switch (status) {
      case SyncStatus.synced:
        return (
          const Color(0xFFE5F6EC),
          const Color(0xFFD3EEDD),
          const Color(0xFF1B8F4E),
          Icons.check_circle,
          'Synced',
        );
      case SyncStatus.pending:
        return (
          const Color(0xFFFFF3E2),
          const Color(0xFFFCDDB0),
          const Color(0xFFE8890C),
          Icons.access_time,
          'Pending',
        );
      case SyncStatus.syncing:
        return (
          const Color(0xFFE3EEFD),
          const Color(0xFFCFE1FB),
          const Color(0xFF2563EB),
          Icons.sync,
          'Syncing',
        );
      case SyncStatus.failed:
        return (
          const Color(0xFFFDE9E7),
          const Color(0xFFF9CFCA),
          const Color(0xFFE03A26),
          Icons.error,
          'Failed',
        );
    }
  }
}