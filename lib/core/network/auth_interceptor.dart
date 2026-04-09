import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import 'package:walleto_ui/core/storage/token_storage.dart';
import 'package:walleto_ui/services/auth_service.dart';
import 'package:walleto_ui/core/network/api_client.dart';
import 'package:walleto_ui/core/router/app_router.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getAccessToken();

    if (token != null) {
      developer.log(
        'Adding Bearer token to request: ${options.path}',
        name: 'AuthInterceptor',
      );
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      developer.log(
        'No access token found for request: ${options.path}',
        name: 'AuthInterceptor',
      );
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      developer.log(
        'Received 401 Unauthorized for path: ${err.requestOptions.path}',
        name: 'AuthInterceptor',
      );
      if (err.requestOptions.path.contains('/api/v1/auth/refresh')) {
        developer.log(
          '401 on refresh endpoint. Clearing tokens and redirecting to login.',
          name: 'AuthInterceptor',
        );
        await TokenStorage.clearTokens();
        if (rootNavigatorKey.currentContext?.mounted ?? false) {
          rootNavigatorKey.currentContext?.go('/login');
        }
        return super.onError(err, handler);
      }

      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken != null) {
        developer.log(
          'Found refresh token, attempting to refresh...',
          name: 'AuthInterceptor',
        );
        try {
          final dio = Dio(BaseOptions(baseUrl: ApiClient.userBaseUrl));
          final authService = AuthService(dio);
          final response = await authService.refreshToken(
            RefreshTokenRequest(refreshToken: refreshToken),
          );

          developer.log(
            'Refresh successful. Saving new tokens.',
            name: 'AuthInterceptor',
          );
          await TokenStorage.saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
          );

          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] =
              'Bearer ${response.accessToken}';

          developer.log(
            'Retrying original request: ${retryOptions.path}',
            name: 'AuthInterceptor',
          );
          final mainDio = Dio(BaseOptions(baseUrl: ApiClient.userBaseUrl));
          final retryResponse = await mainDio.fetch(retryOptions);
          developer.log(
            'Original request retry successful.',
            name: 'AuthInterceptor',
          );
          return handler.resolve(retryResponse);
        } catch (e) {
          developer.log('Failed to refresh token: $e', name: 'AuthInterceptor');
          await TokenStorage.clearTokens();
          if (rootNavigatorKey.currentContext?.mounted ?? false) {
            rootNavigatorKey.currentContext?.go('/login');
          }
          return super.onError(err, handler);
        }
      } else {
        developer.log(
          'No refresh token found. Clearing tokens and redirecting to login.',
          name: 'AuthInterceptor',
        );
        await TokenStorage.clearTokens();
        if (rootNavigatorKey.currentContext?.mounted ?? false) {
          rootNavigatorKey.currentContext?.go('/login');
        }
      }
    }
    super.onError(err, handler);
  }
}
