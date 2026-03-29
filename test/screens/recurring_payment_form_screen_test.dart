import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walleto_ui/screens/recurring_payment_form_screen.dart';
import 'package:walleto_ui/providers/core_providers.dart';
import 'package:walleto_ui/providers/additional_providers.dart';
import 'package:walleto_ui/models/models.dart';
import 'package:walleto_ui/services/additional_services.dart';

class MockRecurringPaymentService implements RecurringPaymentService {
  RecurringPayment? lastCreated;
  RecurringPayment? lastUpdated;
  bool throwError = false;

  @override
  Future<RecurringPayment> createRecurringPayment(
    RecurringPayment payment,
  ) async {
    lastCreated = payment;
    if (throwError) throw Exception('API Error');
    return payment;
  }

  @override
  Future<RecurringPayment> updateRecurringPayment(
    int id,
    RecurringPayment payment,
  ) async {
    lastUpdated = payment;
    if (throwError) throw Exception('API Error');
    return payment;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildTestSetup(
    MockRecurringPaymentService mockService, {
    RecurringPayment? existingPayment,
  }) {
    return ProviderScope(
      overrides: [
        recurringPaymentServiceProvider.overrideWithValue(mockService),
        recurringPaymentsProvider.overrideWith((ref) => <RecurringPayment>[]),
      ],
      child: MaterialApp(
        home: RecurringPaymentFormScreen(existingPayment: existingPayment),
      ),
    );
  }

  testWidgets('RecurringPaymentFormScreen - Validation', (
    WidgetTester tester,
  ) async {
    final mockService = MockRecurringPaymentService();

    await tester.pumpWidget(buildTestSetup(mockService));

    await tester.tap(find.text('SAVE PAYMENT'));
    await tester.pump();

    expect(find.text('Required'), findsNWidgets(3)); // name, amount, due day

    // Enter invalid number for amount and due day
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Name');
    await tester.enterText(fields.at(1), 'abc'); // amount
    await tester.enterText(fields.at(2), '32'); // due day > 31

    await tester.tap(find.text('SAVE PAYMENT'));
    await tester.pump();

    expect(find.text('Must be a valid number'), findsOneWidget);
    expect(find.text('Must be a valid day (1-31)'), findsOneWidget);
  });

  testWidgets('RecurringPaymentFormScreen - Create Successfully', (
    WidgetTester tester,
  ) async {
    final mockService = MockRecurringPaymentService();

    await tester.pumpWidget(buildTestSetup(mockService));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Rent');
    await tester.enterText(fields.at(1), '15000');
    await tester.enterText(fields.at(2), '1');

    // Select Expiry Date
    await tester.tap(find.text('Expiry Date *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // select default date (which is +1 year)
    await tester.pumpAndSettle();

    await tester.tap(find.text('SAVE PAYMENT'));
    await tester.pump();

    expect(mockService.lastCreated, isNotNull);
    expect(mockService.lastCreated!.name, 'Rent');
    expect(mockService.lastCreated!.amount, 15000.0);
    expect(mockService.lastCreated!.dueDay, 1);
  });

  testWidgets('RecurringPaymentFormScreen - Error Handling', (
    WidgetTester tester,
  ) async {
    final mockService = MockRecurringPaymentService()..throwError = true;

    await tester.pumpWidget(buildTestSetup(mockService));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Rent');
    await tester.enterText(fields.at(1), '15000');
    await tester.enterText(fields.at(2), '1');

    await tester.tap(find.text('Expiry Date *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SAVE PAYMENT'));
    await tester.pump();

    expect(find.textContaining('Failed to save payment'), findsOneWidget);
  });
}
