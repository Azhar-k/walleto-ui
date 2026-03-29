import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
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
      options.headers['Authorization'] = 'Bearer $token';
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      if (err.requestOptions.path.contains('/api/v1/auth/refresh')) {
        await TokenStorage.clearTokens();
        if (rootNavigatorKey.currentContext?.mounted ?? false) {
          rootNavigatorKey.currentContext?.go('/login');
        }
        return super.onError(err, handler);
      }

      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken != null) {
        try {
          final dio = Dio(BaseOptions(baseUrl: ApiClient.userBaseUrl));
          final authService = AuthService(dio);
          final response = await authService.refreshToken(
            RefreshTokenRequest(refreshToken: refreshToken),
          );

          await TokenStorage.saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
          );

          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] =
              'Bearer ${response.accessToken}';

          final mainDio = Dio(BaseOptions(baseUrl: ApiClient.userBaseUrl));
          final retryResponse = await mainDio.fetch(retryOptions);
          return handler.resolve(retryResponse);
        } catch (e) {
          await TokenStorage.clearTokens();
          if (rootNavigatorKey.currentContext?.mounted ?? false) {
            rootNavigatorKey.currentContext?.go('/login');
          }
          return super.onError(err, handler);
        }
      } else {
        await TokenStorage.clearTokens();
        if (rootNavigatorKey.currentContext?.mounted ?? false) {
          rootNavigatorKey.currentContext?.go('/login');
        }
      }
    }
    super.onError(err, handler);
  }
}
