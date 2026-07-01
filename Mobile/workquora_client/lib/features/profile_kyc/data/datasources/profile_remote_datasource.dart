import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/profile_model.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._dio);
  final Dio _dio;

  Future<ProfileModel> getProfile() async {
    final res = await _dio.get(ApiEndpoints.profileMe);
    return ProfileModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> updateProfile({String? name, String? bio, String? title}) async {
    await _dio.put(ApiEndpoints.profileUpdate, data: {
      if (name != null) 'name': name,
      if (bio != null) 'bio': bio,
      if (title != null) 'title': title,
    });
  }
}
