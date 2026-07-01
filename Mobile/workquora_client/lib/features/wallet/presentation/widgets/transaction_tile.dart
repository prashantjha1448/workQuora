import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/wallet_transaction_model.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});
  final WalletTransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isCredit = transaction.isCredit;
    final statusColor = switch (transaction.status) {
      'completed' => AppColors.secondary,
      'pending' => AppColors.promoOrange,
      'failed' => AppColors.error,
      _ => AppColors.outline,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCredit ? AppColors.secondaryContainer : AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 18,
              color: isCredit ? AppColors.secondary : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description.isNotEmpty ? transaction.description : transaction.source,
                  style: textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat.yMMMd().format(transaction.createdAt),
                  style: textTheme.labelSmall?.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}\u20b9${transaction.amountRupees.toStringAsFixed(2)}',
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 14,
                  color: isCredit ? AppColors.secondary : AppColors.onSurface,
                ),
              ),
              Text(
                transaction.status,
                style: textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
