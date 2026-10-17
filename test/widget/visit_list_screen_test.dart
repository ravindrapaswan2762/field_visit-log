import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:field_visit_log/features/visits/presentation/providers/visit_provider.dart';
import 'package:field_visit_log/features/visits/presentation/screens/visit_list_screen.dart';
import 'package:field_visit_log/features/visits/presentation/widgets/visit_card.dart';
import 'package:field_visit_log/features/visits/domain/entities/visit.dart';
import 'package:field_visit_log/sync/sync_status.dart';
import 'package:field_visit_log/routing/app_router.dart';

class MockVisitProvider extends Mock with ChangeNotifier implements VisitProvider {}

Widget _wrap(Widget child, VisitProvider provider) {
  return ChangeNotifierProvider<VisitProvider>.value(
    value: provider,
    child: MaterialApp(
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: child,
    ),
  );
}

void main() {
  late MockVisitProvider mockProvider;

  setUp(() {
    mockProvider = MockVisitProvider();
    when(() => mockProvider.state).thenReturn(VisitLoadState.loaded);
    when(() => mockProvider.visits).thenReturn([]);
    when(() => mockProvider.isOnline).thenReturn(true);
    when(() => mockProvider.isSyncing).thenReturn(false);
    when(() => mockProvider.isSaving).thenReturn(false);
    when(() => mockProvider.totalCount).thenReturn(0);
    when(() => mockProvider.pendingCount).thenReturn(0);
    when(() => mockProvider.syncedCount).thenReturn(0);
    when(() => mockProvider.statusFilter).thenReturn(null);
    when(() => mockProvider.init()).thenAnswer((_) async {});
    when(() => mockProvider.loadVisits()).thenAnswer((_) async {});
  });

  testWidgets('shows empty state when no visits', (tester) async {
    await tester.pumpWidget(_wrap(const VisitListScreen(), mockProvider));
    await tester.pumpAndSettle();

    expect(find.text('Field Visit Log'), findsOneWidget);
    expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
  });

  testWidgets('shows visit cards when visits exist', (tester) async {
    final visit = Visit(
      id: 'v1',
      customerName: 'Bob Smith',
      notes: 'Discussed the new product line.',
      createdAt: DateTime.utc(2026, 3, 10),
      syncStatus: SyncStatus.synced,
    );
    when(() => mockProvider.visits).thenReturn([visit]);
    when(() => mockProvider.totalCount).thenReturn(1);
    when(() => mockProvider.syncedCount).thenReturn(1);

    await tester.pumpWidget(_wrap(const VisitListScreen(), mockProvider));
    await tester.pumpAndSettle();

    expect(find.byType(VisitCard), findsOneWidget);
    expect(find.text('Bob Smith'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(VisitCard), matching: find.text('Synced')),
      findsOneWidget,
    );
  });

  testWidgets('shows offline chip when offline', (tester) async {
    when(() => mockProvider.isOnline).thenReturn(false);

    await tester.pumpWidget(_wrap(const VisitListScreen(), mockProvider));
    await tester.pumpAndSettle();

    expect(find.text('Offline'), findsOneWidget);
  });

  testWidgets('FAB is present', (tester) async {
    await tester.pumpWidget(_wrap(const VisitListScreen(), mockProvider));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add_visit_fab')), findsOneWidget);
  });
}
