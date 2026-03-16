import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walleto_ui/screens/transaction_form_screen.dart';
import 'package:walleto_ui/providers/core_providers.dart';
import 'package:walleto_ui/providers/additional_providers.dart';
import 'package:walleto_ui/providers/summary_providers.dart';
import 'package:walleto_ui/models/models.dart';
import 'package:walleto_ui/services/transaction_service.dart';

class MockTransactionService implements TransactionService {
  Transaction? lastSavedTransaction;
  bool isUpdateCalled = false;
  bool isDeleteCalled = false;

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    lastSavedTransaction = transaction;
    return Transaction(
      id: 123,
      amount: transaction.amount,
      transactionType: transaction.transactionType,
      dateTime: transaction.dateTime,
      categoryId: transaction.categoryId,
      categoryName: transaction.categoryName,
      accountId: transaction.accountId,
      accountName: transaction.accountName,
      description: transaction.description,
    );
  }

  @override
  Future<Transaction> updateTransaction(int id, Transaction transaction) async {
    lastSavedTransaction = transaction;
    isUpdateCalled = true;
    return transaction;
  }

  @override
  Future<void> deleteTransaction(int id) async {
    isDeleteCalled = true;
  }

  // Needed for AttachmentsSection
  @override
  Future<List<TransactionAttachment>> getAttachments(int id) async {
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final testAccounts = [
    Account(id: 1, name: 'Test Bank', currency: 'INR', isDefault: true),
  ];
  final testCategories = [
    Category(id: 10, name: 'Food', type: CategoryType.expense),
    Category(id: 11, name: 'Salary', type: CategoryType.income),
  ];
  final testRecurring = <RecurringPayment>[
    RecurringPayment(id: 100, name: 'Netflix', amount: 800, dueDay: 1),
  ];

  Widget buildTestSetup(
    MockTransactionService mockService, {
    Transaction? existingTransaction,
  }) {
    return ProviderScope(
      overrides: [
        accountsProvider.overrideWith((ref) => testAccounts),
        categoriesProvider.overrideWith((ref) => testCategories),
        recurringPaymentsProvider.overrideWith((ref) => testRecurring),
        transactionServiceProvider.overrideWithValue(mockService),
        netBalanceProvider.overrideWith((ref) => 1000.0),
      ],
      child: MaterialApp(
        home: TransactionFormScreen(existingTransaction: existingTransaction),
      ),
    );
  }

  testWidgets('Transaction Creation Flow - Success (Expense)', (
    WidgetTester tester,
  ) async {
    final mockService = MockTransactionService();

    await tester.pumpWidget(buildTestSetup(mockService));
    await tester.pumpAndSettle();

    expect(find.text('Add Transaction'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '250.50');
    await tester.enterText(find.byType(TextFormField).at(1), 'Lunch');

    final saveButton = find.text('SAVE TRANSACTION');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(mockService.lastSavedTransaction, isNotNull);
    final tx = mockService.lastSavedTransaction!;
    expect(tx.amount, 250.5);
    expect(tx.description, 'Lunch');
    expect(tx.transactionType, TransactionType.debit);
    expect(tx.categoryId, 10);
  });

  testWidgets('Transaction Creation Flow - Validation Failure (Empty Amount)', (
    WidgetTester tester,
  ) async {
    final mockService = MockTransactionService();

    await tester.pumpWidget(buildTestSetup(mockService));
    await tester.pumpAndSettle();

    final saveButton = find.text('SAVE TRANSACTION');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);

    await tester.pumpAndSettle();

    // Requires an amount
    expect(find.text('Required'), findsWidgets);
    expect(mockService.lastSavedTransaction, isNull);
  });

  testWidgets('Transaction Creation Flow - Income (Credit)', (
    WidgetTester tester,
  ) async {
    final mockService = MockTransactionService();

    await tester.pumpWidget(buildTestSetup(mockService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Credit/Income'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '5000');
    await tester.enterText(find.byType(TextFormField).at(1), 'Salary Credit');

    final saveButton = find.text('SAVE TRANSACTION');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(mockService.lastSavedTransaction, isNotNull);
    final tx = mockService.lastSavedTransaction!;
    expect(tx.amount, 5000);
    expect(tx.description, 'Salary Credit');
    expect(tx.transactionType, TransactionType.credit);
    expect(tx.categoryId, 11);
  });

  testWidgets('Transaction Edit Flow - Success', (WidgetTester tester) async {
    final mockService = MockTransactionService();
    final existingTx = Transaction(
      id: 99,
      amount: 100.0,
      transactionType: TransactionType.debit,
      dateTime: DateTime(2024, 1, 1),
      categoryId: 10,
      accountId: 1,
      description: 'Old description',
    );

    await tester.pumpWidget(
      buildTestSetup(mockService, existingTransaction: existingTx),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Transaction'), findsOneWidget);

    // Existing values
    expect(find.text('Old description'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '150.0');

    final saveButton = find.text('SAVE TRANSACTION');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(mockService.isUpdateCalled, isTrue);
    expect(mockService.lastSavedTransaction, isNotNull);
    final tx = mockService.lastSavedTransaction!;
    expect(tx.id, 99);
    expect(tx.amount, 150.0);
    expect(tx.description, 'Old description');
    expect(tx.transactionType, TransactionType.debit);
  });

  testWidgets('Transaction Delete Flow - Cancel', (WidgetTester tester) async {
    final mockService = MockTransactionService();
    final existingTx = Transaction(
      id: 99,
      amount: 100.0,
      transactionType: TransactionType.debit,
      dateTime: DateTime(2024, 1, 1),
      categoryId: 10,
      accountId: 1,
      description: 'Old description',
    );

    await tester.pumpWidget(
      buildTestSetup(mockService, existingTransaction: existingTx),
    );
    await tester.pumpAndSettle();

    final deleteIcon = find.byIcon(Icons.delete_outline);
    expect(deleteIcon, findsOneWidget);
    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    expect(find.text('Delete Transaction'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Transaction'), findsOneWidget);
    expect(mockService.isDeleteCalled, isFalse);
  });

  testWidgets('Transaction Delete Flow - Confirm', (WidgetTester tester) async {
    final mockService = MockTransactionService();
    final existingTx = Transaction(
      id: 99,
      amount: 100.0,
      transactionType: TransactionType.debit,
      dateTime: DateTime(2024, 1, 1),
      categoryId: 10,
      accountId: 1,
      description: 'Old description',
    );

    await tester.pumpWidget(
      buildTestSetup(mockService, existingTransaction: existingTx),
    );
    await tester.pumpAndSettle();

    final deleteIcon = find.byIcon(Icons.delete_outline);
    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    expect(find.text('Delete Transaction'), findsOneWidget);

    final deleteButton = find.widgetWithText(TextButton, 'Delete');
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(mockService.isDeleteCalled, isTrue);
  });

  testWidgets('Transaction Edit Flow - Change Type (Debit -> Credit)', (
    WidgetTester tester,
  ) async {
    final mockService = MockTransactionService();
    final existingTx = Transaction(
      id: 99,
      amount: 100.0,
      transactionType: TransactionType.debit,
      dateTime: DateTime(2024, 1, 1),
      categoryId: 10,
      accountId: 1,
      description: 'Old description',
    );

    await tester.pumpWidget(
      buildTestSetup(mockService, existingTransaction: existingTx),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Transaction'), findsOneWidget);

    // Swap to Credit
    await tester.tap(find.text('Credit/Income'));
    await tester.pumpAndSettle();

    final saveButton = find.text('SAVE TRANSACTION');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(mockService.isUpdateCalled, isTrue);
    expect(mockService.lastSavedTransaction, isNotNull);
    final tx = mockService.lastSavedTransaction!;
    expect(tx.id, 99);
    expect(tx.transactionType, TransactionType.credit);
    // category will switch to default income category since type changed
    expect(tx.categoryId, 11);
  });

  testWidgets('Transaction Edit Flow - Toggle Exclude from Summary', (
    WidgetTester tester,
  ) async {
    final mockService = MockTransactionService();
    final existingTx = Transaction(
      id: 99,
      amount: 100.0,
      transactionType: TransactionType.debit,
      dateTime: DateTime(2024, 1, 1),
      categoryId: 10,
      accountId: 1,
      description: 'Old description',
      excludeFromSummary: false,
    );

    await tester.pumpWidget(
      buildTestSetup(mockService, existingTransaction: existingTx),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Transaction'), findsOneWidget);

    final switchTileFinder = find.widgetWithText(
      SwitchListTile,
      'Exclude from Summary',
    );
    await tester.ensureVisible(switchTileFinder);
    await tester.tap(switchTileFinder);
    await tester.pumpAndSettle();

    final saveButton = find.text('SAVE TRANSACTION');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(mockService.isUpdateCalled, isTrue);
    expect(mockService.lastSavedTransaction, isNotNull);
    final tx = mockService.lastSavedTransaction!;
    expect(tx.id, 99);
    expect(tx.excludeFromSummary, isTrue);
  });
}
