import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walleto_ui/screens/recurring_payments_screen.dart';
import 'package:walleto_ui/providers/core_providers.dart';
import 'package:walleto_ui/providers/additional_providers.dart';
import 'package:walleto_ui/models/models.dart';
import 'package:walleto_ui/services/additional_services.dart';

class MockRecurringPaymentService implements RecurringPaymentService {
  int? lastCompletedId;
  bool toggleAllCalled = false;

  @override
  Future<RecurringPayment> completeRecurringPayment(int id) async {
    lastCompletedId = id;
    return RecurringPayment(id: id, name: 'Test', amount: 0, dueDay: 1);
  }

  @override
  Future<void> toggleAll(Map<String, dynamic> request) async {
    toggleAllCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildTestSetup(
    MockRecurringPaymentService mockService,
    List<RecurringPayment> payments,
  ) {
    return ProviderScope(
      overrides: [
        recurringPaymentServiceProvider.overrideWithValue(mockService),
        recurringPaymentsProvider.overrideWith((ref) => payments),
      ],
      child: const MaterialApp(home: RecurringPaymentsScreen()),
    );
  }

  testWidgets('RecurringPaymentsScreen - Empty State', (
    WidgetTester tester,
  ) async {
    final mockService = MockRecurringPaymentService();

    await tester.pumpWidget(buildTestSetup(mockService, []));
    await tester.pumpAndSettle();

    expect(find.text('No recurring payments found.'), findsOneWidget);
  });

  testWidgets('RecurringPaymentsScreen - List Rendering and Totals', (
    WidgetTester tester,
  ) async {
    final mockService = MockRecurringPaymentService();
    final now = DateTime.now();
    final expiredDate = now.subtract(const Duration(days: 10));
    final futureDate = now.add(const Duration(days: 10));

    final payments = [
      RecurringPayment(
        id: 1,
        name: 'Netflix',
        amount: 500.0,
        dueDay: 5,
        expiryDate: futureDate.toIso8601String().split('T')[0],
        isCompleted: false,
      ),
      RecurringPayment(
        id: 2,
        name: 'Gym',
        amount: 1000.0,
        dueDay: 10,
        expiryDate: expiredDate.toIso8601String().split('T')[0],
        isCompleted: true,
      ),
    ];

    await tester.pumpWidget(buildTestSetup(mockService, payments));
    await tester.pumpAndSettle();

    expect(find.text('₹1500.00'), findsOneWidget); // Total Amount
    expect(find.text('₹500.00'), findsOneWidget); // Remaining Amount
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('Expired'), findsOneWidget); // One is expired
  });

  testWidgets('RecurringPaymentsScreen - Completing Payment', (
    WidgetTester tester,
  ) async {
    final mockService = MockRecurringPaymentService();
    final payments = [
      RecurringPayment(
        id: 1,
        name: 'Netflix',
        amount: 500.0,
        dueDay: 5,
        expiryDate: '2050-01-01',
        isCompleted: false,
      ),
    ];

    await tester.pumpWidget(buildTestSetup(mockService, payments));
    await tester.pumpAndSettle();

    // Tap checkbox
    final checkbox = find.byType(Checkbox).first;
    await tester.tap(checkbox);
    await tester.pump();

    expect(mockService.lastCompletedId, 1);
  });

  testWidgets('RecurringPaymentsScreen - Toggle All', (
    WidgetTester tester,
  ) async {
    final mockService = MockRecurringPaymentService();
    final payments = [
      RecurringPayment(
        id: 1,
        name: 'Netflix',
        amount: 500.0,
        dueDay: 5,
        expiryDate: '2050-01-01',
        isCompleted: false,
      ),
    ];

    await tester.pumpWidget(buildTestSetup(mockService, payments));
    await tester.pumpAndSettle();

    // Tap toggle all action
    await tester.tap(find.byIcon(Icons.done_all));
    await tester.pump();

    expect(mockService.toggleAllCalled, true);
  });
}
