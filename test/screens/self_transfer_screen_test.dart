import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walleto_ui/screens/self_transfer_screen.dart';
import 'package:walleto_ui/providers/core_providers.dart';
import 'package:walleto_ui/models/models.dart';
import 'package:walleto_ui/services/additional_services.dart';
import 'package:walleto_ui/services/transaction_service.dart';

class MockTransactionService implements TransactionService {
  @override
  Future<List<Transaction>> searchTransactions(
    Map<String, dynamic> criteria,
  ) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTransferService implements TransferService {
  Map<String, dynamic>? lastTransferReq;
  bool throwError = false;

  @override
  Future<void> transferFunds(Map<String, dynamic> request) async {
    lastTransferReq = request;
    if (throwError) throw Exception('API Error');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final accounts = [
    Account(id: 1, name: 'Bank 1', currency: 'INR', isDefault: true),
    Account(id: 2, name: 'Bank 2', currency: 'INR', isDefault: false),
  ];
  final categories = [
    Category(id: 1, name: 'Transfer Category', type: CategoryType.expense),
  ];

  Widget buildTestSetup(MockTransferService mockService) {
    return ProviderScope(
      overrides: [
        accountsProvider.overrideWith((ref) => accounts),
        categoriesProvider.overrideWith((ref) => categories),
        transferServiceProvider.overrideWithValue(mockService),
        transactionServiceProvider.overrideWithValue(MockTransactionService()),
      ],
      child: const MaterialApp(home: SelfTransferScreen()),
    );
  }

  testWidgets('SelfTransferScreen - Same Account Validation', (
    WidgetTester tester,
  ) async {
    final mockService = MockTransferService();

    await tester.pumpWidget(buildTestSetup(mockService));
    await tester.pumpAndSettle();

    // Select From
    final dropdowns = find.byType(DropdownButtonFormField<Account>);
    await tester.tap(dropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank 1').last);
    await tester.pumpAndSettle();

    // Select To
    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank 1').last); // Select the same account
    await tester.pumpAndSettle();

    // Select Category
    final categoryDropdown = find.byType(DropdownButtonFormField<Category>);
    await tester.tap(categoryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transfer Category').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '1000');

    await tester.tap(find.text('TRANSFER FUNDS'));
    await tester.pump();

    expect(
      find.text('Source and Destination accounts must be different.'),
      findsOneWidget,
    );
  });

  testWidgets('SelfTransferScreen - Successful Transfer', (
    WidgetTester tester,
  ) async {
    final mockService = MockTransferService();

    await tester.pumpWidget(buildTestSetup(mockService));
    await tester.pumpAndSettle();

    // Select From
    final dropdowns = find.byType(DropdownButtonFormField<Account>);
    await tester.tap(dropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank 1').last);
    await tester.pumpAndSettle();

    // Select To
    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank 2').last);
    await tester.pumpAndSettle();

    // Select Category
    final categoryDropdown = find.byType(DropdownButtonFormField<Category>);
    await tester.tap(categoryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transfer Category').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '1500');

    await tester.tap(find.text('TRANSFER FUNDS'));
    await tester.pump();

    expect(mockService.lastTransferReq, isNotNull);
    expect(mockService.lastTransferReq!['fromAccountId'], 1);
    expect(mockService.lastTransferReq!['toAccountId'], 2);
    expect(mockService.lastTransferReq!['amount'], 1500.0);
    expect(mockService.lastTransferReq!['categoryId'], 1);
  });

  testWidgets('SelfTransferScreen - Error Handling', (
    WidgetTester tester,
  ) async {
    final mockService = MockTransferService()..throwError = true;

    await tester.pumpWidget(buildTestSetup(mockService));
    await tester.pumpAndSettle();

    // Select From
    final dropdowns = find.byType(DropdownButtonFormField<Account>);
    await tester.tap(dropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank 1').last);
    await tester.pumpAndSettle();

    // Select To
    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank 2').last);
    await tester.pumpAndSettle();

    // Select Category
    final categoryDropdown = find.byType(DropdownButtonFormField<Category>);
    await tester.tap(categoryDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transfer Category').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '1000');

    await tester.tap(find.text('TRANSFER FUNDS'));
    await tester.pump();

    expect(find.textContaining('Transfer failed'), findsOneWidget);
  });
}
