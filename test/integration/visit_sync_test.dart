import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mocktail/mocktail.dart';
import 'package:field_visit_log/core/constants/app_constants.dart';
import 'package:field_visit_log/core/database/app_database.dart';
import 'package:field_visit_log/core/database/database_migrations.dart';
import 'package:field_visit_log/core/errors/app_exception.dart';
import 'package:field_visit_log/features/visits/data/datasources/visit_local_datasource.dart';
import 'package:field_visit_log/features/visits/data/datasources/visit_remote_datasource.dart';
import 'package:field_visit_log/features/visits/data/models/visit_model.dart';
import 'package:field_visit_log/features/visits/data/repositories/visit_repository_impl.dart';
import 'package:field_visit_log/features/visits/domain/usecases/create_visit.dart';
import 'package:field_visit_log/features/visits/domain/usecases/sync_pending_visits.dart';
import 'package:field_visit_log/sync/sync_status.dart';

class MockRemoteDatasource extends Mock implements VisitRemoteDatasource {}
class FakeVisitModel extends Fake implements VisitModel {}

Future<AppDatabase> _createTestDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: DatabaseMigrations.onCreate,
    ),
  );
  AppDatabase.instance.setDatabaseForTest(db);
  return AppDatabase.instance;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeVisitModel());
    registerFallbackValue(SyncStatus.pending);
  });

  group('Visit Synchronization Integration Tests', () {
    late AppDatabase testDb;
    late VisitLocalDatasource local;
    late MockRemoteDatasource mockRemote;
    late VisitRepositoryImpl repo;
    late CreateVisit createVisit;
    late SyncPendingVisits syncPendingVisits;

    setUp(() async {
      testDb = await _createTestDb();
      local = VisitLocalDatasource(db: testDb);
      mockRemote = MockRemoteDatasource();
      repo = VisitRepositoryImpl(
        localDatasource: local,
        remoteDatasource: mockRemote,
      );
      createVisit = CreateVisit(repo);
      syncPendingVisits = SyncPendingVisits(repo);
    });

    tearDown(() async {
      await testDb.close();
    });

    test('synchronizes pending visits when connectivity returns', () async {
      // Create two visits while offline
      final v1 = await createVisit(
        customerName: 'Acme Corp',
        notes: 'Offline quarterly review meeting.',
      );
      final v2 = await createVisit(
        customerName: 'Beta Industries',
        notes: 'Offline audit visit with management.',
      );

      expect(v1.syncStatus, SyncStatus.pending);
      expect(v2.syncStatus, SyncStatus.pending);

      // Simulate remote server accepting the visits
      when(() => mockRemote.uploadVisit(any())).thenAnswer((_) async => {
        'status': 'synced',
        'serverId': 'srv-12345',
      });

      // Trigger sync (as connectivity service does upon coming online)
      final syncedCount = await syncPendingVisits();
      expect(syncedCount, equals(2));

      final updatedV1 = await repo.getVisitById(v1.id);
      final updatedV2 = await repo.getVisitById(v2.id);

      expect(updatedV1?.syncStatus, SyncStatus.synced);
      expect(updatedV1?.syncedAt, isNotNull);
      expect(updatedV2?.syncStatus, SyncStatus.synced);
      expect(updatedV2?.syncedAt, isNotNull);
    });

    test('simulates network timeout and marks visit as failed with retry info', () async {
      final v = await createVisit(
        customerName: 'Gamma Logistics',
        notes: 'Network latency testing notes.',
      );

      when(() => mockRemote.uploadVisit(any()))
          .thenThrow(const NetworkException('Request timed out.'));

      await syncPendingVisits();

      final stored = await repo.getVisitById(v.id);
      expect(stored, isNotNull);
      expect(stored!.syncStatus, SyncStatus.failed);
      expect(stored.retryCount, equals(1));
      expect(stored.nextRetryAt, isNotNull);
      expect(stored.lastSyncError, contains('Request timed out'));
    });

    test('simulates 500 server error and retains visit for exponential backoff retry', () async {
      final v = await createVisit(
        customerName: 'Delta Retailers',
        notes: 'Server 500 fault injection test.',
      );

      when(() => mockRemote.uploadVisit(any()))
          .thenThrow(const ServerException('Internal Server Error', statusCode: 500));

      await syncPendingVisits();

      final stored = await repo.getVisitById(v.id);
      expect(stored, isNotNull);
      expect(stored!.syncStatus, SyncStatus.failed);
      expect(stored.retryCount, equals(1));
      expect(stored.nextRetryAt, isNotNull);
    });

    test('validation failure 422 exhausts retries immediately to prevent endless looping', () async {
      final v = await createVisit(
        customerName: 'Epsilon Tech',
        notes: 'Unprocessable entity scenario.',
      );

      when(() => mockRemote.uploadVisit(any()))
          .thenThrow(const ValidationServerException('Unprocessable entity'));

      await syncPendingVisits();

      final stored = await repo.getVisitById(v.id);
      expect(stored, isNotNull);
      expect(stored!.syncStatus, SyncStatus.failed);
      expect(stored.retryCount, equals(AppConstants.maxRetryCount));
    });

    test('repeated sync calls for duplicate request are idempotent', () async {
      final v = await createVisit(
        customerName: 'Zeta Holdings',
        notes: 'Testing idempotency preservation.',
      );

      // First sync succeeds
      when(() => mockRemote.uploadVisit(any())).thenAnswer((_) async => {
        'status': 'synced',
        'serverId': 'srv-zeta-01',
      });

      await syncPendingVisits();
      var stored = await repo.getVisitById(v.id);
      expect(stored?.syncStatus, SyncStatus.synced);

      // Re-running sync ignores already synced visits
      final secondSyncCount = await syncPendingVisits();
      expect(secondSyncCount, equals(0));

      stored = await repo.getVisitById(v.id);
      expect(stored?.syncStatus, SyncStatus.synced);
      expect(stored?.id, equals(v.id));
    });
  });
}
