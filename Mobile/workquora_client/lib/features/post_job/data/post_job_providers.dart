import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/core_providers.dart';
import '../data/datasources/post_job_remote_datasource.dart';
import '../data/repositories/post_job_repository_impl.dart';
import '../domain/repositories/post_job_repository.dart';

final postJobRemoteDataSourceProvider = Provider<PostJobRemoteDataSource>((ref) {
  return PostJobRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final postJobRepositoryProvider = Provider<PostJobRepository>((ref) {
  return PostJobRepositoryImpl(ref.watch(postJobRemoteDataSourceProvider));
});
