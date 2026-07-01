import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/wallet_model.dart';

class BankAccountTile extends StatelessWidget {
  const BankAccountTile({super.key, required this.account});
  final BankAccountModel account;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.bankName, style: textTheme.bodyLarge),
                  Text(account.accountEnding, style: textTheme.labelSmall?.copyWith(color: AppColors.outline)),
                ],
              ),
            ),
            if (account.isPrimary)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(8)),
                child: Text('Primary', style: textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}
