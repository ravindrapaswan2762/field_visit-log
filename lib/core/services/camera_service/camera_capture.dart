import 'package:flutter/material.dart';
import 'camera_capture_stub.dart'
    if (dart.library.html) 'camera_capture_web.dart' as impl;

class WebCameraHelper {
  static Future<String?> capturePhoto(BuildContext context) {
    return impl.capturePhotoFromWeb(context);
  }
}
