import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/core_providers.dart';
import '../data/datasources/wallet_remote_datasource.dart';
import '../data/repositories/wallet_repository_impl.dart';
import '../domain/repositories/wallet_repository.dart';

final walletRemoteDataSourceProvider = Provider<WalletRemoteDataSource>((ref) {
  return WalletRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(ref.watch(walletRemoteDataSourceProvider));
});
