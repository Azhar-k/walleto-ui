import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_interceptor.dart';
import 'api_response_interceptor.dart';

class ApiClient {
  static String get coreBaseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    return 'http://10.0.2.2:8080'; // Loopback for Android emulator
  }

  static String get userBaseUrl {
    if (kIsWeb) return 'http://localhost:8073';
    return 'http://10.0.2.2:8073';
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
