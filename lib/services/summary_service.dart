import 'package:dio/dio.dart';

class SummaryService {
  final Dio _dio;
  SummaryService(this._dio);

  /// GET /api/summary/{accountId}?startDate=&endDate=
  Future<Map<String, dynamic>> getAccountSummary(
    int accountId, {
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final response = await _dio.get<Map<String, dynamic>>(
      '/api/summary/$accountId',
      queryParameters: queryParams,
    );
    // The API wraps results in ApiResponse { data: { totalIncome, totalExpense, balance } }
    return (response.data?['data'] as Map<String, dynamic>?) ??
        response.data ??
        {};
  }

  /// GET /api/summary/{accountId}/categories/expense
  Future<List<dynamic>> getCategoryExpenseSummary(
    int accountId, {
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final response = await _dio.get<Map<String, dynamic>>(
      '/api/summary/$accountId/categories/expense',
      queryParameters: queryParams,
    );
    final data = response.data?['data'];
    if (data is List) return data;
    return [];
  }

  /// GET /api/summary/{accountId}/categories/income
  Future<List<dynamic>> getCategoryIncomeSummary(
    int accountId, {
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final response = await _dio.get<Map<String, dynamic>>(
      '/api/summary/$accountId/categories/income',
      queryParameters: queryParams,
    );
    final data = response.data?['data'];
    if (data is List) return data;
    return [];
  }

  /// GET /api/balance — net balance across all accounts
  Future<double> getNetBalance() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/balance');
    final data = response.data?['data'];
    if (data is num) return data.toDouble();
    if (data is Map) return (data['balance'] as num?)?.toDouble() ?? 0.0;
    return 0.0;
  }

  /// GET /api/balance/{accountId}
  Future<double> getAccountBalance(int accountId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/balance/$accountId',
    );
    final data = response.data?['data'];
    if (data is num) return data.toDouble();
    if (data is Map) return (data['balance'] as num?)?.toDouble() ?? 0.0;
    return 0.0;
  }
}
