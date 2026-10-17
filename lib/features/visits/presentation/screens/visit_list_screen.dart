import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../sync/sync_status.dart';
import '../providers/visit_provider.dart';
import '../widgets/visit_card.dart';
import '../../../../routing/app_router.dart';

class VisitListScreen extends StatefulWidget {
  const VisitListScreen({super.key});

  @override
  State<VisitListScreen> createState() => _VisitListScreenState();
}

class _VisitListScreenState extends State<VisitListScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitProvider>().init();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<VisitProvider>().loadVisits();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_visit_fab'),
        onPressed: () async {
          final added = await Navigator.pushNamed(context, AppRouter.addVisit);
          if (added == true && context.mounted) {
            context.read<VisitProvider>().loadVisits();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Visit'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Field Visit Log'),
      actions: [
        // Connectivity indicator
        Consumer<VisitProvider>(
          builder: (_, provider, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Chip(
              avatar: Icon(
                provider.isOnline ? Icons.wifi : Icons.wifi_off,
                size: 16,
              ),
              label: Text(provider.isOnline ? 'Online' : 'Offline'),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        // Manual sync button
        Consumer<VisitProvider>(
          builder: (_, provider, __) => IconButton(
            icon: provider.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Sync now',
            onPressed: provider.isSyncing ? null : provider.syncNow,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer<VisitProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            _SummaryBar(provider: provider),
            _FilterRow(provider: provider),
            Expanded(child: _VisitList(provider: provider)),
          ],
        );
      },
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.provider});
  final VisitProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _SummaryChip(label: 'Total', count: provider.totalCount),
          const SizedBox(width: 12),
          _SummaryChip(
            label: 'Pending',
            count: provider.pendingCount,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          _SummaryChip(
            label: 'Synced',
            count: provider.syncedCount,
            color: Colors.green.shade600,
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.count, this.color});
  final String label;
  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.provider});
  final VisitProvider provider;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: provider.statusFilter == null,
            onSelected: (_) => provider.setFilter(null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Pending',
            selected: provider.statusFilter == SyncStatus.pending,
            onSelected: (_) => provider.setFilter(SyncStatus.pending),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Synced',
            selected: provider.statusFilter == SyncStatus.synced,
            onSelected: (_) => provider.setFilter(SyncStatus.synced),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Failed',
            selected: provider.statusFilter == SyncStatus.failed,
            onSelected: (_) => provider.setFilter(SyncStatus.failed),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _VisitList extends StatelessWidget {
  const _VisitList({required this.provider});
  final VisitProvider provider;

  @override
  Widget build(BuildContext context) {
    switch (provider.state) {
      case VisitLoadState.initial:
      case VisitLoadState.loading:
        return const Center(child: CircularProgressIndicator());

      case VisitLoadState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage ?? 'An error occurred.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: provider.loadVisits,
                child: const Text('Retry'),
              ),
            ],
          ),
        );

      case VisitLoadState.loaded:
        final visits = provider.visits;
        if (visits.isEmpty) {
          return _EmptyState(filter: provider.statusFilter);
        }
        return RefreshIndicator(
          onRefresh: provider.loadVisits,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: visits.length,
            itemBuilder: (context, index) {
              final visit = visits[index];
              return VisitCard(
                key: ValueKey(visit.id),
                visit: visit,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.visitDetails,
                  arguments: visit.id,
                ),
              );
            },
          ),
        );
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.filter});
  final SyncStatus? filter;

  @override
  Widget build(BuildContext context) {
    final message = filter != null
        ? 'No ${filter!.toDisplayString().toLowerCase()} visits.'
        : 'No visits yet.\nTap + to record your first visit.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
