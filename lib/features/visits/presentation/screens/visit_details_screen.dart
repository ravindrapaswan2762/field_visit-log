import 'dart:io';
import 'package:flutter/foundation.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Visit Details',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF0F172A)),
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
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1D4ED8)),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_visit == null) {
      return const Center(
        child: Text('Visit not found.', style: TextStyle(color: Color(0xFF64748B))),
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

  @override
  Widget build(BuildContext context) {
    final localTime = visit.createdAt.toLocal();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Customer Profile Card ─────────────────────────────────────
          _buildProfileCard(context, localTime),
          const SizedBox(height: 12),

          // ── 2. Four-Column Metrics Row (Zero Overflow Guaranteed) ────────
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
          const SizedBox(height: 16),

          // ── 7. Retry Sync Button ──────────────────────────────────────────
          _buildRetryButton(context),
          const SizedBox(height: 14),

          // ── 8. Bottom Information Banner ──────────────────────────────────
          _buildInfoBanner(),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, DateTime localTime) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _dateFormat.format(localTime),
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                    ),
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _timeFormat.format(localTime),
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Customer Visit',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SyncStatusBadge(status: visit.syncStatus),
        ],
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
            child: kIsWeb
                ? Image.network(
                    visit.photoPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildLetterAvatar(),
                  )
                : Image.file(
                    File(visit.photoPath!),
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
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFFEDE9FE),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF6D28D9),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMetricsCard(BuildContext context) {
    final shortId = visit.id.length > 8 ? visit.id.substring(0, 8) : visit.id;
    final syncedAtFormatted = visit.syncedAt != null
        ? '${_dateFormat.format(visit.syncedAt!.toLocal())}\n${_timeFormat.format(visit.syncedAt!.toLocal())}'
        : '—';
    final nextRetryFormatted = visit.nextRetryAt != null
        ? _timeFormat.format(visit.nextRetryAt!.toLocal())
        : '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
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
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Item 1: Visit ID (Wrapped in FittedBox to guarantee 0 overflow)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.article_outlined, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(height: 4),
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Visit ID', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'vst_$shortId',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 3),
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
                          child: const Icon(Icons.copy, size: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(color: Color(0xFFE2E8F0), thickness: 1, width: 4),

            // Item 2: Synced At (Wrapped in FittedBox)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sync, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(height: 4),
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Synced At', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      syncedAtFormatted,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(color: Color(0xFFE2E8F0), thickness: 1, width: 4),

            // Item 3: Retry Count (Wrapped in FittedBox)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(height: 4),
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Retry Count', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${visit.retryCount}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(color: Color(0xFFE2E8F0), thickness: 1, width: 4),

            // Item 4: Next Retry (Wrapped in FittedBox)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(height: 4),
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Next Retry', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      nextRetryFormatted,
                      style: TextStyle(
                        fontSize: nextRetryFormatted == '—' ? 13 : 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.article_outlined, size: 15, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 8),
              const Text(
                'Visit Notes',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            visit.notes,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              height: 1.45,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.image_outlined, size: 15, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 8),
              const Text(
                'Photo Attachment',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (visit.hasPhoto)
            InkWell(
              onTap: () => _showPhotoDialog(context),
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: SizedBox(
                        width: 56,
                        height: 50,
                        child: kIsWeb
                            ? Image.network(
                                visit.photoPath!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                              )
                            : Image.file(
                                File(visit.photoPath!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
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
                          fileName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          '2.4 MB • JPEG',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
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
            kIsWeb
                ? Image.network(visit.photoPath!, fit: BoxFit.contain)
                : Image.file(File(visit.photoPath!), fit: BoxFit.contain),
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
        ? const Color(0xFF16A34A)
        : isFailed
            ? const Color(0xFFDC2626)
            : isSyncing
                ? const Color(0xFF0284C7)
                : const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud_outlined, size: 18, color: Color(0xFF0F172A)),
              SizedBox(width: 8),
              Text(
                'Synchronization Status',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              if (visit.syncedAt != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Color(0xFF15803D)),
                          const SizedBox(width: 4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Synced At',
                                style: TextStyle(fontSize: 9, color: Color(0xFF15803D)),
                              ),
                              Text(
                                '${_dateFormat.format(visit.syncedAt!.toLocal())} • ${_timeFormat.format(visit.syncedAt!.toLocal())}',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    final hasError = visit.lastSyncError != null && visit.lastSyncError!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 20, color: Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Error Information',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                if (hasError)
                  Text(
                    visit.lastSyncError!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else ...[
                  const Text('—', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const Text('No errors', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
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
      icon: const Icon(Icons.sync, size: 18, color: Colors.white),
      label: const Text(
        'Retry Sync',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6B93F6),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This visit is saved locally and will sync automatically when the network is available.',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF1E40AF),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
