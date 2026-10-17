import '../../../../core/widgets/visit_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
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
      final visit =
          await context.read<VisitProvider>().getVisitDetails(widget.visitId);
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
      backgroundColor: const Color(0xFFFAFBFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFBFE),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Visit Details',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: 19,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF0F172A), size: 22),
            onPressed: () {},
            tooltip: 'More',
          ),
          const SizedBox(width: 4),
        ],
      ),
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
            Text(_error!, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadVisit,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8)),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_visit == null) {
      return const Center(
        child: Text('Visit not found.',
            style: TextStyle(color: Color(0xFF64748B))),
      );
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

  static final _dateFormat = DateFormat('MMM d, yyyy');
  static final _timeFormat = DateFormat('hh:mm a');

  // ── Shared UI helpers ────────────────────────────────────────────────────

  static BoxDecoration _cardDecoration({Color? color, Color? border}) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: border ?? const Color(0xFFE5EAF2)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  /// Soft tint (background, border) used by the profile + sync cards.
  (Color, Color) _statusTint() {
    switch (visit.syncStatus) {
      case SyncStatus.synced:
        return (const Color(0xFFF1FAF5), const Color(0xFFD9EFE2));
      case SyncStatus.pending:
        return (const Color(0xFFFFF8EE), const Color(0xFFFBE6C6));
      case SyncStatus.syncing:
        return (const Color(0xFFF0F6FE), const Color(0xFFD6E5FA));
      case SyncStatus.failed:
        return (const Color(0xFFFEF3F2), const Color(0xFFF9D5D1));
    }
  }

  Widget _sectionHeader(
    IconData icon,
    String title, {
    Color tint = const Color(0xFFEAF0FB),
    Color iconColor = const Color(0xFF3B5FB0),
  }) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  /// Keeps the start and the extension of long file names.
  String _shortFileName(String name) {
    if (name.startsWith('data:image')) {
      return 'camera_photo.jpg';
    }
    if (name.length <= 26) return name;
    final ext = p.extension(name);
    final base = p.basenameWithoutExtension(name);
    if (base.length <= 16) return name;
    return '${base.substring(0, 10)}…${base.substring(base.length - 4)}$ext';
  }

  String _fileTypeLabel(String name) {
    if (name.startsWith('data:image')) {
      return 'JPEG image • In-app capture';
    }
    final ext = p.extension(name).replaceFirst('.', '').toUpperCase();
    if (ext.isEmpty) return 'Image';
    if (ext == 'JPG') return 'JPEG image';
    return '$ext image';
  }

  @override
  Widget build(BuildContext context) {
    final localTime = visit.createdAt.toLocal();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Customer Profile Card ─────────────────────────────────────
          _buildProfileCard(context, localTime),
          const SizedBox(height: 12),

          // ── 2. Four-Column Metrics Row ───────────────────────────────────
          _buildMetricsCard(context),
          const SizedBox(height: 12),

          // ── 3. Visit Notes Card ───────────────────────────────────────────
          _buildNotesCard(),
          const SizedBox(height: 12),

          // ── 4. Photo Attachment Card ──────────────────────────────────────
          _buildPhotoCard(context),
          const SizedBox(height: 12),

          // ── 5. Synchronization Status Card ────────────────────────────────
          _buildSyncStatusCard(),
          const SizedBox(height: 12),

          // ── 6. Error Information Card ─────────────────────────────────────
          _buildErrorCard(),
          const SizedBox(height: 14),

          // ── 7. Retry Sync Button ──────────────────────────────────────────
          _buildRetryButton(context),
          const SizedBox(height: 12),

          // ── 8. Bottom Information Banner ──────────────────────────────────
          _buildInfoBanner(),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, DateTime localTime) {
    final (tintBg, tintBorder) = _statusTint();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(color: tintBg, border: tintBorder),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _buildAvatar()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visit.customerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _dateFormat.format(localTime),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('•',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B))),
                        ),
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _timeFormat.format(localTime),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Customer Visit',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Align(
              alignment: Alignment.topRight,
              child: SyncStatusBadge(status: visit.syncStatus),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (visit.hasPhoto) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF1F5F9),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: ClipOval(
          child: SizedBox(
            width: 56,
            height: 56,
            child: VisitImage(
              path: visit.photoPath!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildLetterAvatar(),
            ),
          ),
        ),
      );
    }
    return _buildLetterAvatar();
  }

  Widget _buildLetterAvatar() {
    final initial = visit.customerName.trim().isNotEmpty
        ? visit.customerName.trim()[0].toUpperCase()
        : '?';

    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFFE4E0FA),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF5B3FD0),
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

    Widget _metricTile({
    required IconData icon,
    required String label,
    required Widget value,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF2F63D8)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF6B7FA3),
                    ),
                  ),
                  const SizedBox(height: 3),
                  value,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCard(BuildContext context) {
    final shortId = visit.id.length > 8 ? visit.id.substring(0, 8) : visit.id;
    final syncedAtFormatted = visit.syncedAt != null
        ? DateFormat('MMM d, hh:mm a').format(visit.syncedAt!.toLocal())
        : '—';
    final nextRetryFormatted = visit.nextRetryAt != null
        ? _timeFormat.format(visit.nextRetryAt!.toLocal())
        : '—';

    const valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF0F172A),
    );

    Widget plainValue(String text) => Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: valueStyle,
        );

    const verticalLine = VerticalDivider(
      width: 1,
      thickness: 1,
      color: Color(0xFFE5EAF2),
    );

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                // Item 1: Visit ID
                _metricTile(
                  icon: Icons.description_outlined,
                  label: 'Visit ID',
                  value: Row(
                    children: [
                      Flexible(child: plainValue('vst_$shortId')),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: visit.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Visit ID copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: const Icon(Icons.copy,
                            size: 14, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                verticalLine,
                // Item 2: Synced At
                _metricTile(
                  icon: Icons.sync,
                  label: 'Synced At',
                  value: plainValue(syncedAtFormatted),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5EAF2)),
          IntrinsicHeight(
            child: Row(
              children: [
                // Item 3: Retry Count
                _metricTile(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Retry Count',
                  value: plainValue('${visit.retryCount}'),
                ),
                verticalLine,
                // Item 4: Next Retry
                _metricTile(
                  icon: Icons.update,
                  label: 'Next Retry',
                  value: plainValue(nextRetryFormatted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.article_outlined, 'Visit Notes'),
          const SizedBox(height: 10),
          Text(
            visit.notes,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(BuildContext context) {
    final fileName = visit.hasPhoto ? p.basename(visit.photoPath!) : 'No photo';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.image_outlined, 'Photo Attachment'),
          const SizedBox(height: 12),
          if (visit.hasPhoto)
            InkWell(
              onTap: () => _showPhotoDialog(context),
              borderRadius: BorderRadius.circular(10),
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: SizedBox(
                        width: 60,
                        height: 48,
                        child: VisitImage(
                          path: visit.photoPath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _shortFileName(fileName),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fileTypeLabel(fileName),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 22, color: Color(0xFF64748B)),
                ],
              ),
            )
          else
            const Text(
              'No photo attached.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
        ],
      ),
    );
  }

  void _showPhotoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VisitImage(
              path: visit.photoPath!,
              fit: BoxFit.contain,
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildSyncStatusCard() {
    final isSynced = visit.syncStatus == SyncStatus.synced;
    final isFailed = visit.syncStatus == SyncStatus.failed;
    final isSyncing = visit.syncStatus == SyncStatus.syncing;
    final (tintBg, tintBorder) = _statusTint();

    final title = isSynced
        ? 'Successfully Synced'
        : isFailed
            ? 'Sync Failed'
            : isSyncing
                ? 'Syncing in Progress…'
                : 'Pending Synchronization';

    final subtitle = isSynced
        ? 'This visit has been uploaded to the server.'
        : isFailed
            ? 'Encountered an error while uploading.'
            : isSyncing
                ? 'Uploading visit to remote server.'
                : 'Will synchronize automatically when connected.';

    final icon = isSynced
        ? Icons.check_circle
        : isFailed
            ? Icons.error
            : isSyncing
                ? Icons.sync
                : Icons.access_time_filled;

    final iconColor = isSynced
        ? const Color(0xFF1B8F4E)
        : isFailed
            ? const Color(0xFFDC2626)
            : isSyncing
                ? const Color(0xFF0284C7)
                : const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(color: tintBg, border: tintBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (tinted icon box, same style as the other cards)
          _sectionHeader(
            Icons.cloud_outlined,
            'Synchronization Status',
            tint: tintBorder,
            iconColor: iconColor,
          ),
          const SizedBox(height: 12),

          // Inner white panel: status + synced-at together
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tintBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, color: iconColor, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (visit.syncedAt != null) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, thickness: 1, color: tintBorder),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      const Text(
                        'Synced At',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_dateFormat.format(visit.syncedAt!.toLocal())} • ${_timeFormat.format(visit.syncedAt!.toLocal())}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    final hasError =
        visit.lastSyncError != null && visit.lastSyncError!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasError ? Icons.error_outline : Icons.check_circle_outline,
            size: 22,
            color: hasError
                ? const Color(0xFFDC2626)
                : const Color(0xFF475569),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Error Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 5),
                if (hasError)
                  Text(
                    visit.lastSyncError!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  )
                else
                  const Text(
                    'No errors reported',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.sync, size: 20, color: Colors.white),
      label: const Text(
        'Retry Sync',
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6B93F6),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3EAF6)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 17, color: Color(0xFF2563EB)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This visit is saved locally and will sync automatically when the network is available.',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF3D5A99),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}