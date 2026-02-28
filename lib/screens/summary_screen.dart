import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/summary_providers.dart';
import '../providers/core_providers.dart';
import '../models/models.dart';
import '../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(summaryFilterProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final defaultAccountAsync = ref.watch(defaultAccountProvider);
    final selectedAccount = ref.watch(selectedAccountProvider);
    final accountsAsync = ref.watch(accountsProvider);

    final monthName = DateFormat(
      'MMMM',
    ).format(DateTime(filterState.year, filterState.month));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // ignore: unused_result
          await ref.refresh(defaultAccountProvider.future);
          // ignore: unused_result
          await ref.refresh(accountsProvider.future);
          // ignore: unused_result
          await ref.refresh(monthlySummaryProvider.future);
          // ignore: unused_result
          await ref.refresh(netBalanceProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor,
                child: Column(
                  children: [
                    // Account Selector
                    accountsAsync.when(
                      data: (accounts) {
                        if (accounts.isEmpty) {
                          return const Text(
                            'No accounts available',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          );
                        }

                        // Determine the active account to display in dropdown
                        Account? activeAccount = selectedAccount;
                        if (activeAccount == null) {
                          final defaultAccountOpt =
                              defaultAccountAsync.valueOrNull;
                          if (defaultAccountOpt != null) {
                            activeAccount = accounts.firstWhere(
                              (a) => a.id == defaultAccountOpt.id,
                              orElse: () => accounts.first,
                            );
                          } else if (accounts.isNotEmpty) {
                            activeAccount = accounts.first;
                          }
                        }

                        // ensure activeAccount is really in the list to avoid Dropdown errors
                        if (activeAccount != null &&
                            !accounts.any((a) => a.id == activeAccount!.id)) {
                          activeAccount = accounts.first;
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Account>(
                              value: activeAccount,
                              dropdownColor: Theme.of(context).primaryColor,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              items: accounts.map((account) {
                                return DropdownMenuItem<Account>(
                                  value: account,
                                  child: Text(account.name),
                                );
                              }).toList(),
                              onChanged: (Account? newValue) {
                                if (newValue != null &&
                                    newValue.id != activeAccount?.id) {
                                  ref
                                          .read(
                                            selectedAccountProvider.notifier,
                                          )
                                          .state =
                                      newValue;

                                  // Refresh summary to reflect the new account
                                  ref.invalidate(monthlySummaryProvider);
                                }
                              },
                            ),
                          ),
                        );
                      },
                      loading: () => const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white70,
                          strokeWidth: 2,
                        ),
                      ),
                      error: (_, _) => const Text(
                        'Error loading accounts',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Monthly Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    summaryAsync.when(
                      data: (summary) {
                        final monthlyBalance =
                            summary.totalIncome - summary.totalExpense;
                        return Text(
                          '₹${monthlyBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                      loading: () =>
                          const CircularProgressIndicator(color: Colors.white),
                      error: (_, _) => const Text(
                        'Error',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Month navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                          onPressed: () => ref
                              .read(summaryFilterProvider.notifier)
                              .previousMonth(),
                        ),
                        Text(
                          '$monthName ${filterState.year}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                          onPressed: () => ref
                              .read(summaryFilterProvider.notifier)
                              .nextMonth(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: summaryAsync.when(
                data: (summary) => _buildSummaryContent(
                  context,
                  summary,
                  filterState,
                  selectedAccount,
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Text('Error loading summary: $e'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // ignore: unused_result
                            ref.refresh(defaultAccountProvider);
                            // ignore: unused_result
                            ref.refresh(monthlySummaryProvider);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryContent(
    BuildContext context,
    MonthlySummaryData summary,
    SummaryFilterState filterState,
    Account? selectedAccount,
  ) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      context: context,
                      title: 'Expense',
                      amount: summary.totalExpense,
                      color: AppTheme.debitColor,
                      icon: Icons.arrow_upward,
                      isSelected: _tabController.index == 0,
                      onTap: () {
                        if (_tabController.index != 0) {
                          _tabController.animateTo(0);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoCard(
                      context: context,
                      title: 'Income',
                      amount: summary.totalIncome,
                      color: AppTheme.creditColor,
                      icon: Icons.arrow_downward,
                      isSelected: _tabController.index == 1,
                      onTap: () {
                        if (_tabController.index != 1) {
                          _tabController.animateTo(1);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Provide fixed height or Expanded, since it's inside a SingleScrollView (CustomScrollView -> SliverToBoxAdapter),
              // we'll use a fixed height container that is large enough, or just render both lists conditionally.
              // Since it's inside a column, we can do an IndexedStack or AnimatedSwitcher for dynamic height, or just standard conditionals:
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  final isExpenseTab = _tabController.index == 0;
                  final activeBreakdown = isExpenseTab
                      ? summary.expenseBreakdown
                      : summary.incomeBreakdown;
                  final activeTotal = isExpenseTab
                      ? summary.totalExpense
                      : summary.totalIncome;
                  final activeColor = isExpenseTab
                      ? AppTheme.debitColor
                      : AppTheme.creditColor;

                  return Column(
                    children: [
                      if (activeBreakdown.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'No transactions recorded for this period.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else ...[
                        SizedBox(
                          height: 200,
                          child: _buildPieChart(activeBreakdown, activeColor),
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryList(
                          context,
                          activeTotal,
                          activeColor,
                          activeBreakdown,
                          selectedAccount?.id ?? 0,
                          selectedAccount?.name ?? '',
                          DateTime(filterState.year, filterState.month, 1),
                          DateTime(
                            filterState.year,
                            filterState.month + 1,
                            0,
                            23,
                            59,
                            59,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isSelected ? 0.2 : 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isSelected ? 0.6 : 0.2),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(
    List<Map<String, dynamic>> breakdowns,
    Color baseColor,
  ) {
    // Generate variations of the base color if we want, or just stick to a palette.
    // Let's use a dynamic palette that tints the base color.
    final colors = [
      baseColor,
      baseColor.withValues(alpha: 0.8),
      baseColor.withValues(alpha: 0.6),
      baseColor.withValues(alpha: 0.4),
      baseColor.withValues(alpha: 0.9),
      baseColor.withValues(alpha: 0.7),
      baseColor.withValues(alpha: 0.5),
      baseColor.withValues(alpha: 0.3),
    ];
    int colorIdx = 0;
    final sections = breakdowns.map((b) {
      final c = colors[colorIdx % colors.length];
      colorIdx++;
      final amount = (b['totalAmount'] as num?)?.toDouble() ?? 0.0;
      return PieChartSectionData(
        color: c,
        value: amount,
        title: amount.toStringAsFixed(0),
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(sectionsSpace: 2, centerSpaceRadius: 40, sections: sections),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    double total,
    Color baseColor,
    List<Map<String, dynamic>> breakdowns,
    int accountId,
    String accountName,
    DateTime startDate,
    DateTime endDate,
  ) {
    final colors = [
      baseColor,
      baseColor.withValues(alpha: 0.8),
      baseColor.withValues(alpha: 0.6),
      baseColor.withValues(alpha: 0.4),
      baseColor.withValues(alpha: 0.9),
      baseColor.withValues(alpha: 0.7),
      baseColor.withValues(alpha: 0.5),
      baseColor.withValues(alpha: 0.3),
    ];
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: breakdowns.length,
      itemBuilder: (ctx, idx) {
        final b = breakdowns[idx];
        final c = colors[idx % colors.length];
        final amount = (b['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final count = b['transactionCount'] ?? 0;
        final categoryName = b['categoryName'] ?? 'Unknown';
        final pct = total > 0 ? (amount / total) * 100 : 0;

        return ListTile(
          onTap: () async {
            final categories = await ref.read(categoriesProvider.future);
            int? categoryId;
            try {
              final cat = categories.firstWhere(
                (c) => c.name.toLowerCase() == categoryName.toLowerCase(),
              );
              categoryId = cat.id;
            } catch (_) {}

            if (context.mounted) {
              context.go(
                '/transactions',
                extra: {
                  'accountId': accountId,
                  if (categoryId != null) 'categoryId': categoryId,
                  'fromDate': startDate.toIso8601String().split('T')[0],
                  'toDate': endDate.toIso8601String().split('T')[0],
                  'excludeFromSummary': false,
                },
              );
            }
          },
          leading: Icon(Icons.circle, color: c, size: 16),
          title: Text(categoryName),
          subtitle: Text('$count transactions'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}
