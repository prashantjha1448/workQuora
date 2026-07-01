import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/storage/hive_service.dart';
import '../../domain/repositories/discover_repository.dart';
import '../datasources/discover_remote_datasource.dart';
import '../models/talent_model.dart';

class DiscoverRepositoryImpl implements DiscoverRepository {
  DiscoverRepositoryImpl(this._remote);
  final DiscoverRemoteDataSource _remote;

  String _cacheKey(String? category, String? keyword) => 'nearby_${category ?? 'All'}_${keyword ?? ''}';

  @override
  Future<Either<AppFailure, List<TalentModel>>> searchTalent({
    required double lat,
    required double lng,
    double radius = 25,
    String? category,
    String? keyword,
  }) async {
    final box = Hive.box(HiveBoxes.talentList);
    final cacheKey = _cacheKey(category, keyword);

    try {
      final results = await _remote.getNearbyFreelancers(
        lat: lat,
        lng: lng,
        radius: radius,
        category: category,
        keyword: keyword,
      );
      // Cache as raw JSON strings — cheap to store/restore, avoids needing
      // Hive type adapters for every model.
      await box.put(cacheKey, jsonEncode(results.map((t) => _toJsonLite(t)).toList()));
      return Right(results);
    } on DioException catch (e) {
      final cached = box.get(cacheKey) as String?;
      if (cached != null) {
        final list = (jsonDecode(cached) as List).cast<Map<String, dynamic>>();
        return Right(list.map(TalentModel.fromJson).toList());
      }
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return Left(AppFailure.network());
      }
      final message = (e.response?.data is Map) ? e.response?.data['message'] as String? : null;
      return Left(AppFailure.fromMessage(message ?? 'Could not load talent. Please try again.'));
    } catch (_) {
      return Left(AppFailure.fromMessage('Unexpected error loading talent.'));
    }
  }

  Map<String, dynamic> _toJsonLite(TalentModel t) => {
        '_id': t.id,
        'name': t.name,
        'title': t.title,
        'avatar': t.avatar,
        'skills': t.skills,
        'hourlyRate': t.hourlyRate,
        'averageRating': t.averageRating,
        'totalJobsCompleted': t.totalJobsCompleted,
        'distance': t.distance,
        'isVerified': t.isVerified,
        'isAvailable': t.isAvailable,
        'availabilityStatus': t.availabilityStatus,
      };
}
