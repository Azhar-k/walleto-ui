import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../providers/core_providers.dart';
import '../providers/summary_providers.dart';
import '../core/theme/app_theme.dart';

// Family provider to fetch transactions for a specific account and date range
final accountTransactionsProvider = FutureProvider.autoDispose
    .family<
      List<Transaction>,
      ({int accountId, DateTime fromDate, DateTime toDate})
    >((ref, arg) async {
      final service = ref.watch(transactionServiceProvider);

      return await service.searchTransactions({
        'accountId': arg.accountId,
        'fromDate': DateFormat('yyyy-MM-dd').format(arg.fromDate),
        'toDate': DateFormat('yyyy-MM-dd').format(arg.toDate),
      });
    });

class AccountDetailsScreen extends ConsumerStatefulWidget {
  final int accountId;
  final Account? initialAccount;

  const AccountDetailsScreen({
    super.key,
    required this.accountId,
    this.initialAccount,
  });

  @override
  ConsumerState<AccountDetailsScreen> createState() =>
      _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ConsumerState<AccountDetailsScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    // Default 30 days ago to today
    final now = DateTime.now();
    _toDate = now;
    _fromDate = now.subtract(const Duration(days: 30));
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If not provided from navigation, we could look it up from accountsProvider
    final accountsAsync = ref.watch(accountsProvider);
    final account =
        widget.initialAccount ??
        accountsAsync.valueOrNull?.firstWhere(
          (a) => a.id == widget.accountId,
          orElse: () =>
              Account(id: widget.accountId, name: 'Unknown', currency: 'INR'),
        ) ??
        Account(id: widget.accountId, name: 'Loading...', currency: 'INR');

    final balanceAsync = ref.watch(accountBalanceProvider(widget.accountId));
    final transactionsAsync = ref.watch(
      accountTransactionsProvider((
        accountId: widget.accountId,
        fromDate: _fromDate,
        toDate: _toDate,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Account',
            onPressed: () => context.push('/accounts/edit', extra: account),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Header: Account Info & Balance ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.account_balance,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.bank ?? 'Unknown Bank',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (account.accountNumber != null &&
                              account.accountNumber!.isNotEmpty)
                            Text(
                              '•••• ${account.accountNumber}',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Current Balance',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                balanceAsync.when(
                  data: (balance) {
                    final isPositive = balance >= 0;
                    return Text(
                      '${account.currency} ${balance.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isPositive
                            ? AppTheme.creditColor
                            : AppTheme.debitColor,
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 32,
                    width: 32,
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, st) => const Text(
                    'Error loading balance',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Date Range Selector ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transactions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    '${DateFormat('MMM d').format(_fromDate)} - ${DateFormat('MMM d').format(_toDate)}',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Transaction List ──────────────────────────────────────────────
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions in this period',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isDebit = tx.transactionType == TransactionType.DEBIT;

                    return ListTile(
                      onTap: () =>
                          context.push('/transactions/edit', extra: tx),
                      leading: CircleAvatar(
                        backgroundColor: isDebit
                            ? AppTheme.debitColor.withValues(alpha: 0.1)
                            : AppTheme.creditColor.withValues(alpha: 0.1),
                        child: Icon(
                          isDebit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isDebit
                              ? AppTheme.debitColor
                              : AppTheme.creditColor,
                        ),
                      ),
                      title: Text(
                        tx.categoryName ?? 'Uncategorized',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('MMM d, y • h:mm a').format(tx.dateTime),
                          ),
                          if (tx.description != null &&
                              tx.description!.isNotEmpty)
                            Text(
                              tx.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      trailing: Text(
                        '${isDebit ? '-' : '+'} ${account.currency} ${tx.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDebit
                              ? AppTheme.debitColor
                              : AppTheme.creditColor,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
