import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  // In-memory fallback for insecure web contexts (HTTP)
  static String? _memAccessToken;
  static String? _memRefreshToken;

  /// Returns true when running on the web over a non-secure (HTTP) origin,
  /// where FlutterSecureStorage is unavailable.
  static bool get _useMemoryFallback {
    if (!kIsWeb) return false;
    // ignore: undefined_prefixed_name
    final origin = Uri.base.origin;
    return origin.startsWith('http://');
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (_useMemoryFallback) {
      _memAccessToken = accessToken;
      _memRefreshToken = refreshToken;
      return;
    }
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<String?> getAccessToken() async {
    if (_useMemoryFallback) return _memAccessToken;
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    if (_useMemoryFallback) return _memRefreshToken;
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    if (_useMemoryFallback) {
      _memAccessToken = null;
      _memRefreshToken = null;
      return;
    }
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  static Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
