import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/core_providers.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(child: Text('No accounts created yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(accountsProvider),
            child: ListView.builder(
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      child: const Icon(Icons.account_balance),
                    ),
                    title: Row(
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (account.isDefault == true) ...[
                          const SizedBox(width: 8),
                          Badge(
                            label: const Text('Default'),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondary,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '${account.bank ?? 'Unknown Bank'} • ${account.currency ?? 'INR'}',
                    ),
                    // We don't have individual account balances in the basic Account model based on the schema,
                    // it usually comes from a separate summary API or is computed on the fly.
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to account details
                    },
                  ),
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
              Text('Error loading accounts: $e'),
              ElevatedButton(
                onPressed: () => ref.refresh(accountsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/accounts/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
