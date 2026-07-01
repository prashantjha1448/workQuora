import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/core_providers.dart';
import '../data/datasources/talent_profile_remote_datasource.dart';
import '../data/repositories/talent_profile_repository_impl.dart';
import '../domain/repositories/talent_profile_repository.dart';

final talentProfileRemoteDataSourceProvider = Provider<TalentProfileRemoteDataSource>((ref) {
  return TalentProfileRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final talentProfileRepositoryProvider = Provider<TalentProfileRepository>((ref) {
  return TalentProfileRepositoryImpl(ref.watch(talentProfileRemoteDataSourceProvider));
});

/// `.family` keyed by userId — autoDispose so a profile fetched once isn't
/// held in memory forever as the user browses many talent cards; Riverpod
/// drops it shortly after the screen is popped and no longer watched.
final talentProfileProvider =
    FutureProvider.autoDispose.family<TalentProfileBundle, String>((ref, userId) async {
  final repo = ref.watch(talentProfileRepositoryProvider);
  final result = await repo.getProfileBundle(userId);
  return result.match((failure) => throw failure, (bundle) => bundle);
});
