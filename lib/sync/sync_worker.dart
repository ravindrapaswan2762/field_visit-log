import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../core/constants/app_constants.dart';
import '../core/database/app_database.dart';
import '../core/network/api_client.dart';
import '../features/visits/data/datasources/visit_local_datasource.dart';
import '../features/visits/data/datasources/visit_remote_datasource.dart';
import '../features/visits/data/repositories/visit_repository_impl.dart';
import '../features/visits/domain/usecases/sync_pending_visits.dart';

/// Top-level callback required by WorkManager.
/// Must be a top-level function, not a class method.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      if (taskName == AppConstants.syncTaskName) {
        await _runSyncTask();
      }
      return Future.value(true);
    } catch (_) {
      // Return false to let WorkManager retry according to its own policy.
      return Future.value(false);
    }
  });
}

Future<void> _runSyncTask() async {
  final db = AppDatabase.instance;
  final local = VisitLocalDatasource(db: db);
  final remote = VisitRemoteDatasource(apiClient: ApiClient());
  final repo = VisitRepositoryImpl(
    localDatasource: local,
    remoteDatasource: remote,
  );

  await repo.recoverStaleSyncingVisits();
  final syncUseCase = SyncPendingVisits(repo);
  await syncUseCase();
}

/// Schedules a one-off background sync task with network constraints.
/// WorkManager may run this later than requested; do not rely on exact timing.
Future<void> scheduleBackgroundSync() async {
  if (kIsWeb) return;
  await Workmanager().registerOneOffTask(
    AppConstants.syncTaskName,
    AppConstants.syncTaskName,
    tag: AppConstants.syncTaskTag,
    existingWorkPolicy: ExistingWorkPolicy.keep,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: AppConstants.initialRetryDelay,
  );
}
