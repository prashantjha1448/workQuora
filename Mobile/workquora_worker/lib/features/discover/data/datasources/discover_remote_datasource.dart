import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/talent_model.dart';

class DiscoverRemoteDataSource {
  DiscoverRemoteDataSource(this._dio);
  final Dio _dio;

  /// Backend does NOT paginate this endpoint yet (no page/limit support in
  /// getNearbyFreelancers). We still pass radius/category/keyword to keep
  /// the result set as small as possible server-side until pagination ships.
  Future<List<TalentModel>> getNearbyFreelancers({
    required double lat,
    required double lng,
    double radius = 25,
    String? category,
    String? keyword,
  }) async {
    final res = await _dio.get(ApiEndpoints.nearbyFreelancers, queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
      if (category != null && category != 'All') 'category': category,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
    });
    final list = (res.data['freelancers'] ?? res.data['data']) as List;
    return list.map((e) => TalentModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
