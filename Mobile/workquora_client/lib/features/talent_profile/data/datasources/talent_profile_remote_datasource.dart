import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/review_model.dart';
import '../models/talent_profile_model.dart';

class TalentProfileRemoteDataSource {
  TalentProfileRemoteDataSource(this._dio);
  final Dio _dio;

  Future<TalentProfileModel> getPublicProfile(String userId) async {
    final res = await _dio.get(ApiEndpoints.publicProfile(userId));
    return TalentProfileModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<ReviewModel>> getReviews(String userId) async {
    final res = await _dio.get(ApiEndpoints.userReviews(userId));
    final list = res.data['data'] as List;
    return list.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
