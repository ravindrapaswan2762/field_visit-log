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
      backgroundColor: const Color(0xFFFAFBFE),
      appBar: _buildAppBar(context, provider),
      body: _buildBody(context, provider),
      bottomNavigationBar: _buildBottomBar(context, provider),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: SizedBox(
          width: 50,
          height: 50,
          child: FloatingActionButton(
            key: const Key('add_visit_fab'),
            onPressed: () async {
              final added =
                  await Navigator.pushNamed(context, AppRouter.addVisit);
              if (added == true && context.mounted) {
                context.read<VisitProvider>().loadVisits();
              }
            },
            backgroundColor: const Color(0xFF1D4ED8),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 26),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, VisitProvider provider) {
    return AppBar(
      backgroundColor: const Color(0xFFFAFBFE),
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 56,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: const FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          'Field Visit Log',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: 19,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
        ),
      ),
      actions: [
        // Connectivity Status Pill
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: provider.isOnline
                ? const Color(0xFFE8F7EE)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: provider.isOnline
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                provider.isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: provider.isOnline
                      ? const Color(0xFF15803D)
                      : const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                provider.isSyncing
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                        ),
                      )
                    : const Icon(
                        Icons.sync,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                const SizedBox(width: 4),
                const Text(
                  'Sync',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 14),
      ],
    );
  }

  Widget _buildBody(BuildContext context, VisitProvider provider) {
    return Column(
      children: [
        _MetricsCard(provider: provider),
        _FilterRow(provider: provider),
        const SizedBox(height: 6),
        Expanded(child: _VisitList(provider: provider)),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, VisitProvider provider) {
    final lastSyncText = _formatLastSync(provider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFEFF4FD),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.cloud_outlined, size: 20, color: Color(0xFF1D4ED8)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Last sync: $lastSyncText',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF1D4ED8)),
                      ),
                    )
                  : const Icon(Icons.sync, size: 17, color: Color(0xFF1D4ED8)),
              label: const Text(
                'Sync Now',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1D4ED8),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE1EAFB),
                disabledBackgroundColor: const Color(0xFFE1EAFB),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
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
            .fold<DateTime?>(null,
                (prev, curr) => prev == null || curr.isAfter(prev) ? curr : prev) ??
        DateTime.now();

    return DateFormat('MMM d, yyyy • hh:mm a').format(time.toLocal());
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.provider});
  final VisitProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(13, 6, 13, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EAF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F2563EB),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _MetricItem(
              icon: Icons.article_outlined,
              value: '${provider.totalCount}',
              label: 'Total Visits',
              chipIcon: Icons.bar_chart_rounded,
              chipLabel: 'All visits',
              gradient: const [Color(0xFF5B9BFF), Color(0xFF2563EB)],
              haloColor: const Color(0xFFDCE8FD),
              chipBg: const Color(0xFFE6EEFD),
              chipFg: const Color(0xFF2563EB),
            ),
            const _MetricDivider(),
            _MetricItem(
              icon: Icons.access_time_rounded,
              value: '${provider.pendingCount}',
              label: 'Pending',
              chipIcon: Icons.access_time,
              chipLabel: 'Needs sync',
              gradient: const [Color(0xFFFFC857), Color(0xFFFFA11B)],
              haloColor: const Color(0xFFFFEBCF),
              chipBg: const Color(0xFFFFF1DC),
              chipFg: const Color(0xFFE8890C),
              leftPadding: 8,
            ),
            const _MetricDivider(),
            _MetricItem(
              icon: Icons.check_circle_outline_rounded,
              value: '${provider.syncedCount}',
              label: 'Synced',
              chipIcon: Icons.cloud_upload_outlined,
              chipLabel: 'Uploaded',
              gradient: const [Color(0xFF4ADE80), Color(0xFF22A559)],
              haloColor: const Color(0xFFD8F5E2),
              chipBg: const Color(0xFFDDF5E6),
              chipFg: const Color(0xFF1E9D55),
              leftPadding: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: const Color(0xFFDDE4F0),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.chipIcon,
    required this.chipLabel,
    required this.gradient,
    required this.haloColor,
    required this.chipBg,
    required this.chipFg,
    this.leftPadding = 0,
  });

  final IconData icon;
  final String value;
  final String label;
  final IconData chipIcon;
  final String chipLabel;
  final List<Color> gradient;
  final Color haloColor;
  final Color chipBg;
  final Color chipFg;
  final double leftPadding;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(left: leftPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Soft halo + gradient squircle icon (kept small)
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: haloColor,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient,
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 14),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F1F3D),
                            height: 1.1,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5B6B84),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            // Chip under each metric
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(chipIcon, size: 12, color: chipFg),
                    const SizedBox(width: 4),
                    Text(
                      chipLabel,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: chipFg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.provider});
  final VisitProvider provider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: _PillFilter(
              label: 'All',
              icon: Icons.segment,
              selected: provider.statusFilter == null,
              onTap: () => provider.setFilter(null),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _PillFilter(
              label: 'Pending',
              icon: Icons.access_time,
              selected: provider.statusFilter == SyncStatus.pending,
              onTap: () => provider.setFilter(SyncStatus.pending),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _PillFilter(
              label: 'Synced',
              icon: Icons.check_circle_outline,
              selected: provider.statusFilter == SyncStatus.synced,
              onTap: () => provider.setFilter(SyncStatus.synced),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _PillFilter(
              label: 'Failed',
              icon: Icons.error_outline,
              selected: provider.statusFilter == SyncStatus.failed,
              onTap: () => provider.setFilter(SyncStatus.failed),
            ),
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
    final borderColor =
        selected ? const Color(0xFF0D47A1) : const Color(0xFFDDE3EC);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fgColor),
              const SizedBox(width: 5),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
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
              const Icon(Icons.error_outline,
                  size: 48, color: Color(0xFFEF4444)),
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
            padding: const EdgeInsets.only(top: 2, bottom: 80),
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