import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_interceptor.dart';
import 'api_response_interceptor.dart';
import '../config/app_config.dart';

class ApiClient {
  static String get coreBaseUrl {
    return AppConfig.coreBaseUrl;
  }

  static String get userBaseUrl {
    return AppConfig.userBaseUrl;
  }

  static Dio getCoreClient() {
    final dio = Dio(
      BaseOptions(
        baseUrl: coreBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(AuthInterceptor());
    // Unwrap {"success":true, "data": <payload>} envelope on every response
    dio.interceptors.add(ApiResponseInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    return dio;
  }

  static Dio getUserClient() {
    final dio = Dio(
      BaseOptions(
        baseUrl: userBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    return dio;
  }
}
