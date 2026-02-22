import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_service.g.dart';

@RestApi()
abstract class AuthService {
  factory AuthService(Dio dio, {String baseUrl}) = _AuthService;

  @POST('/api/v1/auth/login')
  Future<AuthResponse> login(@Body() AuthRequest request);

  @POST('/api/v1/auth/register')
  Future<UserResponse> register(@Body() RegisterRequest request);
}

class AuthRequest {
  final String usernameOrEmail;
  final String password;

  AuthRequest({required this.usernameOrEmail, required this.password});

  Map<String, dynamic> toJson() => {
    'usernameOrEmail': usernameOrEmail,
    'password': password,
  };
}

class RegisterRequest {
  final String email;
  final String username;
  final String password;

  RegisterRequest({
    required this.email,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'username': username,
    'password': password,
  };
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;

  AuthResponse({required this.accessToken, required this.refreshToken});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // The API might wrap in an ApiResponse layer, checking that based on docs
    final data = json['data'] ?? json;
    return AuthResponse(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );
  }
}

class UserResponse {
  final int id;
  final String email;
  final String username;

  UserResponse({required this.id, required this.email, required this.username});

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return UserResponse(
      id: data['id'],
      email: data['email'],
      username: data['username'],
    );
  }
}
