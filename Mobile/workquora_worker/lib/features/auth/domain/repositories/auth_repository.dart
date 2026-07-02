import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_exception.dart';
import '../../data/models/user_model.dart';

typedef AuthResult<T> = Future<Either<AppFailure, T>>;

abstract class AuthRepository {
  AuthResult<String> register({
    required String name,
    required String email,
    required String password,
    String? username,
    String? mobileNumber,
    String role,
  });

  AuthResult<String> verifyRegistration({required String email, required String otp});
  AuthResult<UserModel> verifyMobile({required String email, required String otp});
  AuthResult<void> resendMobileOtp({String? email});
  AuthResult<UserModel> login({required String emailOrUsername, required String password});
  AuthResult<UserModel> getCurrentUser();
  AuthResult<void> logout();
  AuthResult<void> forgotPassword({required String email});
  AuthResult<void> resetPassword({required String email, required String otp, required String newPassword});
  AuthResult<bool> checkUsernameAvailable(String username);
  Future<bool> hasActiveSession();
}
