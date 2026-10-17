import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:field_visit_log/features/visits/presentation/providers/visit_provider.dart';
import 'package:field_visit_log/features/visits/presentation/screens/add_visit_screen.dart';

class MockVisitProvider extends Mock with ChangeNotifier implements VisitProvider {}

Widget _wrap(VisitProvider provider) {
  return ChangeNotifierProvider<VisitProvider>.value(
    value: provider,
    child: const MaterialApp(home: AddVisitScreen()),
  );
}

void main() {
  late MockVisitProvider mockProvider;

  setUp(() {
    mockProvider = MockVisitProvider();
    when(() => mockProvider.isSaving).thenReturn(false);
  });

  testWidgets('shows validation errors on empty submit', (tester) async {
    await tester.pumpWidget(_wrap(mockProvider));
    await tester.pump();

    await tester.tap(find.byKey(const Key('save_visit_button')));
    await tester.pump();

    expect(find.text('Customer name is required.'), findsOneWidget);
    expect(find.text('Visit notes are required.'), findsOneWidget);
  });

  testWidgets('shows validation error when name is too short', (tester) async {
    await tester.pumpWidget(_wrap(mockProvider));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('customer_name_field')), 'A');
    await tester.tap(find.byKey(const Key('save_visit_button')));
    await tester.pump();

    expect(
      find.textContaining('at least 2 characters'),
      findsOneWidget,
    );
  });

  testWidgets('calls addVisit on valid form submission', (tester) async {
    when(() => mockProvider.addVisit(
          customerName: any(named: 'customerName'),
          notes: any(named: 'notes'),
          photoPath: any(named: 'photoPath'),
        )).thenAnswer((_) async => true);

    await tester.pumpWidget(_wrap(mockProvider));
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('customer_name_field')),
      'Jane Doe',
    );
    await tester.enterText(
      find.byKey(const Key('notes_field')),
      'Visited the main office and reviewed contract terms.',
    );
    await tester.tap(find.byKey(const Key('save_visit_button')));
    await tester.pump();

    verify(() => mockProvider.addVisit(
          customerName: 'Jane Doe',
          notes: 'Visited the main office and reviewed contract terms.',
          photoPath: any(named: 'photoPath'),
        )).called(1);
  });
}
