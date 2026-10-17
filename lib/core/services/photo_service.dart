import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Handles photo picking and persistent local storage.
/// Permissions are requested only when the user explicitly chooses to attach a photo.
class PhotoService {
  PhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Lets the user pick an image from the [source] and copies it to
  /// app-managed storage. Returns the local path, or null if the user
  /// cancelled or an error occurred. Never throws – the caller should
  /// treat null as "no photo".
  Future<String?> pickAndSavePhoto({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return null;

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
    return File(path).existsSync();
  }
}
