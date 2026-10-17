import '../../../../core/widgets/visit_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/photo_service.dart';

/// Self-contained widget that handles photo attachment for a visit.
/// Shows a button to pick a photo if none is attached, or a preview
/// thumbnail with a remove action if one is already selected.
class PhotoAttachment extends StatelessWidget {
  const PhotoAttachment({
    super.key,
    required this.photoPath,
    required this.onPhotoSelected,
    required this.onPhotoRemoved,
    this.enabled = true,
  });

  final String? photoPath;
  final ValueChanged<String?> onPhotoSelected;
  final VoidCallback onPhotoRemoved;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (photoPath != null && photoPath!.isNotEmpty) {
      return _PhotoPreview(
        path: photoPath!,
        onRemove: enabled ? onPhotoRemoved : null,
      );
    }

    return _PhotoPickerButton(
      enabled: enabled,
      onPhotoSelected: onPhotoSelected,
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.path, this.onRemove});
  final String path;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final imageWidget = VisitImage(
      path: path,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _MissingPhoto(),
    );

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageWidget,
        ),
        if (onRemove != null)
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                tooltip: 'Remove photo',
                onPressed: onRemove,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoPickerButton extends StatelessWidget {
  const _PhotoPickerButton({
    required this.enabled,
    required this.onPhotoSelected,
  });

  final bool enabled;
  final ValueChanged<String?> onPhotoSelected;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? () => _showSourceDialog(context) : null,
      icon: const Icon(Icons.photo_camera_outlined),
      label: const Text('Attach Photo (optional)'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSourceDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pick(ImageSource.camera, context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pick(ImageSource.gallery, context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(ImageSource source, BuildContext context) async {
    final service = PhotoService();
    final path = await service.pickAndSavePhoto(source: source, context: context);
    if (path != null) {
      onPhotoSelected(path);
    }
  }
}

class _MissingPhoto extends StatelessWidget {
  const _MissingPhoto();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: Colors.grey.shade600, size: 36),
          const SizedBox(height: 8),
          Text(
            'Photo could not be loaded',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
