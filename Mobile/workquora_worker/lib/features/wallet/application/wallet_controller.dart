import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_exception.dart';
import '../data/wallet_providers.dart';
import '../data/models/wallet_model.dart';

class WalletController extends AsyncNotifier<WalletModel?> {
  @override
  Future<WalletModel?> build() => _fetch();

  Future<WalletModel?> _fetch() async {
    final repo = ref.read(walletRepositoryProvider);
    final result = await repo.getBalance();
    return result.match((failure) => throw failure, (wallet) => wallet);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<AppFailure?> addBankAccount({
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    bool isPrimary = false,
  }) async {
    final repo = ref.read(walletRepositoryProvider);
    final result = await repo.addBankAccount(
      bankName: bankName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      isPrimary: isPrimary,
    );
    return result.match((failure) => failure, (_) {
      refresh();
      return null;
    });
  }
}

final walletControllerProvider = AsyncNotifierProvider<WalletController, WalletModel?>(WalletController.new);
