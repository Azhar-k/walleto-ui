import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/core_providers.dart';
import '../providers/additional_providers.dart';

class RecurringPaymentsScreen extends ConsumerWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(recurringPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Toggle All Completed',
            onPressed: () async {
               try {
                   await ref.read(recurringPaymentServiceProvider).toggleAll({"markCompleted": true});
                   ref.invalidate(recurringPaymentsProvider);
               } catch(e) { /* Error */ }
            },
          )
        ],
      ),
      body: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(child: Text('No recurring payments found.'));
          }
          
          final totalAmount = payments.fold<double>(0, (sum, p) => sum + p.amount);
          final remainingAmount = payments.where((p) => p.completed != true).fold<double>(0, (sum, p) => sum + p.amount);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                   children: [
                      Column(
                        children: [
                           const Text('Total Amount', style: TextStyle(color: Colors.grey)),
                           Text('₹${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ]
                      ),
                      Column(
                        children: [
                           const Text('Remaining Amount', style: TextStyle(color: Colors.grey)),
                           Text('₹${remainingAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: remainingAmount > 0 ? Colors.red : Colors.green)),
                        ]
                      )
                   ]
                )
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.refresh(recurringPaymentsProvider),
                  child: ListView.separated(
                    itemCount: payments.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      // Highlight if expired
                      final isExpired = DateTime.tryParse(payment.expiryDate)?.isBefore(DateTime.now()) ?? false;
                      
                      return ListTile(
                        tileColor: isExpired ? Colors.orange.withOpacity(0.1) : null,
                        title: Row(
                          children: [
                             Text(payment.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                             if (isExpired) const Badge(label: Text('Expired'), backgroundColor: Colors.orange)
                          ],
                        ),
                        subtitle: Text('₹${payment.amount} • Due: Day ${payment.dueDay} • Exp: ${payment.expiryDate}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                               value: payment.completed ?? false,
                               onChanged: (val) async {
                                  if (payment.id != null) {
                                      await ref.read(recurringPaymentServiceProvider).completeRecurringPayment(payment.id!);
                                      ref.invalidate(recurringPaymentsProvider);
                                  }
                               }
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => context.push('/recurring-payments/edit', extra: payment),
                            ),
                          ],
                        )
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/recurring-payments/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
