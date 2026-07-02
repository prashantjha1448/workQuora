import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_exception.dart';
import '../data/auth_providers.dart';
import 'auth_controller.dart';

enum RegistrationStep { form, emailOtp, mobileOtp, done }

class RegistrationState {
  const RegistrationState({
    this.step = RegistrationStep.form,
    this.email = '',
    this.isLoading = false,
    this.error,
  });

  final RegistrationStep step;
  final String email;
  final bool isLoading;
  final AppFailure? error;

  RegistrationState copyWith({
    RegistrationStep? step,
    String? email,
    bool? isLoading,
    AppFailure? error,
    bool clearError = false,
  }) {
    return RegistrationState(
      step: step ?? this.step,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RegistrationController extends Notifier<RegistrationState> {
  @override
  RegistrationState build() => const RegistrationState();

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? username,
    String? mobileNumber,
    String role = 'CLIENT',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.register(
      name: name,
      email: email,
      password: password,
      username: username,
      mobileNumber: mobileNumber,
      role: role,
    );
    result.match(
      (failure) => state = state.copyWith(isLoading: false, error: failure),
      (_) => state = state.copyWith(isLoading: false, step: RegistrationStep.emailOtp, email: email),
    );
  }

  Future<void> verifyEmailOtp(String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.verifyRegistration(email: state.email, otp: otp);
    result.match(
      (failure) => state = state.copyWith(isLoading: false, error: failure),
      (_) => state = state.copyWith(isLoading: false, step: RegistrationStep.mobileOtp),
    );
  }

  Future<void> verifyMobileOtp(String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.verifyMobile(email: state.email, otp: otp);
    result.match(
      (failure) => state = state.copyWith(isLoading: false, error: failure),
      (user) {
        state = state.copyWith(isLoading: false, step: RegistrationStep.done);
        ref.read(authControllerProvider.notifier).setUser(user);
      },
    );
  }

  Future<void> resendMobileOtp() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.resendMobileOtp(email: state.email);
  }
}

final registrationControllerProvider = NotifierProvider<RegistrationController, RegistrationState>(
  RegistrationController.new,
);
