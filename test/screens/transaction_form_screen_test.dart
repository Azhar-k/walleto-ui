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
  Transaction? createdTransaction;

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    createdTransaction = transaction;
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Transaction Creation Flow - Success', (
    WidgetTester tester,
  ) async {
    final mockService = MockTransactionService();

    final testAccounts = [
      Account(id: 1, name: 'Test Bank', currency: 'INR', isDefault: true),
    ];
    final testCategories = [
      Category(id: 10, name: 'Food', type: CategoryType.expense),
      Category(id: 11, name: 'Salary', type: CategoryType.income),
    ];
    final testRecurring = <RecurringPayment>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsProvider.overrideWith((ref) => testAccounts),
          categoriesProvider.overrideWith((ref) => testCategories),
          recurringPaymentsProvider.overrideWith((ref) => testRecurring),
          transactionServiceProvider.overrideWithValue(mockService),
          netBalanceProvider.overrideWith((ref) => 1000.0),
        ],
        child: const MaterialApp(home: TransactionFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Add Transaction'), findsOneWidget);
    expect(find.text('SAVE TRANSACTION'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '250.50');

    await tester.enterText(find.byType(TextFormField).at(1), 'Lunch');

    final saveButton = find.text('SAVE TRANSACTION');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    if (mockService.createdTransaction == null) {
      final requiredErrors = find.text('Required');
      print(
        'Validation failed? Required count: ${requiredErrors.evaluate().length}',
      );
    }

    expect(mockService.createdTransaction, isNotNull);
    final tx = mockService.createdTransaction!;
    expect(tx.amount, 250.5);
    expect(tx.description, 'Lunch');
    expect(tx.accountId, 1);
    expect(tx.categoryId, 10);
    expect(tx.transactionType, TransactionType.debit);
  });
}
