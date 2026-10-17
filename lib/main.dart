import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'app.dart';
import 'sync/sync_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise WorkManager with the background task dispatcher on mobile.
  if (!kIsWeb) {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  runApp(const FieldVisitApp());
}
