import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walleto_ui/screens/transactions_screen.dart';
import 'package:walleto_ui/providers/core_providers.dart';
import 'package:walleto_ui/providers/additional_providers.dart';
import 'package:walleto_ui/models/models.dart';
import 'package:walleto_ui/services/transaction_service.dart';

class MockTransactionService implements TransactionService {
  Map<String, dynamic>? lastCriteria;
  List<Transaction> transactionsToReturn = [];
  bool throwError = false;

  @override
  Future<List<Transaction>> searchTransactions(
    Map<String, dynamic> criteria,
  ) async {
    lastCriteria = criteria;
    if (throwError) {
      throw Exception('Search failed');
    }
    return transactionsToReturn;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final testAccounts = [
    Account(id: 1, name: 'Default Bank', currency: 'INR', isDefault: true),
    Account(id: 2, name: 'Wallet', currency: 'INR', isDefault: false),
  ];
  final testCategories = [
    Category(id: 10, name: 'Food', type: CategoryType.expense),
  ];
  final testRecurring = <RecurringPayment>[];

  Widget buildTestSetup(
    MockTransactionService mockService, {
    Map<String, dynamic>? initialFilters,
  }) {
    return ProviderScope(
      overrides: [
        accountsProvider.overrideWith((ref) => testAccounts),
        categoriesProvider.overrideWith((ref) => testCategories),
        recurringPaymentsProvider.overrideWith((ref) => testRecurring),
        transactionServiceProvider.overrideWithValue(mockService),
      ],
      child: MaterialApp(
        home: TransactionsScreen(initialFilters: initialFilters),
      ),
    );
  }

  testWidgets('TransactionsScreen - Default Retrieval and Display', (
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
        accountName: 'Default Bank',
        description: 'Pizza',
      ),
    ];

    await tester.pumpWidget(buildTestSetup(mockService));

    // Wait for the initial load and API calls
    await tester.pumpAndSettle();

    // Verify UI components
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Pizza'), findsOneWidget);
    expect(
      find.text('Default Bank'),
      findsWidgets,
    ); // Both in filter chip and list item

    // Verify search was called with default criteria (including default 'accountId' if behavior dictacts)
    expect(mockService.lastCriteria, isNotNull);
    expect(mockService.lastCriteria!.containsKey('fromDate'), isTrue);
    expect(mockService.lastCriteria!.containsKey('toDate'), isTrue);
  });

  testWidgets('TransactionsScreen - Empty State', (WidgetTester tester) async {
    final mockService = MockTransactionService();
    mockService.transactionsToReturn = [];

    await tester.pumpWidget(buildTestSetup(mockService));
    await tester.pumpAndSettle();

    expect(find.text('No transactions found.'), findsOneWidget);
    expect(
      find.text('Try changing the filters or date range.'),
      findsOneWidget,
    );
  });

  testWidgets('TransactionsScreen - Error State and Retry', (
    WidgetTester tester,
  ) async {
    final mockService = MockTransactionService();
    mockService.throwError = true;

    await tester.pumpWidget(buildTestSetup(mockService));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Error: Exception: Search failed'),
      findsOneWidget,
    );
    final retryButton = find.text('Retry');
    expect(retryButton, findsOneWidget);

    // Now make it succeed
    mockService.throwError = false;
    mockService.transactionsToReturn = [
      Transaction(
        id: 2,
        amount: 200.0,
        transactionType: TransactionType.credit,
        dateTime: DateTime.now(),
        categoryId: 11,
        categoryName: 'Salary',
        accountId: 1,
        accountName: 'Default Bank',
        description: 'Bonus',
      ),
    ];

    await tester.tap(retryButton);
    await tester.pumpAndSettle();

    expect(find.text('Bonus'), findsOneWidget);
  });

  testWidgets('TransactionsScreen - Apply Filters', (
    WidgetTester tester,
  ) async {
    final mockService = MockTransactionService();
    mockService.transactionsToReturn = [];

    await tester.pumpWidget(buildTestSetup(mockService));
    await tester.pumpAndSettle();

    // Open filter sheet
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    expect(find.text('Filters'), findsOneWidget);

    // Enter search text
    await tester.enterText(find.byType(TextField).first, 'Coffee');

    // Tap apply
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();

    expect(mockService.lastCriteria, isNotNull);
    expect(mockService.lastCriteria!['search'], 'Coffee');
  });

  testWidgets('TransactionsScreen - Account Chip Filtering', (
    WidgetTester tester,
  ) async {
    final mockService = MockTransactionService();
    mockService.transactionsToReturn = [];

    await tester.pumpWidget(buildTestSetup(mockService));
    await tester.pumpAndSettle();

    // By default, if the logic preselects nothing or 'All', accountId might be missing/null.
    // If it preselects, it will be the default account. We tap the 'Wallet' chip (accountId: 2).
    await tester.tap(find.text('Wallet'));
    await tester.pumpAndSettle();

    expect(mockService.lastCriteria, isNotNull);
    expect(mockService.lastCriteria!['accountId'], 2);

    // Tap 'All' chip
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(mockService.lastCriteria!['accountId'], isNull);
  });
}
