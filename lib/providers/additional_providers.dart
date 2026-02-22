import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'core_providers.dart';

// State Notifiers / Future Providers for Additional Entities
final recurringPaymentsProvider = FutureProvider<List<RecurringPayment>>((ref) async {
  final service = ref.watch(recurringPaymentServiceProvider);
  return await service.getRecurringPayments();
});

final regexesProvider = FutureProvider<List<RegexPattern>>((ref) async {
  final service = ref.watch(regexServiceProvider);
  return await service.getRegexPatterns();
});
