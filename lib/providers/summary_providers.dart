import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'core_providers.dart';

class SummaryFilterState {
  final int year;
  final int month;
  
  SummaryFilterState({required this.year, required this.month});

  SummaryFilterState copyWith({int? year, int? month}) {
    return SummaryFilterState(
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }
}

class SummaryFilterNotifier extends StateNotifier<SummaryFilterState> {
  SummaryFilterNotifier() : super(SummaryFilterState(year: DateTime.now().year, month: DateTime.now().month));

  void setFilter(int year, int month) {
    state = state.copyWith(year: year, month: month);
  }
  
  void previousMonth() {
    int m = state.month - 1;
    int y = state.year;
    if (m == 0) {
      m = 12;
      y -= 1;
    }
    setFilter(y, m);
  }
  
  void nextMonth() {
     int m = state.month + 1;
     int y = state.year;
     if (m == 13) {
        m = 1;
        y += 1;
     }
     setFilter(y, m);
  }
}

final summaryFilterProvider = StateNotifierProvider<SummaryFilterNotifier, SummaryFilterState>((ref) {
  return SummaryFilterNotifier();
});

final monthlySummaryProvider = FutureProvider<MonthlySummary>((ref) async {
  final filter = ref.watch(summaryFilterProvider);
  final service = ref.watch(summaryServiceProvider);
  return await service.getMonthlySummary(filter.year, filter.month, null);
});
