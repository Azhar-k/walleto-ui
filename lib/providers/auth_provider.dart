import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../services/auth_service.dart';

final userDioProvider = Provider<Dio>((ref) {
  return ApiClient.getUserClient();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(userDioProvider);
  return AuthService(dio);
});
