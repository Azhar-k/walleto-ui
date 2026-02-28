import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Intercepts every response from the Core API and unwraps the
/// ApiResponse envelope:  {"success":true, "data": payload}
///
/// After this interceptor the rest of the Retrofit-generated code
/// receives payload directly, so List / object deserialisation works.
class ApiResponseInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;

    if (data is Map<String, dynamic> && data.containsKey('data')) {
      // Unwrap the envelope
      response.data = data['data'];

      // Log failures from the backend even when HTTP status is 200
      final success = data['success'];
      final message = data['message'];
      if (success == false) {
        if (kDebugMode) {
          debugPrint(
            '[ApiResponseInterceptor] Backend returned success=false '
            'for ${response.requestOptions.uri}: $message',
          );
        }
      }
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log every network error so they appear in the console
    if (kDebugMode) {
      debugPrint(
        '[ApiResponseInterceptor] ❌ DioException '
        '${err.type.name} → ${err.requestOptions.uri}\n'
        '  message : ${err.message}\n'
        '  response: ${err.response?.data}',
      );
    }
    handler.next(err);
  }
}
