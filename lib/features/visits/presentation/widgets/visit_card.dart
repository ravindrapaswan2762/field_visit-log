import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/visit.dart';
import 'sync_status_badge.dart';

class VisitCard extends StatelessWidget {
  const VisitCard({
    super.key,
    required this.visit,
    required this.onTap,
  });

  final Visit visit;
  final VoidCallback onTap;

  static final _dateFormat = DateFormat('MMM d, yyyy · h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localTime = visit.createdAt.toLocal();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      visit.customerName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (visit.hasPhoto)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.photo_camera_outlined,
                        size: 18,
                        color: theme.colorScheme.primary,
                        semanticLabel: 'Has photo',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _dateFormat.format(localTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                visit.notes,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              SyncStatusBadge(status: visit.syncStatus),
            ],
          ),
        ),
      ),
    );
  }
}
