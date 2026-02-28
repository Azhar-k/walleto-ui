import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'core_providers.dart';

// ── Filter state: keeps track of the selected month/year ────────────────────

class SummaryFilterState {
  final int year;
  final int month;

  SummaryFilterState({required this.year, required this.month});

  SummaryFilterState copyWith({int? year, int? month}) =>
      SummaryFilterState(year: year ?? this.year, month: month ?? this.month);

  /// First moment of the month (UTC iso string expected by the backend)
  String get startDate =>
      '$year-${month.toString().padLeft(2, '0')}-01T00:00:00';

  /// Last moment of the month
  String get endDate {
    final lastDay = DateTime(year, month + 1, 0).day;
    return '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}T23:59:59';
  }
}

class SummaryFilterNotifier extends StateNotifier<SummaryFilterState> {
  SummaryFilterNotifier()
    : super(
        SummaryFilterState(
          year: DateTime.now().year,
          month: DateTime.now().month,
        ),
      );

  void setFilter(int year, int month) =>
      state = state.copyWith(year: year, month: month);

  void previousMonth() {
    int m = state.month - 1;
    int y = state.year;
    if (m == 0) {
      m = 12;
      y -= 1;
    }
    setFilter(y, m);
  }

  void nextMonth() {
    int m = state.month + 1;
    int y = state.year;
    if (m == 13) {
      m = 1;
      y += 1;
    }
    setFilter(y, m);
  }
}

final summaryFilterProvider =
    StateNotifierProvider<SummaryFilterNotifier, SummaryFilterState>(
      (ref) => SummaryFilterNotifier(),
    );

// ── Selected account ─────────────────────────────────────────────────────────

final selectedAccountProvider = StateProvider<Account?>((ref) => null);

// ── Default account ──────────────────────────────────────────────────────────

final defaultAccountProvider = FutureProvider<Account>((ref) async {
  final service = ref.watch(accountServiceProvider);
  return await service.getDefaultAccount();
});

// ── Monthly summary (income + expense) ──────────────────────────────────────

class MonthlySummaryData {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final List<Map<String, dynamic>> expenseBreakdown;
  final List<Map<String, dynamic>> incomeBreakdown;

  MonthlySummaryData({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.expenseBreakdown,
    required this.incomeBreakdown,
  });
}

final monthlySummaryProvider = FutureProvider<MonthlySummaryData>((ref) async {
  final filter = ref.watch(summaryFilterProvider);
  final service = ref.watch(summaryServiceProvider);

  // Use selected account, or fallback to default
  Account? account = ref.watch(selectedAccountProvider);
  if (account == null) {
    account = await ref.watch(defaultAccountProvider.future);
  }

  final accountId = account?.id ?? 0;

  // Run all three calls in parallel
  final results = await Future.wait([
    service.getAccountSummary(
      accountId,
      startDate: filter.startDate,
      endDate: filter.endDate,
    ),
    service.getCategoryExpenseSummary(
      accountId,
      startDate: filter.startDate,
      endDate: filter.endDate,
    ),
    service.getCategoryIncomeSummary(
      accountId,
      startDate: filter.startDate,
      endDate: filter.endDate,
    ),
  ]);

  final summary = results[0] as Map<String, dynamic>;
  final expenseBreakdown = (results[1] as List).cast<Map<String, dynamic>>();
  final incomeBreakdown = (results[2] as List).cast<Map<String, dynamic>>();

  return MonthlySummaryData(
    totalIncome: (summary['totalIncome'] as num?)?.toDouble() ?? 0.0,
    totalExpense: (summary['totalExpense'] as num?)?.toDouble() ?? 0.0,
    balance:
        (summary['netBalance'] as num?)?.toDouble() ??
        (summary['balance'] as num?)?.toDouble() ??
        0.0,
    expenseBreakdown: expenseBreakdown,
    incomeBreakdown: incomeBreakdown,
  );
});

// ── Net balance (across all accounts) ────────────────────────────────────────

final netBalanceProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(summaryServiceProvider);
  return await service.getNetBalance();
});

// ── Individual Account Balance ───────────────────────────────────────────────

final accountBalanceProvider = FutureProvider.family<double, int>((
  ref,
  accountId,
) async {
  final service = ref.watch(summaryServiceProvider);
  return await service.getAccountBalance(accountId);
});
