import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Wrapper around the Core API summary and balance endpoints.
/// The [ApiResponseInterceptor] already unwraps {"success":true,"data":...}
/// before responses reach this class, so we work directly with the payload.
class SummaryService {
  final Dio _dio;
  SummaryService(this._dio);

  // ── /api/summary/{accountId} ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getAccountSummary(
    int accountId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _dio.get<dynamic>(
        '/api/summary/$accountId',
        queryParameters: queryParams,
      );
      // After the interceptor, data is the payload directly
      final payload = response.data;
      if (payload is Map<String, dynamic>) return payload;
      return {};
    } catch (e, st) {
      if (kDebugMode) debugPrint('[SummaryService.getAccountSummary] $e\n$st');
      rethrow;
    }
  }

  // ── /api/summary/{accountId}/categories/expense ──────────────────────────

  Future<List<Map<String, dynamic>>> getCategoryExpenseSummary(
    int accountId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _dio.get<dynamic>(
        '/api/summary/$accountId/categories/expense',
        queryParameters: queryParams,
      );
      final payload = response.data;
      if (payload is List) {
        return payload.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[SummaryService.getCategoryExpenseSummary] $e\n$st');
      }
      rethrow;
    }
  }

  // ── /api/summary/{accountId}/categories/income ───────────────────────────

  Future<List<Map<String, dynamic>>> getCategoryIncomeSummary(
    int accountId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _dio.get<dynamic>(
        '/api/summary/$accountId/categories/income',
        queryParameters: queryParams,
      );
      final payload = response.data;
      if (payload is List) {
        return payload.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[SummaryService.getCategoryIncomeSummary] $e\n$st');
      }
      rethrow;
    }
  }

  // ── /api/balance ──────────────────────────────────────────────────────────

  Future<double> getNetBalance() async {
    try {
      final response = await _dio.get<dynamic>('/api/balance');
      final payload = response.data;
      if (payload is num) return payload.toDouble();
      if (payload is Map) {
        return (payload['balance'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[SummaryService.getNetBalance] $e\n$st');
      rethrow;
    }
  }

  // ── /api/balance/{accountId} ─────────────────────────────────────────────

  Future<double> getAccountBalance(int accountId) async {
    try {
      final response = await _dio.get<dynamic>('/api/balance/$accountId');
      final payload = response.data;
      if (payload is num) return payload.toDouble();
      if (payload is Map) {
        return (payload['balance'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[SummaryService.getAccountBalance] $e\n$st');
      rethrow;
    }
  }
}
