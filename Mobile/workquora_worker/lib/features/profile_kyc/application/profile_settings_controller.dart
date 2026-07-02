import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/core_providers.dart';
import '../data/profile_kyc_providers.dart';
import 'profile_controller.dart';

/// Worker profile + settings actions: skills (1–5 enforced), bio/title/name,
/// avatar set/delete, 2FA toggle, and wallet PIN setup. Thin controller that
/// calls the existing repository + a couple of new endpoints, then refreshes
/// the profile so the UI reflects the change immediately.
class ProfileSettingsController {
  ProfileSettingsController(this._ref);
  final Ref _ref;

  Dio get _dio => _ref.read(apiClientProvider).dio;

  Future<void> _refresh() => _ref.read(profileControllerProvider.notifier).refresh();

  /// Enforces: at least 1 skill, at most 5. Returns a failure if violated.
  Future<AppFailure?> updateSkills(List<String> skills) async {
    final cleaned = skills.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    if (cleaned.isEmpty) return AppFailure.fromMessage('Add at least 1 skill.');
    if (cleaned.length > 5) return AppFailure.fromMessage('You can add up to 5 skills only.');
    return _put({'skills': cleaned});
  }

  Future<AppFailure?> updateBasics({String? name, String? bio, String? title}) => _put({
        if (name != null) 'name': name,
        if (bio != null) 'bio': bio,
        if (title != null) 'title': title,
      });

  Future<AppFailure?> setTwoFactor(bool enabled) => _put({'twoFactorEnabled': enabled});

  Future<AppFailure?> _put(Map<String, dynamic> body) async {
    try {
      await _dio.put(ApiEndpoints.profileUpdate, data: body);
      await _refresh();
      return null;
    } on DioException catch (e) {
      return AppFailure.fromMessage(
          (e.response?.data is Map ? e.response?.data['message'] : null) ?? 'Update failed.');
    }
  }

  /// Pick from gallery, upload, refresh.
  Future<AppFailure?> changePhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (x == null) return null; // cancelled
    try {
      final form = FormData.fromMap({
        'photo': await MultipartFile.fromFile(x.path, filename: 'avatar.jpg'),
      });
      await _dio.post(ApiEndpoints.profilePhoto, data: form);
      await _refresh();
      return null;
    } on DioException catch (e) {
      return AppFailure.fromMessage(
          (e.response?.data is Map ? e.response?.data['message'] : null) ?? 'Photo upload failed.');
    }
  }

  Future<AppFailure?> deletePhoto() async {
    try {
      await _dio.delete(ApiEndpoints.profilePhotoDelete);
      await _refresh();
      return null;
    } on DioException catch (e) {
      return AppFailure.fromMessage(
          (e.response?.data is Map ? e.response?.data['message'] : null) ?? 'Could not remove photo.');
    }
  }

  /// Set or change the wallet withdrawal PIN. [oldPin] required only if one
  /// already exists (backend enforces).
  Future<AppFailure?> setWalletPin({required String pin, String? oldPin}) async {
    try {
      await _dio.post(ApiEndpoints.walletSetPin, data: {'pin': pin, if (oldPin != null) 'oldPin': oldPin});
      return null;
    } on DioException catch (e) {
      return AppFailure.fromMessage(
          (e.response?.data is Map ? e.response?.data['message'] : null) ?? 'Could not set PIN.');
    }
  }

  /// Verify PIN to reveal wallet balance (PIN-gated view).
  Future<bool> verifyWalletPin(String pin) async {
    try {
      final res = await _dio.post(ApiEndpoints.walletVerifyPin, data: {'pin': pin});
      return res.data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}

final profileSettingsControllerProvider =
    Provider<ProfileSettingsController>((ref) => ProfileSettingsController(ref));
