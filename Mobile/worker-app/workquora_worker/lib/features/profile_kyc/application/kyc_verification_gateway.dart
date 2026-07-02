import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_exception.dart';
import '../data/profile_kyc_providers.dart';

/// Verification gateway — the seam where MANUAL (admin) verification today can
/// be swapped for AUTOMATED verification (DigiLocker / UIDAI for Aadhaar+PAN,
/// bank penny-drop) later WITHOUT changing any KYC screen code.
///
/// Today [ManualGateway] just submits documents; the backend marks them
/// `pending` and a human admin approves. When automation is ready, add e.g.
/// `DigiLockerGateway implements KycGateway` that calls the DigiLocker/UIDAI
/// flow and returns instantly-verified, then flip the provider below — the UI
/// keeps calling `gateway.submitPan(...)` etc. and never changes.
///
/// Plan (per product): manual until ~1000 users, then switch the provider to
/// the automated gateway. Mobile OTP step is disabled for now (kept in backend
/// for the future).
abstract class KycGateway {
  Future<AppFailure?> submitPan({required String panNumber, File? document});
  Future<AppFailure?> submitAadhaar({required String aadhaarNumber, File? document});
  Future<AppFailure?> submitBank({
    required String accountNumber,
    required String ifscCode,
    required String accountHolderName,
    File? document,
  });

  /// Whether this gateway verifies instantly (automation) or needs admin review.
  bool get isInstant;
}

class ManualGateway implements KycGateway {
  ManualGateway(this._ref);
  final Ref _ref;

  @override
  bool get isInstant => false; // admin reviews manually

  @override
  Future<AppFailure?> submitPan({required String panNumber, File? document}) async {
    final result = await _ref.read(kycRepositoryProvider).submitPan(panNumber: panNumber, document: document);
    return result.match((f) => f, (_) => null);
  }

  @override
  Future<AppFailure?> submitAadhaar({required String aadhaarNumber, File? document}) async {
    final result = await _ref
        .read(kycRepositoryProvider)
        .submitAadhaar(aadhaarNumber: aadhaarNumber, document: document);
    return result.match((f) => f, (_) => null);
  }

  @override
  Future<AppFailure?> submitBank({
    required String accountNumber,
    required String ifscCode,
    required String accountHolderName,
    File? document,
  }) async {
    final result = await _ref.read(kycRepositoryProvider).submitBank(
          accountNumber: accountNumber,
          ifsc: ifscCode,
          holderName: accountHolderName,
          document: document,
        );
    return result.match((f) => f, (_) => null);
  }
}

/// Swap this single line to go automated later:
///   return DigiLockerGateway(ref);
final kycGatewayProvider = Provider<KycGateway>((ref) => ManualGateway(ref));
