import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_exception.dart';
import '../../data/models/talent_model.dart';

abstract class DiscoverRepository {
  Future<Either<AppFailure, List<TalentModel>>> searchTalent({
    required double lat,
    required double lng,
    double radius,
    String? category,
    String? keyword,
  });
}
