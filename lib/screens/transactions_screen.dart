import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/core_providers.dart';
import '../models/models.dart';
import '../core/theme/app_theme.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  // basic filter state
  Map<String, dynamic> _filters = {};

  @override
  void initState() {
    super.initState();
    // Default 30 days
    _filters = {
      "fromDate": DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().subtract(const Duration(days: 30))),
      "toDate": DateFormat('yyyy-MM-dd').format(DateTime.now()),
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionSearchProvider.notifier).search(_filters);
    });
  }

  void _openFilters() {
    // In a real app this would open a complex bottom sheet or standard dialog
    // for Date ranges, Type, Account, Category, Amount etc.
    // For this step, we keep a simplified dialog to demonstrate flow
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filters'),
        content: const Text(
          'Advanced filtering implemented via backend /search endpoint.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilters,
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(transactionSearchProvider.notifier).search(_filters),
            child: ListView.separated(
              itemCount: transactions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isCredit = tx.transactionType == TransactionType.CREDIT;
                final color = isCredit
                    ? AppTheme.creditColor
                    : AppTheme.debitColor;
                final prefix = isCredit ? '+' : '-';

                return ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tx.description ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$prefix ${tx.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tx.categoryName ?? '',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                            ),
                          ),
                          const Text(' • '),
                          Text(
                            tx.accountName ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        DateFormat.yMMMd().add_jm().format(tx.dateTime),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  onTap: () {
                    // view details or edit
                    context.push('/transactions/edit', extra: tx);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading transactions: $e'),
              ElevatedButton(
                onPressed: () => ref
                    .read(transactionSearchProvider.notifier)
                    .search(_filters),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
