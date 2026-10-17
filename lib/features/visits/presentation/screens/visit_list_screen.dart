import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../routing/app_router.dart';
import '../../../../sync/sync_status.dart';
import '../providers/visit_provider.dart';
import '../widgets/visit_card.dart';

class VisitListScreen extends StatefulWidget {
  const VisitListScreen({super.key});

  @override
  State<VisitListScreen> createState() => _VisitListScreenState();
}

class _VisitListScreenState extends State<VisitListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VisitProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context, provider),
      body: _buildBody(context, provider),
      bottomNavigationBar: _buildBottomBar(context, provider),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton(
          key: const Key('add_visit_fab'),
          onPressed: () async {
            final added = await Navigator.pushNamed(context, AppRouter.addVisit);
            if (added == true && context.mounted) {
              context.read<VisitProvider>().loadVisits();
            }
          },
          backgroundColor: const Color(0xFF1D4ED8),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, VisitProvider provider) {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Color(0xFF0F172A), size: 22),
        onPressed: () {},
        tooltip: 'Menu',
      ),
      title: const Text(
        'Field Visit Log',
        style: TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        // Connectivity Status Pill
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: provider.isOnline ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: provider.isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: provider.isOnline ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                provider.isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: provider.isOnline ? const Color(0xFF15803D) : const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Sync Pill Button
        InkWell(
          onTap: provider.isSyncing ? null : provider.syncNow,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                provider.isSyncing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                        ),
                      )
                    : const Icon(
                        Icons.sync,
                        size: 15,
                        color: Color(0xFF2563EB),
                      ),
                const SizedBox(width: 4),
                const Text(
                  'Sync',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // More options
        IconButton(
          icon: const Icon(Icons.more_vert, color: Color(0xFF475569), size: 20),
          onPressed: () {},
          tooltip: 'More',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody(BuildContext context, VisitProvider provider) {
    return Column(
      children: [
        _MetricsCard(provider: provider),
        _FilterRow(provider: provider),
        const SizedBox(height: 4),
        Expanded(child: _VisitList(provider: provider)),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, VisitProvider provider) {
    final lastSyncText = _formatLastSync(provider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.cloud_outlined, size: 20, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Last sync: $lastSyncText',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: provider.isSyncing ? null : provider.syncNow,
              icon: provider.isSyncing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.sync, size: 16, color: Colors.white),
              label: const Text(
                'Sync Now',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastSync(VisitProvider provider) {
    final time = provider.lastSyncTime ??
        provider.visits
            .where((v) => v.syncedAt != null)
            .map((v) => v.syncedAt!)
            .fold<DateTime?>(null, (prev, curr) => prev == null || curr.isAfter(prev) ? curr : prev) ??
        DateTime.now();

    return DateFormat('MMM d, yyyy · hh:mm a').format(time.toLocal());
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.provider});
  final VisitProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total Visits
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D4ED8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.article_outlined, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${provider.totalCount}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Text(
                      'Total Visits',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Pending
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.access_time, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${provider.pendingCount}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Text(
                      'Pending',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Synced
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${provider.syncedCount}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Text(
                      'Synced',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          _PillFilter(
            label: 'All',
            icon: Icons.segment,
            selected: provider.statusFilter == null,
            onTap: () => provider.setFilter(null),
          ),
          const SizedBox(width: 8),
          _PillFilter(
            label: 'Pending',
            icon: Icons.access_time,
            selected: provider.statusFilter == SyncStatus.pending,
            onTap: () => provider.setFilter(SyncStatus.pending),
          ),
          const SizedBox(width: 8),
          _PillFilter(
            label: 'Synced',
            icon: Icons.check_circle_outline,
            selected: provider.statusFilter == SyncStatus.synced,
            onTap: () => provider.setFilter(SyncStatus.synced),
          ),
          const SizedBox(width: 8),
          _PillFilter(
            label: 'Failed',
            icon: Icons.error_outline,
            selected: provider.statusFilter == SyncStatus.failed,
            onTap: () => provider.setFilter(SyncStatus.failed),
          ),
        ],
      ),
    );
  }
}

class _PillFilter extends StatelessWidget {
  const _PillFilter({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? const Color(0xFF0D47A1) : Colors.white;
    final fgColor = selected ? Colors.white : const Color(0xFF475569);
    final borderColor = selected ? const Color(0xFF0D47A1) : const Color(0xFFE2E8F0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fgColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage ?? 'An error occurred.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF475569)),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: provider.loadVisits,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                ),
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
            padding: const EdgeInsets.only(top: 4, bottom: 80),
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
            const Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
