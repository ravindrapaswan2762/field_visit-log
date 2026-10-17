import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'app.dart';
import 'sync/sync_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise WorkManager with the background task dispatcher.
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false, // set true during development for verbose logging
  );

  runApp(const FieldVisitApp());
}
