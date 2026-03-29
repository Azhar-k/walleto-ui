import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walleto_ui/screens/account_details_screen.dart';
import 'package:walleto_ui/providers/core_providers.dart';
import 'package:walleto_ui/providers/summary_providers.dart';
import 'package:walleto_ui/models/models.dart';
import 'package:walleto_ui/services/transaction_service.dart';
import 'package:go_router/go_router.dart';

class MockTransactionService implements TransactionService {
  List<Transaction> transactionsToReturn = [];

  @override
  Future<List<Transaction>> searchTransactions(
    Map<String, dynamic> criteria,
  ) async {
    return transactionsToReturn;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final testAccount = Account(
    id: 1,
    name: 'Default Bank',
    currency: 'INR',
    isDefault: true,
    bank: 'HDFC',
    accountNumber: '1234',
  );

  Widget buildTestSetup({
    required MockTransactionService mockTxService,
    GoRouter? router,
  }) {
    final overrides = <Override>[
      accountsProvider.overrideWith((ref) => [testAccount]),
      accountBalanceProvider(1).overrideWith((ref) => 4000.0),
      transactionServiceProvider.overrideWithValue(mockTxService),
    ];

    if (router != null) {
      return ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(routerConfig: router),
      );
    }

    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: AccountDetailsScreen(accountId: 1)),
    );
  }

  testWidgets('AccountDetailsScreen - Display Header and Balance', (
    WidgetTester tester,
  ) async {
    final mockService = MockTransactionService();
    await tester.pumpWidget(buildTestSetup(mockTxService: mockService));
    await tester.pumpAndSettle();

    expect(find.text('Default Bank'), findsWidgets); // App bar and Body
    expect(find.text('HDFC'), findsOneWidget);
    expect(find.text('•••• 1234'), findsOneWidget);
    expect(find.text('INR 4000.00'), findsOneWidget);
  });

  testWidgets('AccountDetailsScreen - Transaction List Loading and Display', (
    WidgetTester tester,
  ) async {
    final mockService = MockTransactionService();
    mockService.transactionsToReturn = [
      Transaction(
        id: 1,
        amount: 50.0,
        transactionType: TransactionType.debit,
        dateTime: DateTime.now(),
        categoryId: 10,
        categoryName: 'Food',
        accountId: 1,
        description: 'Pizza',
      ),
    ];

    await tester.pumpWidget(buildTestSetup(mockTxService: mockService));
    await tester.pumpAndSettle();

    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Pizza'), findsOneWidget);
    expect(find.text('- INR 50.00'), findsOneWidget);
  });

  testWidgets('AccountDetailsScreen - Empty Transactions State', (
    WidgetTester tester,
  ) async {
    final mockService = MockTransactionService();
    mockService.transactionsToReturn = [];

    await tester.pumpWidget(buildTestSetup(mockTxService: mockService));
    await tester.pumpAndSettle();

    expect(find.text('No transactions in this period'), findsOneWidget);
  });

  testWidgets('AccountDetailsScreen - Date Range Picker', (
    WidgetTester tester,
  ) async {
    final mockService = MockTransactionService();
    await tester.pumpWidget(buildTestSetup(mockTxService: mockService));
    await tester.pumpAndSettle();

    final dateRangeButton = find.byIcon(Icons.calendar_today);
    expect(dateRangeButton, findsOneWidget);

    await tester.tap(dateRangeButton);
    await tester.pumpAndSettle();

    // Verify Date Range Picker open (e.g. Save button exists)
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('AccountDetailsScreen - Navigation to Edit Account', (
    WidgetTester tester,
  ) async {
    final mockService = MockTransactionService();
    final router = GoRouter(
      initialLocation: '/accounts/1',
      routes: [
        GoRoute(
          path: '/accounts/1',
          builder: (context, state) => const AccountDetailsScreen(accountId: 1),
        ),
        GoRoute(
          path: '/accounts/edit',
          builder: (context, state) =>
              const Scaffold(body: Text('Edit Account')),
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestSetup(mockTxService: mockService, router: router),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    // Verify navigation by checking if the Edit Account scaffold is in the tree
    expect(find.text('Edit Account'), findsOneWidget);
  });
}
