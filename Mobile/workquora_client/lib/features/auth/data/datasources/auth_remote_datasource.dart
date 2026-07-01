import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);
  final Dio _dio;

  /// POST /auth/register — sends OTP, no tokens yet.
  Future<String> register({
    required String name,
    required String email,
    required String password,
    String? username,
    String? mobileNumber,
    String role = 'CLIENT',
    String gender = 'OTHER',
  }) async {
    final res = await _dio.post(ApiEndpoints.register, data: {
      'name': name,
      'email': email,
      'password': password,
      if (username != null) 'username': username,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      'role': role,
      'gender': gender,
    });
    return res.data['message'] as String;
  }

  /// POST /auth/verify-registration — verifies email OTP, triggers mobile OTP send.
  Future<String> verifyRegistration({required String email, required String otp}) async {
    final res = await _dio.post(ApiEndpoints.verifyRegistration, data: {'email': email, 'otp': otp});
    return res.data['message'] as String;
  }

  /// POST /auth/verify-mobile — final step, returns full token response.
  Future<AuthSession> verifyMobile({required String email, required String otp}) async {
    final res = await _dio.post(ApiEndpoints.verifyMobile, data: {'email': email, 'otp': otp});
    return AuthSession.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> resendMobileOtp({String? email}) async {
    await _dio.post(ApiEndpoints.sendMobileOtp, data: {if (email != null) 'email': email});
  }

  /// POST /auth/login — accepts email OR username in the `email` field (backend $or query).
  Future<AuthSession> login({required String emailOrUsername, required String password}) async {
    final res = await _dio.post(ApiEndpoints.login, data: {
      'email': emailOrUsername,
      'password': password,
    });
    return AuthSession.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserModel> getMe() async {
    final res = await _dio.get(ApiEndpoints.me);
    return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> logout({String? refreshToken}) async {
    await _dio.post(ApiEndpoints.logout, data: {if (refreshToken != null) 'refreshToken': refreshToken});
  }

  Future<void> logoutAllDevices() async {
    await _dio.post(ApiEndpoints.logoutAll);
  }

  Future<void> forgotPassword({required String email}) async {
    await _dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
  }

  Future<void> resetPassword({required String email, required String otp, required String newPassword}) async {
    await _dio.post(ApiEndpoints.resetPassword, data: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  Future<bool> checkUsernameAvailable(String username) async {
    final res = await _dio.get(ApiEndpoints.checkUsername, queryParameters: {'username': username});
    return res.data['available'] as bool? ?? false;
  }
}

/// Wraps the `{token, refreshToken, user}` shape returned by
/// sendTokenResponse() in authController.js.
class AuthSession {
  const AuthSession({required this.accessToken, required this.refreshToken, required this.user});

  final String accessToken;
  final String refreshToken;
  final UserModel user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      user: UserModel.fromJson((json['user'] ?? json['data']) as Map<String, dynamic>),
    );
  }
}
