import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/summary_providers.dart';
import '../providers/core_providers.dart';
import '../models/models.dart';
import '../core/theme/app_theme.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(summaryFilterProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final netBalanceAsync = ref.watch(netBalanceProvider); // Overall Net Balance across all time

    final monthName = DateFormat('MMMM').format(DateTime(filterState.year, filterState.month));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
            ref.refresh(monthlySummaryProvider);
            ref.refresh(netBalanceProvider);
        },
        child: CustomScrollView(
          slivers: [
             SliverToBoxAdapter(
                 child: Container(
                     padding: const EdgeInsets.all(16),
                     color: Theme.of(context).primaryColor,
                     child: Column(
                        children: [
                           const Text('Net Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
                           const SizedBox(height: 8),
                           netBalanceAsync.when(
                              data: (balance) => Text('₹${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                              loading: () => const CircularProgressIndicator(color: Colors.white),
                              error: (_, _) => const Text('Error', style: TextStyle(color: Colors.white)),
                           ),
                           const SizedBox(height: 16),
                           Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                 IconButton(
                                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                                    onPressed: () => ref.read(summaryFilterProvider.notifier).previousMonth(),
                                 ),
                                 Text('$monthName ${filterState.year}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                 IconButton(
                                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                                    onPressed: () => ref.read(summaryFilterProvider.notifier).nextMonth(),
                                 ),
                              ]
                           )
                        ]
                     )
                 )
             ),
             SliverToBoxAdapter(
                child: summaryAsync.when(
                   data: (summary) => _buildSummaryContent(context, summary),
                   loading: () =>  const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
                   error: (e, st) => Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('Error loading summary: $e'))),
                )
             )
          ],
        )
      )
    );
  }

  Widget _buildSummaryContent(BuildContext context, MonthlySummary summary) {
      // Income vs Expense Cards
      return Padding(
         padding: const EdgeInsets.all(16),
         child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Row(
                  children: [
                     Expanded(child: _buildInfoCard(context, 'Income', summary.totalIncome, AppTheme.creditColor, Icons.arrow_downward)),
                     const SizedBox(width: 16),
                     Expanded(child: _buildInfoCard(context, 'Expense', summary.totalExpense, AppTheme.debitColor, Icons.arrow_upward)),
                  ]
               ),
               const SizedBox(height: 32),
               const Text('Expense Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               const SizedBox(height: 16),
               if (summary.categoryBreakdowns == null || summary.categoryBreakdowns!.where((c) => c.type == CategoryType.EXPENSE).isEmpty)
                  const Center(child: Text('No expenses recorded for this month.', style: TextStyle(color: Colors.grey)))
               else ...[
                  SizedBox(
                     height: 200,
                     child: _buildPieChart(summary.categoryBreakdowns!.where((c) => c.type == CategoryType.EXPENSE).toList())
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryList(summary.categoryBreakdowns!.where((c) => c.type == CategoryType.EXPENSE).toList(), summary.totalExpense),
               ]
            ]
         )
      );
  }

  Widget _buildInfoCard(BuildContext context, String title, double amount, Color color, IconData icon) {
      return Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3))
         ),
         child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                  children: [
                     Icon(icon, color: color, size: 16),
                     const SizedBox(width: 8),
                     Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  ]
               ),
               const SizedBox(height: 8),
               Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ]
         )
      );
  }

  Widget _buildPieChart(List<CategorySummaryBreakdown> breakdowns) {
     final colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.amber];
     
     int colorIdx = 0;
     final sections = breakdowns.map((b) {
        final c = colors[colorIdx % colors.length];
        colorIdx++;
        return PieChartSectionData(
           color: c,
           value: b.totalAmount,
           title: b.totalAmount.toStringAsFixed(0),
           radius: 50,
           titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)
        );
     }).toList();

     return PieChart(
        PieChartData(
           sectionsSpace: 2,
           centerSpaceRadius: 40,
           sections: sections,
        )
     );
  }

  Widget _buildCategoryList(List<CategorySummaryBreakdown> breakdowns, double totalExpense) {
     final colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.amber];
     
     return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: breakdowns.length,
        itemBuilder: (ctx, idx) {
           final b = breakdowns[idx];
           final c = colors[idx % colors.length];
           final pct = totalExpense > 0 ? (b.totalAmount / totalExpense) * 100 : 0;

           return ListTile(
              leading: Icon(Icons.circle, color: c, size: 16),
              title: Text(b.categoryName),
              subtitle: Text('${b.transactionCount} transactions'),
              trailing: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                    Text('₹${b.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                 ]
              ),
           );
        }
     );
  }
}
