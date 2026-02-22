import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // If 401 Unauthorized, we could clear the token and force login here
    if (err.response?.statusCode == 401) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('auth_token');
        // A global navigation to login screen could be triggered here via a router listener
      });
    }
    super.onError(err, handler);
  }
}
