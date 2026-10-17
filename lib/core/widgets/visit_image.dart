import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Renders a visit photo across all platforms and formats:
/// - data URLs (`data:image/...;base64,...`) -> decoded to `Image.memory`
/// - network URLs (`http://`, `https://`) -> `Image.network`
/// - blob URLs (`blob:...`) -> `Image.network` on web
/// - local file paths -> `Image.file` on mobile / desktop
class VisitImage extends StatelessWidget {
  const VisitImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  Widget _defaultError(BuildContext context, Object error, StackTrace? stack) {
    if (errorBuilder != null) {
      return errorBuilder!(context, error, stack);
    }
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, size: 24, color: Color(0xFF94A3B8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return _defaultError(context, 'Empty path', null);
    }

    // 1. Data URI (Base64 from Web Camera or inline data)
    if (path.startsWith('data:image')) {
      final commaIndex = path.indexOf(',');
      final base64String =
          commaIndex != -1 ? path.substring(commaIndex + 1) : path;
      try {
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: _defaultError,
        );
      } catch (e, st) {
        return _defaultError(context, e, st);
      }
    }

    // 2. Web or Remote URL or Blob URL
    if (kIsWeb ||
        path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('blob:')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: _defaultError,
      );
    }

    // 3. Local File on Native Device
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: _defaultError,
    );
  }
}
