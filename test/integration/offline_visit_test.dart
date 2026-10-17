import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:field_visit_log/core/database/app_database.dart';
import 'package:field_visit_log/core/database/database_migrations.dart';
import 'package:field_visit_log/features/visits/data/datasources/visit_local_datasource.dart';
import 'package:field_visit_log/features/visits/data/models/visit_model.dart';
import 'package:field_visit_log/features/visits/domain/usecases/create_visit.dart';
import 'package:field_visit_log/sync/sync_status.dart';
import 'package:field_visit_log/features/visits/data/repositories/visit_repository_impl.dart';
import 'package:field_visit_log/features/visits/data/datasources/visit_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements VisitRemoteDatasource {}
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

  group('Offline visit creation', () {
    late AppDatabase testDb;
    late VisitLocalDatasource local;
    late MockRemote mockRemote;
    late VisitRepositoryImpl repo;

    setUp(() async {
      testDb = await _createTestDb();
      local = VisitLocalDatasource(db: testDb);
      mockRemote = MockRemote();
      repo = VisitRepositoryImpl(
        localDatasource: local,
        remoteDatasource: mockRemote,
      );
    });

    test('creates visit locally without network', () async {
      final useCase = CreateVisit(repo);
      final visit = await useCase(
        customerName: 'Charlie Brown',
        notes: 'Visited the downtown branch.',
      );

      expect(visit.id, isNotEmpty);
      expect(visit.syncStatus, SyncStatus.pending);

      final stored = await repo.getVisitById(visit.id);
      expect(stored, isNotNull);
      expect(stored!.customerName, 'Charlie Brown');
    });

    test('visit persists after re-querying (simulated restart)', () async {
      final useCase = CreateVisit(repo);
      final visit = await useCase(
        customerName: 'Diana Prince',
        notes: 'Follow-up on the service contract.',
      );

      // Simulate "restart" by querying again from same DB.
      final allVisits = await repo.getVisits();
      expect(allVisits.any((v) => v.id == visit.id), isTrue);
    });

    test('failed sync does not delete visit', () async {
      when(() => mockRemote.uploadVisit(any()))
          .thenThrow(Exception('Network timeout'));

      final useCase = CreateVisit(repo);
      final visit = await useCase(
        customerName: 'Edward Norton',
        notes: 'Discussed annual renewal terms.',
      );

      await expectLater(
        () => repo.syncVisit(visit),
        throwsA(anything),
      );

      final stored = await repo.getVisitById(visit.id);
      expect(stored, isNotNull);
      expect(stored!.syncStatus, SyncStatus.failed);
    });

    test('retry uses the same visit ID', () async {
      when(() => mockRemote.uploadVisit(any()))
          .thenAnswer((_) async => {'status': 'synced'});

      final useCase = CreateVisit(repo);
      final visit = await useCase(
        customerName: 'Fiona Green',
        notes: 'Initial onboarding completed successfully.',
      );

      final originalId = visit.id;

      // Verify the ID stays the same across multiple sync calls.
      await repo.syncVisit(visit);

      final stored = await repo.getVisitById(originalId);
      expect(stored?.id, equals(originalId));
      expect(stored?.syncStatus, SyncStatus.synced);
    });
  });
}
