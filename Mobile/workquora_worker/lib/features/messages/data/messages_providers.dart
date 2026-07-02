import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/core_providers.dart';
import '../data/datasources/messages_remote_datasource.dart';
import '../data/repositories/messages_repository_impl.dart';
import '../domain/repositories/messages_repository.dart';

final messagesRemoteDataSourceProvider = Provider<MessagesRemoteDataSource>((ref) {
  return MessagesRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepositoryImpl(ref.watch(messagesRemoteDataSourceProvider));
});
