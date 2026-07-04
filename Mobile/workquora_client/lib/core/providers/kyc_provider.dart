import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../network/dio_client.dart';
import '../constants/api_constants.dart';

class KycProvider extends ChangeNotifier {
  Map<String, dynamic>? _kycData;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get status => _kycData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Overall KYC status — 'not_submitted' when no Kyc record exists yet
  // (GET /kyc/status returns { data: null } in that case).
  String get kycStatus => _kycData?['status'] ?? 'not_submitted';

  bool get isMobileVerified => _kycData?['isMobileVerified'] ?? false;
  bool get isPanVerified => _kycData?['panVerified'] ?? false;
  bool get isAadhaarVerified => _kycData?['aadhaarVerified'] ?? false;
  bool get isBankVerified => _kycData?['bankVerified'] ?? false;
  bool get isSelfieVerified => _kycData?['selfieVerified'] ?? false;
  bool get isFullyVerified => kycStatus == 'verified';

  Future<void> fetchStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await DioClient.instance.dio.get(ApiConstants.kycStatus);
      // { success: true, data: <Kyc document, or null if none exists yet> }
      _kycData = res.data['data'];
    } catch (e) {
      _error = _extractError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  // POST /kyc/otp/send — requires { mobileNumber }, not empty-bodied.
  Future<bool> sendMobileOtp(String mobileNumber) async {
    try {
      await DioClient.instance.dio.post(ApiConstants.kycSendOtp, data: {'mobileNumber': mobileNumber});
      return true;
    } catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyMobileOtp(String otp) async {
    try {
      await DioClient.instance.dio.post(ApiConstants.kycVerifyOtp, data: {'otp': otp});
      await fetchStatus();
      return true;
    } catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  // PAN — panNumber (text) + file (optional on the backend, but the mobile
  // UI requires it so a document is always attached in practice).
  Future<bool> submitPan({required String panNumber, required String filePath}) async {
    try {
      final formData = FormData.fromMap({
        'panNumber': panNumber,
        'file': await MultipartFile.fromFile(filePath),
      });
      await DioClient.instance.dio.post(ApiConstants.kycSubmitPan, data: formData);
      await fetchStatus();
      return true;
    } catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  // Aadhaar — aadhaarNumber (text) + file.
  Future<bool> submitAadhaar({required String aadhaarNumber, required String filePath}) async {
    try {
      final formData = FormData.fromMap({
        'aadhaarNumber': aadhaarNumber,
        'file': await MultipartFile.fromFile(filePath),
      });
      await DioClient.instance.dio.post(ApiConstants.kycSubmitAadhaar, data: formData);
      await fetchStatus();
      return true;
    } catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  // Bank — real backend fields are accountNumber, ifsc, holderName (verified
  // from kycController.submitBank's destructure) — not ifscCode/accountHolderName.
  Future<bool> submitBank({
    required String accountNumber,
    required String ifsc,
    required String holderName,
    String? filePath,
  }) async {
    try {
      final fields = <String, dynamic>{
        'accountNumber': accountNumber,
        'ifsc': ifsc,
        'holderName': holderName,
      };
      if (filePath != null) {
        fields['file'] = await MultipartFile.fromFile(filePath);
      }
      final formData = FormData.fromMap(fields);
      await DioClient.instance.dio.post(ApiConstants.kycSubmitBank, data: formData);
      await fetchStatus();
      return true;
    } catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  // Selfie — file is mandatory on the backend (400 if missing).
  Future<bool> submitSelfie(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      await DioClient.instance.dio.post(ApiConstants.kycSubmitSelfie, data: formData);
      await fetchStatus();
      return true;
    } catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  String _extractError(dynamic e) {
    if (e is DioException) {
      return e.response?.data?['message'] ?? 'Something went wrong';
    }
    return e.toString();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
