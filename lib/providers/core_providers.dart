import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../services/account_service.dart';
import '../services/category_service.dart';
import '../services/transaction_service.dart';
import '../services/additional_services.dart';
import '../services/summary_service.dart';
import '../services/audit_service.dart';
import '../models/models.dart';

final dioProvider = Provider<Dio>((ref) {
  return ApiClient.getCoreClient();
});
// Dio Client Provider
final coreDioProvider = Provider((ref) {
  return ApiClient.getCoreClient();
});

// Service Providers
final accountServiceProvider = Provider((ref) {
  return AccountService(ref.watch(coreDioProvider));
});

final categoryServiceProvider = Provider((ref) {
  return CategoryService(ref.watch(coreDioProvider));
});

final transactionServiceProvider = Provider((ref) {
  return TransactionService(ref.watch(coreDioProvider));
});

final summaryServiceProvider = Provider((ref) {
  return SummaryService(ref.watch(coreDioProvider));
});

final transferServiceProvider = Provider((ref) {
  return TransferService(ref.watch(coreDioProvider));
});

final recurringPaymentServiceProvider = Provider((ref) {
  return RecurringPaymentService(ref.watch(coreDioProvider));
});

final regexServiceProvider = Provider((ref) {
  return RegexService(ref.watch(coreDioProvider));
});

final auditServiceProvider = Provider((ref) {
  return AuditService(ref.watch(coreDioProvider));
});

// State Notifiers / Future Providers
final accountsProvider = FutureProvider<List<Account>>((ref) async {
  final service = ref.watch(accountServiceProvider);
  return await service.getAccounts();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final service = ref.watch(categoryServiceProvider);
  return await service.getCategories();
});

class TransactionSearchNotifier
    extends StateNotifier<AsyncValue<List<Transaction>>> {
  final TransactionService service;

  TransactionSearchNotifier(this.service) : super(const AsyncValue.loading()) {
    search();
  }

  Future<void> search([Map<String, dynamic>? criteria]) async {
    state = const AsyncValue.loading();
    try {
      final transactions = await service.searchTransactions(criteria ?? {});
      state = AsyncValue.data(transactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final transactionSearchProvider =
    StateNotifierProvider<
      TransactionSearchNotifier,
      AsyncValue<List<Transaction>>
    >((ref) {
      final service = ref.watch(transactionServiceProvider);
      return TransactionSearchNotifier(service);
    });
