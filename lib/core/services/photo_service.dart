import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'camera_service/camera_capture.dart';

/// Handles photo picking, camera capture, and persistent local storage.
/// Permissions are requested only when the user explicitly chooses to attach a photo.
class PhotoService {
  PhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Lets the user pick an image from [source] or capture from camera,
  /// copying it to app-managed storage.
  /// On Web, if [source] is [ImageSource.camera] and [context] is provided,
  /// opens an in-app live camera modal dialog.
  Future<String?> pickAndSavePhoto({
    ImageSource source = ImageSource.gallery,
    BuildContext? context,
  }) async {
    if (kIsWeb && source == ImageSource.camera && context != null) {
      final captured = await WebCameraHelper.capturePhoto(context);
      return captured;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return null;

      if (kIsWeb) {
        return picked.path;
      }

      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(dir.path, 'visit_photos'));
      if (!photosDir.existsSync()) {
        photosDir.createSync(recursive: true);
      }

      final ext = p.extension(picked.path).isNotEmpty
          ? p.extension(picked.path)
          : '.jpg';
      final destPath = p.join(
        photosDir.path,
        '${DateTime.now().microsecondsSinceEpoch}$ext',
      );

      await File(picked.path).copy(destPath);
      return destPath;
    } catch (_) {
      // Do not log picked.path – may contain PII from file metadata.
      return null;
    }
  }

  /// Returns true if the file at [path] exists on disk.
  bool photoExists(String? path) {
    if (path == null || path.isEmpty) return false;
    if (kIsWeb || path.startsWith('data:image')) return true;
    return File(path).existsSync();
  }
}
