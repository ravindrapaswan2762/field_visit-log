import 'package:flutter/foundation.dart';

/// Application-wide constants.
/// Never store secrets, tokens, or PII here.
class AppConstants {
  AppConstants._();

  // ── Database ──────────────────────────────────────────────────────────────
  static const String dbName = 'field_visit_log.db';
  static const int dbVersion = 1;

  // ── API ───────────────────────────────────────────────────────────────────
  // For web/desktop, mock server is accessed via localhost:3000.
  // For Android emulator, 10.0.2.2 routes to the host machine.
  static String get baseUrl => kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
  static const String visitsEndpoint = '/api/v1/visits';

  static const Duration httpTimeout = Duration(seconds: 15);
  static const String idempotencyKeyHeader = 'Idempotency-Key';

  // ── Sync ──────────────────────────────────────────────────────────────────
  static const int maxRetryCount = 5;
  static const Duration initialRetryDelay = Duration(seconds: 10);
  static const double retryBackoffMultiplier = 2.0;
  static const Duration maxRetryDelay = Duration(minutes: 30);

  // ── Validation ────────────────────────────────────────────────────────────
  static const int customerNameMinLength = 2;
  static const int customerNameMaxLength = 80;
  static const int notesMinLength = 5;
  static const int notesMaxLength = 500;

  // ── WorkManager ───────────────────────────────────────────────────────────
  static const String syncTaskName = 'field_visit_sync';
  static const String syncTaskTag = 'sync';

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const String appName = 'Field Visit Log';
}
