import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:field_visit_log/core/database/app_database.dart';
import 'package:field_visit_log/core/database/database_migrations.dart';
import 'package:field_visit_log/core/network/connectivity_service.dart';
import 'package:field_visit_log/features/visits/data/datasources/visit_local_datasource.dart';
import 'package:field_visit_log/features/visits/data/datasources/visit_remote_datasource.dart';
import 'package:field_visit_log/features/visits/data/repositories/visit_repository_impl.dart';
import 'package:field_visit_log/features/visits/domain/usecases/create_visit.dart';
import 'package:field_visit_log/features/visits/domain/usecases/get_visit_details.dart';
import 'package:field_visit_log/features/visits/domain/usecases/get_visits.dart';
import 'package:field_visit_log/features/visits/domain/usecases/sync_pending_visits.dart';
import 'package:field_visit_log/features/visits/presentation/providers/visit_provider.dart';
import 'package:field_visit_log/features/visits/presentation/screens/visit_list_screen.dart';
import 'package:field_visit_log/routing/app_router.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}
class MockRemoteDatasource extends Mock implements VisitRemoteDatasource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase testDb;
  late VisitLocalDatasource localDatasource;
  late MockRemoteDatasource mockRemote;
  late MockConnectivityService mockConnectivity;
  late StreamController<bool> connectivityController;
  late VisitRepositoryImpl repository;
  late VisitProvider provider;

  setUp(() async {
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
    testDb = AppDatabase.instance;

    localDatasource = VisitLocalDatasource(db: testDb);
    mockRemote = MockRemoteDatasource();
    mockConnectivity = MockConnectivityService();
    connectivityController = StreamController<bool>.broadcast();

    when(() => mockConnectivity.isConnected).thenAnswer((_) async => false);
    when(() => mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => connectivityController.stream);

    repository = VisitRepositoryImpl(
      localDatasource: localDatasource,
      remoteDatasource: mockRemote,
    );

    provider = VisitProvider(
      getVisits: GetVisits(repository),
      createVisit: CreateVisit(repository),
      getVisitDetails: GetVisitDetails(repository),
      syncPendingVisits: SyncPendingVisits(repository),
      connectivityService: mockConnectivity,
    );

    await provider.init();
  });

  tearDown(() async {
    await connectivityController.close();
    await testDb.close();
  });

  Widget createTestWidget() {
    return ChangeNotifierProvider<VisitProvider>.value(
      value: provider,
      child: const MaterialApp(
        title: 'Field Visit Log',
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: VisitListScreen(),
      ),
    );
  }

  testWidgets('Full End-to-End App Flow: View list -> Add visit offline -> View details', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Initial State: App bar title and FAB
    expect(find.text('Field Visit Log'), findsOneWidget);
    expect(find.byKey(const Key('add_visit_fab')), findsOneWidget);

    // 2. Tap Floating Action Button to navigate to Add Visit screen
    await tester.tap(find.byKey(const Key('add_visit_fab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Add Visit'), findsOneWidget);

    // 3. Fill in the visit form fields
    final nameField = find.byKey(const Key('customer_name_field'));
    final notesField = find.byKey(const Key('notes_field'));

    expect(nameField, findsOneWidget);
    expect(notesField, findsOneWidget);

    await tester.enterText(nameField, 'Global Tech Industries');
    await tester.enterText(notesField, 'Discussed cloud migration strategy and timeline.');
    await tester.pump();

    // 4. Submit form
    final saveButton = find.byKey(const Key('save_visit_button'));
    expect(saveButton, findsOneWidget);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pump();
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);

    await tester.pump();
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 5. Verify back on Visit List and newly created visit card is present
    expect(find.text('Global Tech Industries'), findsOneWidget);

    // 6. Tap on the visit card to open Visit Details Screen
    await tester.tap(find.text('Global Tech Industries'));
    await tester.pump();
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 7. Verify Visit Details Screen content
    expect(find.text('Visit Details'), findsOneWidget);
    expect(find.text('Global Tech Industries'), findsOneWidget);
    expect(find.text('Discussed cloud migration strategy and timeline.'), findsOneWidget);
    expect(find.text('Pending Synchronization'), findsOneWidget);
  });
}
