import '../../../../core/widgets/visit_image.dart';
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

  static final _dateFormat = DateFormat('MMM d, yyyy • hh:mm a');

  @override
  Widget build(BuildContext context) {
    final localTime = visit.createdAt.toLocal();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
  onTap: onTap,
  borderRadius: BorderRadius.circular(14),
  hoverColor: Colors.transparent,
  focusColor: Colors.transparent,
  highlightColor: Colors.transparent,
  splashColor: const Color(0x140F172A), // keeps a subtle tap ripple
  child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _VisitAvatar(visit: visit)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visit.customerName,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
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
                              size: 13,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _dateFormat.format(localTime),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          visit.notes,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SyncStatusBadge(status: visit.syncStatus),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VisitAvatar extends StatelessWidget {
  const _VisitAvatar({required this.visit});

  final Visit visit;

  static const double _size = 46;

  @override
  Widget build(BuildContext context) {
    if (visit.hasPhoto) {
      return SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: SizedBox(
                width: _size,
                height: _size,
                child: VisitImage(
                  path: visit.photoPath!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildLetterAvatar(),
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: const Icon(
                  Icons.image,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _buildLetterAvatar();
  }

  Widget _buildLetterAvatar() {
    final initial = visit.customerName.trim().isNotEmpty
        ? visit.customerName.trim()[0].toUpperCase()
        : '?';

    final (bg, fg) = _pickColor(initial);

    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: fg,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  (Color, Color) _pickColor(String char) {
    final code = char.codeUnitAt(0);
    switch (code % 4) {
      case 0:
        return (const Color(0xFFE4E0FA), const Color(0xFF5B3FD0)); // lavender
      case 1:
        return (const Color(0xFFD5F0E0), const Color(0xFF15803D)); // mint
      case 2:
        return (const Color(0xFFE0F2FE), const Color(0xFF0284C7)); // sky
      default:
        return (const Color(0xFFFEF3C7), const Color(0xFFB45309)); // amber
    }
  }
}