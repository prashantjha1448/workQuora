import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/transactions_controller.dart';
import '../../application/wallet_controller.dart';
import '../widgets/add_bank_account_sheet.dart';
import '../widgets/add_money_sheet.dart';
import '../widgets/bank_account_tile.dart';
import '../widgets/transaction_tile.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        ref.read(transactionsControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletControllerProvider);
    final txState = ref.watch(transactionsControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(walletControllerProvider.notifier).refresh();
            await ref.read(transactionsControllerProvider.notifier).refresh();
          },
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.containerMargin),
            children: [
              walletAsync.when(
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _BalanceError(
                  message: error.toString(),
                  onRetry: () => ref.read(walletControllerProvider.notifier).refresh(),
                ),
                data: (wallet) => wallet == null
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BalanceCard(formattedBalance: wallet.formattedBalance, currency: wallet.currency),
                          const SizedBox(height: AppSpacing.stackLg),
                          Row(
                            children: [
                              Text('Payment Methods', style: textTheme.headlineSmall),
                              const Spacer(),
                              TextButton(
                                onPressed: () => AddBankAccountSheet.show(context),
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.stackSm),
                          if (wallet.bankAccounts.isEmpty)
                            Text(
                              'No payment methods added yet.',
                              style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                            )
                          else
                            ...wallet.bankAccounts.map((b) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
                                  child: BankAccountTile(account: b),
                                )),
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Text('Recent Transactions', style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.stackSm),
              if (txState.isLoading && txState.transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (txState.transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No transactions yet.',
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding),
                    child: Column(
                      children: [
                        for (final tx in txState.transactions) ...[
                          TransactionTile(transaction: tx),
                          if (tx != txState.transactions.last) const Divider(height: 1),
                        ],
                        if (txState.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddMoneySheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Deposit'),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.formattedBalance, required this.currency});
  final num formattedBalance;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TOTAL AVAILABLE BALANCE',
                style: textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.75), letterSpacing: 0.6),
              ),
              const Spacer(),
              const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\u20b9${formattedBalance.toStringAsFixed(2)}',
            style: textTheme.displayLarge?.copyWith(color: Colors.white, fontSize: 36),
          ),
        ],
      ),
    );
  }
}

class _BalanceError extends StatelessWidget {
  const _BalanceError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.stackSm),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
