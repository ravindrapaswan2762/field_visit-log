import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/photo_service.dart';

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
    if (photoPath != null && File(photoPath!).existsSync()) {
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
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _MissingPhoto(),
          ),
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
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pick(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pick(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final service = PhotoService();
    final path = await service.pickAndSavePhoto(source: source);
    onPhotoSelected(path);
  }
}

class _MissingPhoto extends StatelessWidget {
  const _MissingPhoto();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, size: 40),
      ),
    );
  }
}
