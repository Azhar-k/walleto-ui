import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_interceptor.dart';
import 'api_response_interceptor.dart';

class ApiClient {
  static String get coreBaseUrl {
    // if (kIsWeb) return 'http://localhost:8080';
    return 'https://9aad-2401-4900-8fdd-19a5-23cd-429a-2f67-4f06.ngrok-free.app/api/core'; // Loopback for Android emulator
  }

  static String get userBaseUrl {
    // if (kIsWeb) return 'http://localhost:8073';
    return 'https://9aad-2401-4900-8fdd-19a5-23cd-429a-2f67-4f06.ngrok-free.app/api/userservice';
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
