import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scp_operations/main.dart';

void main() {
  testWidgets('opens the work board and a record detail page', (tester) async {
    await tester.pumpWidget(
      OperationsApp(controller: OperationsController.seeded()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();

    expect(find.text('Maintenance requests'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cold storage inspection'),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Cold storage inspection'), findsOneWidget);

    await tester.tap(find.text('Cold storage inspection'));
    await tester.pumpAndSettle();

    expect(find.text('Medical fridge CF-14'), findsOneWidget);
    expect(find.text('Update status'), findsOneWidget);
  });

  testWidgets('creates a local operation record', (tester) async {
    await tester.pumpWidget(
      OperationsApp(controller: OperationsController.seeded(records: const [])),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add operation record'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('titleField')),
      'Prepare route allocation',
    );
    await tester.enterText(
      find.byKey(const ValueKey('ownerField')),
      'Operations desk',
    );
    await tester.enterText(
      find.byKey(const ValueKey('assetField')),
      'Vehicle 04',
    );
    await tester.enterText(
      find.byKey(const ValueKey('locationField')),
      'East route',
    );
    final saveButton = find.widgetWithText(FilledButton, 'Save record');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Prepare route allocation'), findsOneWidget);
    expect(find.text('Vehicle 04 - East route'), findsOneWidget);
  });
}
