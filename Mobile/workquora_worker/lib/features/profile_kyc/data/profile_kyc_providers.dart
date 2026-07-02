import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/core_providers.dart';
import '../data/datasources/kyc_remote_datasource.dart';
import '../data/datasources/profile_remote_datasource.dart';
import '../data/repositories/profile_kyc_repository_impl.dart';
import '../domain/repositories/profile_kyc_repository.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider));
});

final kycRemoteDataSourceProvider = Provider<KycRemoteDataSource>((ref) {
  return KycRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final kycRepositoryProvider = Provider<KycRepository>((ref) {
  return KycRepositoryImpl(ref.watch(kycRemoteDataSourceProvider));
});
