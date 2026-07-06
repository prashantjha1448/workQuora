import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../network/dio_client.dart';
import '../constants/api_constants.dart';
import '../utils/error_helper.dart';

// Worker-specific KYC state machine: mobile OTP -> PAN -> Aadhaar -> bank ->
// selfie -> status. Own implementation against the shared kyc* endpoints in
// api_constants.dart (not copied from any other app).
class KycProvider extends ChangeNotifier {
  Map<String, dynamic>? _status;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  Map<String, dynamic>? get status => _status;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  bool get isMobileVerified => _status?['isMobileVerified'] == true;
  bool get isPanVerified => _status?['panVerified'] == true;
  bool get isAadhaarVerified => _status?['aadhaarVerified'] == true;
  bool get isBankVerified => _status?['bankVerified'] == true;
  bool get isSelfieVerified => _status?['selfieVerified'] == true;
  String get overallStatus => _status?['status']?.toString() ?? 'not_submitted';
  bool get isFullyVerified => overallStatus == 'verified';

  Future<void> fetchStatus() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await DioClient.instance.dio.get(ApiConstants.kycStatus);
      _status = res.data['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = ErrorHelper.extract(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendOtp(String mobileNumber) => _submit(
        () => DioClient.instance.dio.post(ApiConstants.kycSendOtp, data: {'mobileNumber': mobileNumber}),
      );

  Future<bool> verifyOtp(String otp) => _submit(
        () => DioClient.instance.dio.post(ApiConstants.kycVerifyOtp, data: {'otp': otp}),
      );

  Future<bool> submitPan(String panNumber, {String? filePath}) => _submit(() async {
        final form = FormData.fromMap({
          'panNumber': panNumber,
          if (filePath != null) 'file': await MultipartFile.fromFile(filePath),
        });
        return DioClient.instance.dio.post(ApiConstants.kycSubmitPan, data: form);
      });

  Future<bool> submitAadhaar(String aadhaarNumber, {String? filePath}) => _submit(() async {
        final form = FormData.fromMap({
          'aadhaarNumber': aadhaarNumber,
          if (filePath != null) 'file': await MultipartFile.fromFile(filePath),
        });
        return DioClient.instance.dio.post(ApiConstants.kycSubmitAadhaar, data: form);
      });

  Future<bool> submitBank({
    required String accountNumber,
    required String ifsc,
    required String holderName,
    String? pin,
    String? filePath,
  }) =>
      _submit(() async {
        final form = FormData.fromMap({
          'accountNumber': accountNumber,
          'ifsc': ifsc,
          'holderName': holderName,
          if (pin != null && pin.isNotEmpty) 'pin': pin,
          if (filePath != null) 'file': await MultipartFile.fromFile(filePath),
        });
        return DioClient.instance.dio.post(ApiConstants.kycSubmitBank, data: form);
      });

  Future<bool> submitSelfie(String filePath) => _submit(() async {
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath),
        });
        return DioClient.instance.dio.post(ApiConstants.kycSubmitSelfie, data: form);
      });

  Future<bool> _submit(Future<Response> Function() request) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await request();
      await fetchStatus();
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHelper.extract(e);
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
