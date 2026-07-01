import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/kyc_status_model.dart';

class KycRemoteDataSource {
  KycRemoteDataSource(this._dio);
  final Dio _dio;

  Future<void> sendOtp(String mobileNumber) =>
      _dio.post(ApiEndpoints.kycOtpSend, data: {'mobileNumber': mobileNumber});

  Future<void> verifyOtp(String otp) => _dio.post(ApiEndpoints.kycOtpVerify, data: {'otp': otp});

  Future<void> submitPan({required String panNumber, File? document}) async {
    final formData = FormData.fromMap({
      'panNumber': panNumber,
      if (document != null) 'file': await MultipartFile.fromFile(document.path),
    });
    await _dio.post(ApiEndpoints.kycPanSubmit, data: formData);
  }

  Future<void> submitAadhaar({required String aadhaarNumber, File? document}) async {
    final formData = FormData.fromMap({
      'aadhaarNumber': aadhaarNumber,
      if (document != null) 'file': await MultipartFile.fromFile(document.path),
    });
    await _dio.post(ApiEndpoints.kycAadhaarSubmit, data: formData);
  }

  /// `pin` here is the wallet withdrawal PIN — this is the ONLY backend
  /// endpoint that sets it (see walletController.withdraw, which requires
  /// it to already exist). There's no separate "set PIN" screen.
  Future<void> submitBank({
    required String accountNumber,
    required String ifsc,
    required String holderName,
    String? pin,
    File? document,
  }) async {
    final formData = FormData.fromMap({
      'accountNumber': accountNumber,
      'ifsc': ifsc,
      'holderName': holderName,
      if (pin != null) 'pin': pin,
      if (document != null) 'file': await MultipartFile.fromFile(document.path),
    });
    await _dio.post(ApiEndpoints.kycBankSubmit, data: formData);
  }

  Future<void> submitSelfie(File selfie) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(selfie.path),
    });
    await _dio.post(ApiEndpoints.kycSelfieSubmit, data: formData);
  }

  Future<KycStatusModel> getStatus() async {
    final res = await _dio.get(ApiEndpoints.kycStatus);
    return KycStatusModel.fromJson(res.data['data'] as Map<String, dynamic>?);
  }
}
