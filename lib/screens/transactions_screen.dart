import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/core_providers.dart';
import '../models/models.dart'; // needed by _TransactionTile
import '../core/theme/app_theme.dart'; // needed by _TransactionTile

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
                return _TransactionTile(
                  tx: tx,
                  onTap: () => context.push('/transactions/edit', extra: tx),
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

// ─── Per-item widget with expandable description ─────────────────────────────

class _TransactionTile extends StatefulWidget {
  final Transaction tx;
  final VoidCallback onTap;

  const _TransactionTile({required this.tx, required this.onTap});

  @override
  State<_TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<_TransactionTile> {
  bool _descExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final isCredit = tx.transactionType == TransactionType.CREDIT;
    final color = isCredit ? AppTheme.creditColor : AppTheme.debitColor;
    final prefix = isCredit ? '+' : '−';
    final hasDesc = (tx.description ?? '').trim().isNotEmpty;
    final hasCounterparty = (tx.counterpartyName ?? '').trim().isNotEmpty;

    // Short preview: first 3 words of description
    final words = (tx.description ?? '').trim().split(RegExp(r'\s+'));
    final shortDesc = words.take(3).join(' ');
    final descIsTruncated = words.length > 3;

    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Primary row: amount (big) ────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Category chip
                if ((tx.categoryName ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tx.categoryName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                // Amount — the star of the show
                Text(
                  '$prefix ₹${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // ── Secondary row: account • counterparty • date ─────────────────
            Row(
              children: [
                if ((tx.accountName ?? '').isNotEmpty) ...[
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    tx.accountName!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                if (hasCounterparty) ...[
                  const Text(
                    '  ·  ',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Icon(
                    Icons.person_outline,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      tx.counterpartyName!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  DateFormat.MMMd().add_jm().format(tx.dateTime),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            // ── Collapsible description ──────────────────────────────────────
            if (hasDesc) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _descExpanded ? (tx.description ?? '') : shortDesc,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  if (descIsTruncated)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _descExpanded = !_descExpanded),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          _descExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
