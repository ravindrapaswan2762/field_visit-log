import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/visit.dart';
import '../../../../sync/sync_status.dart';
import '../providers/visit_provider.dart';
import '../widgets/sync_status_badge.dart';

class VisitDetailsScreen extends StatefulWidget {
  const VisitDetailsScreen({super.key, required this.visitId});
  final String visitId;

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> {
  Visit? _visit;
  bool _loading = true;
  String? _error;


  @override
  void initState() {
    super.initState();
    _loadVisit();
  }

  Future<void> _loadVisit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final visit = await context.read<VisitProvider>().getVisitDetails(widget.visitId);
      if (mounted) {
        setState(() {
          _visit = visit;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load visit details.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visit Details')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadVisit, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_visit == null) {
      return const Center(child: Text('Visit not found.'));
    }
    return _VisitDetailsContent(
      visit: _visit!,
      onRetry: () async {
        await context.read<VisitProvider>().syncNow();
        await _loadVisit();
      },
    );
  }
}

class _VisitDetailsContent extends StatelessWidget {
  const _VisitDetailsContent({required this.visit, required this.onRetry});
  final Visit visit;
  final VoidCallback onRetry;

  static final _dateFormat = DateFormat('EEEE, MMMM d, yyyy · h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localTime = visit.createdAt.toLocal();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer name
          Text(
            visit.customerName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          // Date
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                _dateFormat.format(localTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sync status
          SyncStatusBadge(status: visit.syncStatus),
          if (visit.lastSyncError != null &&
              visit.syncStatus == SyncStatus.failed) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.onErrorContainer,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      visit.lastSyncError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (visit.nextRetryAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Next retry: ${DateFormat.jm().format(visit.nextRetryAt!.toLocal())}',
                style: theme.textTheme.labelSmall,
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Sync'),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Notes
          Text('Visit Notes', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(visit.notes, style: theme.textTheme.bodyMedium),

          // Photo
          if (visit.hasPhoto) ...[
            const SizedBox(height: 24),
            Text('Photo', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _buildPhoto(visit.photoPath!),
          ],

          // Synced at
          if (visit.syncedAt != null) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Synced on ${DateFormat('MMM d, yyyy · h:mm a').format(visit.syncedAt!.toLocal())}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhoto(String path) {
    if (!File(path).existsSync()) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Photo file not found.'),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => const Text('Could not display photo.'),
      ),
    );
  }
}
