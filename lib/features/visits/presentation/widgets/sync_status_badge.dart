import 'package:flutter/material.dart';
import '../../../../sync/sync_status.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key, required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = _config(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color, semanticLabel: label),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }

  (Color, IconData, String) _config(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case SyncStatus.pending:
        return (cs.onSurface.withValues(alpha: 0.6), Icons.schedule, 'Pending');
      case SyncStatus.syncing:
        return (cs.primary, Icons.sync, 'Syncing…');
      case SyncStatus.synced:
        return (Colors.green.shade600, Icons.check_circle_outline, 'Synced');
      case SyncStatus.failed:
        return (cs.error, Icons.error_outline, 'Failed');
    }
  }
}
