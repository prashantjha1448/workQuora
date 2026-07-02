import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/core_providers.dart';
import '../data/datasources/discover_remote_datasource.dart';
import '../data/repositories/discover_repository_impl.dart';
import '../domain/repositories/discover_repository.dart';

final discoverRemoteDataSourceProvider = Provider<DiscoverRemoteDataSource>((ref) {
  return DiscoverRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final discoverRepositoryProvider = Provider<DiscoverRepository>((ref) {
  return DiscoverRepositoryImpl(ref.watch(discoverRemoteDataSourceProvider));
});
