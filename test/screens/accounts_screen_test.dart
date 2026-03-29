import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walleto_ui/screens/accounts_screen.dart';
import 'package:walleto_ui/providers/core_providers.dart';
import 'package:walleto_ui/providers/summary_providers.dart';
import 'package:walleto_ui/models/models.dart';
import 'package:go_router/go_router.dart';

void main() {
  final testAccounts = [
    Account(
      id: 1,
      name: 'Default Bank',
      currency: 'INR',
      isDefault: true,
      bank: 'HDFC',
    ),
    Account(
      id: 2,
      name: 'Wallet',
      currency: 'USD',
      isDefault: false,
      bank: 'PayPal',
    ),
  ];

  Widget buildTestSetup({
    List<Account>? accountsData,
    Object? accountsError,
    double netBalance = 5000.0,
    double account1Balance = 4000.0,
    double account2Balance = 1000.0,
    GoRouter? router,
  }) {
    final overrides = <Override>[
      netBalanceProvider.overrideWith((ref) => netBalance),
      accountBalanceProvider(1).overrideWith((ref) => account1Balance),
      accountBalanceProvider(2).overrideWith((ref) => account2Balance),
    ];

    if (accountsError != null) {
      overrides.add(
        accountsProvider.overrideWith(
          (ref) => Future.error(accountsError, StackTrace.empty),
        ),
      );
    } else {
      overrides.add(
        accountsProvider.overrideWith((ref) => accountsData ?? testAccounts),
      );
    }

    if (router != null) {
      return ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(routerConfig: router),
      );
    }

    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: AccountsScreen()),
    );
  }

  testWidgets('AccountsScreen - Default Retrieval and Display', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestSetup());
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Accounts'), findsOneWidget);

    // Verify Net Balance Header
    expect(find.text('Net Balance'), findsOneWidget);
    expect(find.text('₹5000.00'), findsOneWidget);

    // Verify Account 1 (Default Bank)
    expect(find.text('Default Bank'), findsOneWidget);
    expect(find.text('HDFC • INR'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget); // Default badge
    expect(find.text('INR 4000.00'), findsOneWidget);

    // Verify Account 2 (Wallet)
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('PayPal • USD'), findsOneWidget);
    expect(find.text('USD 1000.00'), findsOneWidget);
  });

  testWidgets('AccountsScreen - Net Balance Info Dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestSetup());
    await tester.pumpAndSettle();

    // Tap info icon
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(
      find.text(
        'Total Income (All Accounts) - Total Expense (All Accounts)\n\nNote: Transactions excluded from summary are not considered for balance calculation.',
      ),
      findsOneWidget,
    );

    // Close dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('AccountsScreen - Empty State', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestSetup(accountsData: []));
    await tester.pumpAndSettle();

    expect(find.text('No accounts created yet.'), findsOneWidget);
  });

  testWidgets('AccountsScreen - Error State and Retry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestSetup(accountsError: Exception('Failed to load accounts')),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Error loading accounts: Exception: Failed to load accounts',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('AccountsScreen - Navigation to New Account', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/accounts',
      routes: [
        GoRoute(
          path: '/accounts',
          builder: (context, state) => const AccountsScreen(),
        ),
        GoRoute(
          path: '/accounts/new',
          builder: (context, state) =>
              const Scaffold(body: Text('New Account')),
        ),
      ],
    );

    await tester.pumpWidget(buildTestSetup(router: router));
    await tester.pumpAndSettle();

    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);

    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Verify navigation by checking if the New Account scaffold is in the tree
    expect(find.text('New Account'), findsOneWidget);
  });

  testWidgets('AccountsScreen - Navigation to Account Details', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/accounts',
      routes: [
        GoRoute(
          path: '/accounts',
          builder: (context, state) => const AccountsScreen(),
        ),
        GoRoute(
          path: '/accounts/:id',
          builder: (context, state) =>
              const Scaffold(body: Text('Account Details')),
        ),
      ],
    );

    await tester.pumpWidget(buildTestSetup(router: router));
    await tester.pumpAndSettle();

    // Tap on the first account card
    await tester.tap(find.text('Default Bank'));
    await tester.pumpAndSettle();

    // Verify navigation by checking if the Account Details scaffold is in the tree
    expect(find.text('Account Details'), findsOneWidget);
  });
}
