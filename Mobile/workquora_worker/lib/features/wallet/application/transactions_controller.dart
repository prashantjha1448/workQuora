import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_exception.dart';
import '../data/wallet_providers.dart';
import '../data/models/wallet_transaction_model.dart';

class TransactionsState {
  const TransactionsState({
    this.transactions = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<WalletTransactionModel> transactions;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final AppFailure? error;

  TransactionsState copyWith({
    List<WalletTransactionModel>? transactions,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    AppFailure? error,
    bool clearError = false,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TransactionsController extends Notifier<TransactionsState> {
  @override
  TransactionsState build() {
    Future.microtask(refresh);
    return const TransactionsState();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(walletRepositoryProvider);
    final result = await repo.getTransactions(page: 1);
    result.match(
      (failure) => state = state.copyWith(isLoading: false, error: failure),
      (page) => state = state.copyWith(
        isLoading: false,
        transactions: page.transactions,
        page: page.page,
        hasMore: page.hasMore,
      ),
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    final repo = ref.read(walletRepositoryProvider);
    final result = await repo.getTransactions(page: state.page + 1);
    result.match(
      (failure) => state = state.copyWith(isLoadingMore: false, error: failure),
      (page) => state = state.copyWith(
        isLoadingMore: false,
        transactions: [...state.transactions, ...page.transactions],
        page: page.page,
        hasMore: page.hasMore,
      ),
    );
  }
}

final transactionsControllerProvider = NotifierProvider<TransactionsController, TransactionsState>(
  TransactionsController.new,
);
