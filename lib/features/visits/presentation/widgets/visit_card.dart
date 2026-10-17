import 'dart:io';
import 'package:flutter/foundation.dart';
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _VisitAvatar(visit: visit),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        visit.customerName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _dateFormat.format(localTime),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        visit.notes,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SyncStatusBadge(status: visit.syncStatus),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.only(right: 2),
                      child: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    if (visit.hasPhoto) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF1F5F9),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipOval(
              child: SizedBox(
                width: 48,
                height: 48,
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
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.image,
                size: 8,
                color: Colors.white,
              ),
            ),
          ),
        ],
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
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: fg,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  (Color, Color) _pickColor(String char) {
    final code = char.codeUnitAt(0);
    switch (code % 4) {
      case 0:
        return (const Color(0xFFEDE9FE), const Color(0xFF6D28D9)); // lavender
      case 1:
        return (const Color(0xFFDCFCE7), const Color(0xFF047857)); // mint
      case 2:
        return (const Color(0xFFE0F2FE), const Color(0xFF0284C7)); // sky
      default:
        return (const Color(0xFFFEF3C7), const Color(0xFFB45309)); // amber
    }
  }
}
