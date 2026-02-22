import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/core_providers.dart';
import '../providers/summary_providers.dart';
import '../models/models.dart';
import '../core/theme/app_theme.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  void _showNetBalanceInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Net Balance'),
        content: const Text(
          'Total Income (All Accounts) - Total Expense (All Accounts)\n\n'
          'Note: Transactions excluded from summary are not considered for balance calculation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final netBalanceAsync = ref.watch(netBalanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: Column(
        children: [
          // ── Net Balance Header ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Text(
                  'Net Balance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () => _showNetBalanceInfo(context),
                  color: Colors.grey.shade600,
                  tooltip: 'How is this calculated?',
                  padding: const EdgeInsets.only(left: 4),
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),
                netBalanceAsync.when(
                  data: (balance) {
                    final isPositive = balance >= 0;
                    return Text(
                      '₹${balance.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isPositive
                            ? AppTheme.creditColor
                            : AppTheme.debitColor,
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (err, st) => const Text('Error'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Account List ─────────────────────────────────────────────────
          Expanded(
            child: accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const Center(child: Text('No accounts created yet.'));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(accountsProvider);
                    ref.invalidate(netBalanceProvider);
                  },
                  child: ListView.builder(
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return _AccountListTile(account: account);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error loading accounts: $e'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(accountsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/accounts/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AccountListTile extends ConsumerWidget {
  final Account account;
  const _AccountListTile({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: Provider takes accountId which cannot be null here
    // since the account is from the backend
    final balanceAsync = ref.watch(accountBalanceProvider(account.id!));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => context.push('/accounts/${account.id}', extra: account),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                account.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (account.isDefault == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Default',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${account.bank ?? 'Unknown Bank'} • ${account.currency ?? 'INR'}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  balanceAsync.when(
                    data: (balance) {
                      final isPositive = balance >= 0;
                      return Text(
                        '${account.currency ?? 'INR'} ${balance.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPositive
                              ? AppTheme.creditColor
                              : AppTheme.debitColor,
                        ),
                      );
                    },
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (err, st) => const Text(
                      'Error',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
