import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walleto_ui/screens/login_screen.dart';
import 'package:walleto_ui/screens/register_screen.dart';
import 'package:walleto_ui/screens/accounts_screen.dart';
import 'package:walleto_ui/screens/account_details_screen.dart';
import 'package:walleto_ui/screens/account_form_screen.dart';
import 'package:walleto_ui/screens/categories_screen.dart';
import 'package:walleto_ui/screens/category_form_screen.dart';
import 'package:walleto_ui/screens/recurring_payments_screen.dart';
import 'package:walleto_ui/screens/recurring_payment_form_screen.dart';
import 'package:walleto_ui/screens/transactions_screen.dart';
import 'package:walleto_ui/screens/transaction_form_screen.dart';
import 'package:walleto_ui/screens/self_transfer_screen.dart';
import 'package:walleto_ui/screens/summary_screen.dart';
import 'package:walleto_ui/screens/scan_sms_screen.dart';
import 'package:walleto_ui/screens/regex_management_screen.dart';
import 'package:walleto_ui/widgets/main_navigation_shell.dart';
import 'package:walleto_ui/screens/audit_logs_screen.dart';
import 'package:walleto_ui/models/models.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/summary',
  redirect: (BuildContext context, GoRouterState state) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final isLoggedIn = token != null && token.isNotEmpty;
    final isLoggingIn =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isLoggedIn && !isLoggingIn) return '/login';
    if (isLoggedIn && isLoggingIn) return '/summary';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) => MainNavigationShell(child: child),
      routes: [
        GoRoute(
          path: '/summary',
          builder: (context, state) => const SummaryScreen(),
        ),
        GoRoute(
          path: '/accounts',
          builder: (context, state) => const AccountsScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const AccountFormScreen(),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final account = state.extra as Account;
                return AccountFormScreen(existingAccount: account);
              },
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final idStr = state.pathParameters['id']!;
                final accountId = int.tryParse(idStr) ?? 0;
                final account = state.extra as Account?;
                return AccountDetailsScreen(
                  accountId: accountId,
                  initialAccount: account,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/transactions',
          builder: (context, state) {
            final initialFilters = state.extra as Map<String, dynamic>?;
            return TransactionsScreen(initialFilters: initialFilters);
          },
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const TransactionFormScreen(),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final tx = state.extra as Transaction;
                return TransactionFormScreen(existingTransaction: tx);
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/recurring-payments',
      builder: (context, state) => const RecurringPaymentsScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => RecurringPaymentFormScreen(),
        ),
        GoRoute(
          path: 'edit',
          builder: (context, state) {
            final rp = state.extra as RecurringPayment;
            return RecurringPaymentFormScreen(existingPayment: rp);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => CategoriesScreen(),
      routes: [
        GoRoute(path: 'new', builder: (context, state) => CategoryFormScreen()),
        GoRoute(
          path: 'edit',
          builder: (context, state) {
            final category = state.extra as Category;
            return CategoryFormScreen(existingCategory: category);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/self-transfer',
      builder: (context, state) => SelfTransferScreen(),
    ),
    GoRoute(path: '/scan-sms', builder: (context, state) => ScanSmsScreen()),
    GoRoute(
      path: '/regex-patterns',
      builder: (context, state) => RegexManagementScreen(),
    ),
    GoRoute(
      path: '/audit-logs',
      builder: (context, state) => const AuditLogsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const Scaffold(
        appBar: null,
        body: Center(child: Text('Settings Screen')),
      ),
    ),
  ],
);
