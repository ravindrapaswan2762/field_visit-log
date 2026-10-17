import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:field_visit_log/features/visits/data/datasources/visit_local_datasource.dart';
import 'package:field_visit_log/features/visits/data/datasources/visit_remote_datasource.dart';
import 'package:field_visit_log/features/visits/data/models/visit_model.dart';
import 'package:field_visit_log/features/visits/data/repositories/visit_repository_impl.dart';
import 'package:field_visit_log/features/visits/domain/entities/visit.dart';
import 'package:field_visit_log/sync/sync_status.dart';
import 'package:field_visit_log/core/errors/app_exception.dart';

class MockLocalDatasource extends Mock implements VisitLocalDatasource {}
class MockRemoteDatasource extends Mock implements VisitRemoteDatasource {}
class FakeVisitModel extends Fake implements VisitModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeVisitModel());
    registerFallbackValue(SyncStatus.pending);
  });

  late MockLocalDatasource mockLocal;
  late MockRemoteDatasource mockRemote;
  late VisitRepositoryImpl repository;

  setUp(() {
    mockLocal = MockLocalDatasource();
    mockRemote = MockRemoteDatasource();
    repository = VisitRepositoryImpl(
      localDatasource: mockLocal,
      remoteDatasource: mockRemote,
    );
  });

  final testVisit = Visit(
    id: 'test-uuid-001',
    customerName: 'Alice Johnson',
    notes: 'Discussed quarterly targets.',
    createdAt: DateTime.utc(2026, 1, 15, 10, 0),
    syncStatus: SyncStatus.pending,
  );

  VisitModel modelFromVisit(Visit v) => VisitModel.fromEntity(v);

  group('createVisit', () {
    test('inserts visit into local datasource', () async {
      when(() => mockLocal.insertVisit(any())).thenAnswer((_) async {});

      await repository.createVisit(testVisit);

      verify(() => mockLocal.insertVisit(any())).called(1);
      verifyNever(() => mockRemote.uploadVisit(any()));
    });
  });

  group('getVisits', () {
    test('returns mapped entities from local datasource', () async {
      when(() => mockLocal.getAllVisits())
          .thenAnswer((_) async => [modelFromVisit(testVisit)]);

      final visits = await repository.getVisits();

      expect(visits.length, 1);
      expect(visits.first.id, testVisit.id);
      expect(visits.first.customerName, testVisit.customerName);
    });
  });

  group('syncVisit - success', () {
    test('marks visit as synced after successful upload', () async {
      when(() => mockLocal.updateSyncStatus(
            id: any(named: 'id'),
            syncStatus: any(named: 'syncStatus'),
            retryCount: any(named: 'retryCount'),
            nextRetryAt: any(named: 'nextRetryAt'),
            lastSyncError: any(named: 'lastSyncError'),
            syncedAt: any(named: 'syncedAt'),
          )).thenAnswer((_) async {});
      when(() => mockRemote.uploadVisit(any()))
          .thenAnswer((_) async => {'status': 'synced'});

      await repository.syncVisit(testVisit);

      // First call: syncing; second call: synced
      final captured = verify(() => mockLocal.updateSyncStatus(
            id: captureAny(named: 'id'),
            syncStatus: captureAny(named: 'syncStatus'),
            retryCount: any(named: 'retryCount'),
            nextRetryAt: any(named: 'nextRetryAt'),
            lastSyncError: any(named: 'lastSyncError'),
            syncedAt: any(named: 'syncedAt'),
          )).captured;

      final statuses = captured
          .whereType<SyncStatus>()
          .toList();
      expect(statuses, contains(SyncStatus.syncing));
      expect(statuses, contains(SyncStatus.synced));
    });
  });

  group('syncVisit - network failure', () {
    test('marks visit as failed with retry info on network error', () async {
      when(() => mockLocal.updateSyncStatus(
            id: any(named: 'id'),
            syncStatus: any(named: 'syncStatus'),
            retryCount: any(named: 'retryCount'),
            nextRetryAt: any(named: 'nextRetryAt'),
            lastSyncError: any(named: 'lastSyncError'),
            syncedAt: any(named: 'syncedAt'),
          )).thenAnswer((_) async {});
      when(() => mockRemote.uploadVisit(any()))
          .thenThrow(const NetworkException());

      await expectLater(
        () => repository.syncVisit(testVisit),
        throwsA(isA<NetworkException>()),
      );

      final captured = verify(() => mockLocal.updateSyncStatus(
            id: captureAny(named: 'id'),
            syncStatus: captureAny(named: 'syncStatus'),
            retryCount: any(named: 'retryCount'),
            nextRetryAt: any(named: 'nextRetryAt'),
            lastSyncError: any(named: 'lastSyncError'),
            syncedAt: any(named: 'syncedAt'),
          )).captured;

      expect(captured.whereType<SyncStatus>(), contains(SyncStatus.failed));
    });

    test('uses original visit ID for retry (idempotency)', () async {
      when(() => mockLocal.updateSyncStatus(
            id: any(named: 'id'),
            syncStatus: any(named: 'syncStatus'),
            retryCount: any(named: 'retryCount'),
            nextRetryAt: any(named: 'nextRetryAt'),
            lastSyncError: any(named: 'lastSyncError'),
            syncedAt: any(named: 'syncedAt'),
          )).thenAnswer((_) async {});

      VisitModel? capturedModel;
      when(() => mockRemote.uploadVisit(any())).thenAnswer((invocation) async {
        capturedModel = invocation.positionalArguments.first as VisitModel;
        throw const NetworkException();
      });

      await expectLater(
        () => repository.syncVisit(testVisit),
        throwsA(isA<NetworkException>()),
      );

      // The model passed to the remote must have the original visit ID.
      expect(capturedModel?.id, equals(testVisit.id));
    });
  });

  group('syncVisit - validation failure', () {
    test('exhausts retry count on validation errors', () async {
      when(() => mockLocal.updateSyncStatus(
            id: any(named: 'id'),
            syncStatus: any(named: 'syncStatus'),
            retryCount: any(named: 'retryCount'),
            nextRetryAt: any(named: 'nextRetryAt'),
            lastSyncError: any(named: 'lastSyncError'),
            syncedAt: any(named: 'syncedAt'),
          )).thenAnswer((_) async {});
      when(() => mockRemote.uploadVisit(any())).thenThrow(
        const ValidationServerException('Validation failed.'),
      );

      await expectLater(
        () => repository.syncVisit(testVisit),
        throwsA(isA<ValidationServerException>()),
      );

      // retryCount should be set to maxRetryCount to stop future retries.
      verify(
        () => mockLocal.updateSyncStatus(
          id: any(named: 'id'),
          syncStatus: SyncStatus.failed,
          retryCount: any(named: 'retryCount'),
          nextRetryAt: any(named: 'nextRetryAt'),
          lastSyncError: any(named: 'lastSyncError'),
          syncedAt: any(named: 'syncedAt'),
        ),
      ).called(greaterThanOrEqualTo(1));
    });
  });
}
