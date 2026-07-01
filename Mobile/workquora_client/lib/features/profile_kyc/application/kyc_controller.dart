import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../core/error/app_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../data/profile_kyc_providers.dart';
import '../data/models/kyc_status_model.dart';

enum KycStep { mobile, pan, aadhaar, bank, selfie, done }

class KycState {
  const KycState({
    this.status = const KycStatusModel(),
    this.isLoadingStatus = true,
    this.isSubmitting = false,
    this.error,
  });

  final KycStatusModel status;
  final bool isLoadingStatus;
  final bool isSubmitting;
  final AppFailure? error;

  KycStep get currentStep {
    if (!status.mobileVerified) return KycStep.mobile;
    if (!status.panVerified) return KycStep.pan;
    if (!status.aadhaarVerified) return KycStep.aadhaar;
    if (!status.bankVerified) return KycStep.bank;
    if (!status.selfieVerified) return KycStep.selfie;
    return KycStep.done;
  }

  KycState copyWith({KycStatusModel? status, bool? isLoadingStatus, bool? isSubmitting, AppFailure? error, bool clearError = false}) {
    return KycState(
      status: status ?? this.status,
      isLoadingStatus: isLoadingStatus ?? this.isLoadingStatus,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class KycController extends Notifier<KycState> {
  @override
  KycState build() {
    Future.microtask(loadStatus);
    return const KycState();
  }

  Future<void> loadStatus() async {
    state = state.copyWith(isLoadingStatus: true, clearError: true);
    final repo = ref.read(kycRepositoryProvider);
    final result = await repo.getStatus();
    result.match(
      (failure) => state = state.copyWith(isLoadingStatus: false, error: failure),
      (status) => state = state.copyWith(isLoadingStatus: false, status: status),
    );
  }

  Future<bool> _run(Future<dynamic> Function() action) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    final repo = ref.read(kycRepositoryProvider);
    final result = await action();
    return result.match(
      (failure) {
        state = state.copyWith(isSubmitting: false, error: failure);
        return false;
      },
      (_) {
        state = state.copyWith(isSubmitting: false);
        loadStatus();
        // KYC status may have just flipped to verified — refresh the
        // app-wide user so the Post Job KYC gate re-checks correctly
        // without the user needing to log out/in.
        ref.read(authControllerProvider.notifier).refreshUser();
        return true;
      },
    );
  }

  Future<bool> sendMobileOtp(String mobileNumber) =>
      _run(() => ref.read(kycRepositoryProvider).sendOtp(mobileNumber));

  Future<bool> verifyMobileOtp(String otp) => _run(() => ref.read(kycRepositoryProvider).verifyOtp(otp));

  Future<bool> submitPan(String panNumber, {File? document}) =>
      _run(() => ref.read(kycRepositoryProvider).submitPan(panNumber: panNumber.toUpperCase(), document: document));

  Future<bool> submitAadhaar(String aadhaarNumber, {File? document}) =>
      _run(() => ref.read(kycRepositoryProvider).submitAadhaar(aadhaarNumber: aadhaarNumber, document: document));

  Future<bool> submitBank({
    required String accountNumber,
    required String ifsc,
    required String holderName,
    String? pin,
    File? document,
  }) =>
      _run(() => ref.read(kycRepositoryProvider).submitBank(
            accountNumber: accountNumber,
            ifsc: ifsc.toUpperCase(),
            holderName: holderName,
            pin: pin,
            document: document,
          ));

  Future<bool> submitSelfie(File selfie) => _run(() => ref.read(kycRepositoryProvider).submitSelfie(selfie));
}

final kycControllerProvider = NotifierProvider<KycController, KycState>(KycController.new);
