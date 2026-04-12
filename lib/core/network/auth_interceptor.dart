import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:walleto_ui/core/storage/token_storage.dart';
import 'package:walleto_ui/services/auth_service.dart';
import 'package:walleto_ui/core/network/api_client.dart';
import 'package:walleto_ui/core/network/api_response_interceptor.dart';
import 'package:walleto_ui/core/router/app_router.dart';

class AuthInterceptor extends Interceptor {
  static Future<String?>? _refreshTokenFuture;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getAccessToken();

    if (token != null) {
      debugPrint('[AuthInterceptor] Adding Bearer token to request: ${options.path}');
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      debugPrint('[AuthInterceptor] No access token found for request: ${options.path}');
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      debugPrint('[AuthInterceptor] Received 401 Unauthorized for path: ${err.requestOptions.path}');
      if (err.requestOptions.path.contains('/api/v1/auth/refresh')) {
        debugPrint('[AuthInterceptor] 401 on refresh endpoint. Clearing tokens and redirecting to login.');
        await _clearTokensAndRedirect();
        return super.onError(err, handler);
      }

      // CONCURRENCY FIX: Check if another isolate already updated the token!
      final failedToken = err.requestOptions.headers['Authorization']?.toString().replaceFirst('Bearer ', '');
      final currentStorageToken = await TokenStorage.getAccessToken();
      
      String? newToken;
      
      if (currentStorageToken != null && failedToken != null && currentStorageToken != failedToken) {
        debugPrint('[AuthInterceptor] Storage token already differs from failed token. Bypassing refresh.');
        newToken = currentStorageToken;
      } else {
        newToken = await _refreshTokenAndRetry();
      }

      if (newToken != null) {
        try {
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newToken';

          debugPrint('[AuthInterceptor] Retrying original request: ${retryOptions.path}');
          final retryDio = Dio(BaseOptions(baseUrl: err.requestOptions.baseUrl));
          // Attach ApiResponseInterceptor to unwrap the {"success": true, "data": ...} envelope
          retryDio.interceptors.add(ApiResponseInterceptor());
          final retryResponse = await retryDio.fetch(retryOptions);
          debugPrint('[AuthInterceptor] Original request retry successful.');
          return handler.resolve(retryResponse);
        } catch (e) {
          debugPrint('[AuthInterceptor] Failed to retry request: $e');
        }
      } else {
        return super.onError(err, handler);
      }
    }
    super.onError(err, handler);
  }

  Future<void> _clearTokensAndRedirect() async {
    await TokenStorage.clearTokens();
    if (rootNavigatorKey.currentContext?.mounted ?? false) {
      rootNavigatorKey.currentContext?.go('/login');
    }
  }

  Future<String?> _refreshTokenAndRetry() async {
    if (_refreshTokenFuture != null) {
      debugPrint('[AuthInterceptor] Waiting for ongoing refresh token request...');
      return await _refreshTokenFuture;
    }

    _refreshTokenFuture = _performRefreshToken();
    final result = await _refreshTokenFuture;
    _refreshTokenFuture = null;
    return result;
  }

  Future<String?> _performRefreshToken() async {
    String? originalRefreshToken;
    try {
      originalRefreshToken = await TokenStorage.getRefreshToken();
      if (originalRefreshToken == null) {
        debugPrint('[AuthInterceptor] No refresh token found. Clearing tokens and redirecting to login.');
        await _clearTokensAndRedirect();
        return null;
      }

      debugPrint('[AuthInterceptor] Found refresh token, attempting to refresh...');
      final dio = ApiClient.getUserClient();
      final authService = AuthService(dio);
      final response = await authService.refreshToken(
        RefreshTokenRequest(refreshToken: originalRefreshToken),
      );

      debugPrint('[AuthInterceptor] Refresh successful. Saving new tokens.');
      await TokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      return response.accessToken;
    } catch (e) {
      debugPrint('[AuthInterceptor] Failed to refresh token: $e');

      // Cross-isolate concurrency recovery:
      // If two isolates try to refresh at the same time, the backend will reject one with 400.
      if (e is DioException && e.response?.statusCode == 400 && originalRefreshToken != null) {
        // Wait briefly to allow the winning isolate to write to SecureStorage
        await Future.delayed(const Duration(milliseconds: 500));
        final latestRefreshToken = await TokenStorage.getRefreshToken();
        if (latestRefreshToken != null && latestRefreshToken != originalRefreshToken) {
          debugPrint('[AuthInterceptor] Recovered from concurrent refresh! Another isolate refreshed the token.');
          return await TokenStorage.getAccessToken();
        }
      }

      await _clearTokensAndRedirect();
      return null;
    }
  }
}
