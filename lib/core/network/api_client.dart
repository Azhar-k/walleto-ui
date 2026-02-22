import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_interceptor.dart';

class ApiClient {
  static const String coreBaseUrl = 'http://10.0.2.2:8080'; // 10.0.2.2 is loopback for Android emulator
  static const String userBaseUrl = 'http://10.0.2.2:8073';

  static Dio getCoreClient() {
    final dio = Dio(BaseOptions(
      baseUrl: coreBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    dio.interceptors.add(AuthInterceptor());
    
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
    
    return dio;
  }
  
  static Dio getUserClient() {
    final dio = Dio(BaseOptions(
      baseUrl: userBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
    
    return dio;
  }
}
