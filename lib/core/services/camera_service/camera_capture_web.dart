// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<String?> capturePhotoFromWeb(BuildContext context) async {
  return showDialog<String?>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _WebCameraDialog(),
  );
}

class _WebCameraDialog extends StatefulWidget {
  const _WebCameraDialog();

  @override
  State<_WebCameraDialog> createState() => _WebCameraDialogState();
}

class _WebCameraDialogState extends State<_WebCameraDialog> {
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  String? _viewId;
  bool _isLoading = true;
  String? _errorMessage;
  String? _capturedDataUrl;
  List<html.MediaDeviceInfo> _videoDevices = [];
  int _currentDeviceIndex = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera([String? deviceId]) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _capturedDataUrl = null;
    });

    _stopStream();

    final nav = html.window.navigator;
    if (nav.mediaDevices == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Camera API is not supported in this browser.';
        });
      }
      return;
    }

    try {
      if (_videoDevices.isEmpty) {
        final allDevices = await nav.mediaDevices!.enumerateDevices();
        _videoDevices = allDevices
            .where((d) => d.kind == 'videoinput')
            .cast<html.MediaDeviceInfo>()
            .toList();
      }

      Map<String, dynamic> videoConstraints;
      if (deviceId != null) {
        videoConstraints = {
          'deviceId': {'exact': deviceId}
        };
      } else {
        videoConstraints = {
          'facingMode': {'ideal': 'environment'},
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        };
      }

      html.MediaStream stream;
      try {
        stream = await nav.mediaDevices!
            .getUserMedia({'video': videoConstraints, 'audio': false});
      } catch (_) {
        stream = await nav.mediaDevices!
            .getUserMedia({'video': true, 'audio': false});
      }

      _mediaStream = stream;
      _viewId = 'web-camera-view-${DateTime.now().millisecondsSinceEpoch}';

      final video = html.VideoElement()
        ..autoplay = true
        ..muted = true
                ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.borderRadius = '12px'
        ..srcObject = stream;

      video.setAttribute('playsinline', 'true');
      video.play();
      _videoElement = video;

      ui_web.platformViewRegistry
          .registerViewFactory(_viewId!, (int id) => video);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Could not access camera. Please check camera permissions in your browser or ensure another application is not using the camera.';
        });
      }
    }
  }

  void _switchCamera() {
    if (_videoDevices.length <= 1) return;
    _currentDeviceIndex = (_currentDeviceIndex + 1) % _videoDevices.length;
    final nextDevice = _videoDevices[_currentDeviceIndex];
    _initCamera(nextDevice.deviceId);
  }

  void _captureFrame() {
    if (_videoElement == null) return;
    final v = _videoElement!;
    final w = v.videoWidth > 0 ? v.videoWidth : 1280;
    final h = v.videoHeight > 0 ? v.videoHeight : 720;

    final canvas = html.CanvasElement(width: w, height: h);
    final ctx = canvas.context2D;
    ctx.drawImage(v, 0, 0);

    final dataUrl = canvas.toDataUrl('image/jpeg', 0.88);
    setState(() {
      _capturedDataUrl = dataUrl;
    });
  }

  void _retake() {
    setState(() {
      _capturedDataUrl = null;
    });
  }

  void _confirmPhoto() {
    _stopStream();
    Navigator.of(context).pop(_capturedDataUrl);
  }

  Future<void> _fallbackToGallery() async {
    _stopStream();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    Navigator.of(context).pop(picked?.path);
  }

  void _stopStream() {
    if (_mediaStream != null) {
      for (final track in _mediaStream!.getTracks()) {
        track.stop();
      }
      _mediaStream = null;
    }
    if (_videoElement != null) {
      _videoElement!.srcObject = null;
      _videoElement = null;
    }
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_outlined,
                        size: 18, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Capture Photo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Align in frame and take picture',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 20, color: Color(0xFF64748B)),
                    onPressed: () {
                      _stopStream();
                      Navigator.of(context).pop();
                    },
                    tooltip: 'Cancel',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Camera Viewport
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 280,
                  color: const Color(0xFF0F172A),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_isLoading)
                        const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF38BDF8)),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Starting camera…',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else if (_errorMessage != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.videocam_off_outlined,
                                    size: 42, color: Color(0xFFF87171)),
                                const SizedBox(height: 10),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_capturedDataUrl != null)
                        Image.memory(
                          base64Decode(
                              _capturedDataUrl!.split(',').last),
                          fit: BoxFit.cover,
                        )
                      else if (_viewId != null) ...[
                        HtmlElementView(viewType: _viewId!),
                        // Subtle Viewfinder Corners
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: CustomPaint(
                                painter: _ViewfinderOverlayPainter(),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Switch Camera icon if streaming and multiple cameras available
                      if (!_isLoading &&
                          _errorMessage == null &&
                          _capturedDataUrl == null &&
                          _videoDevices.length > 1)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Material(
                            color: Colors.black45,
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(Icons.flip_camera_ios,
                                  color: Colors.white, size: 20),
                              onPressed: _switchCamera,
                              tooltip: 'Switch Camera',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons Row
              if (_errorMessage != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _stopStream();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _fallbackToGallery,
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: const Text('Choose File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_capturedDataUrl != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _retake,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retake'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _confirmPhoto,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Use Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Center(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _captureFrame,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2563EB), width: 3),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x202563EB),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewfinderOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const cornerLength = 20.0;

    // Top Left
    canvas.drawLine(Offset.zero, const Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, cornerLength), paint);

    // Top Right
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom Left
    canvas.drawLine(
        Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Bottom Right
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
