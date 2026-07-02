import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Displays the Uber-style earnings breakdown for a completed job:
/// gross → platform fee → GST on fee → net payout. Reads the `breakdown`
/// object stored on the payout transaction (see BACKEND_fee_gst_patch). If a
/// transaction has no breakdown (older records), it renders nothing.
class SettlementBreakdown extends StatelessWidget {
  const SettlementBreakdown({super.key, required this.breakdown});

  /// The `breakdown` map from the transaction:
  /// {gross, platformFee, platformFeePercent, gstPercent, gstOnFee,
  ///  totalDeduction, netPayout}
  final Map<String, dynamic> breakdown;

  @override
  Widget build(BuildContext context) {
    final tt = AppTypography.light;
    final inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    num n(String k) => (breakdown[k] as num?) ?? 0;

    Widget row(String label, num value, {bool negative = false, bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: (bold ? tt.bodyLarge : tt.bodyMedium)?.copyWith(
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                      color: bold ? AppColors.onSurface : AppColors.onSurfaceVariant)),
              Text('${negative ? '−' : ''}${inr.format(value)}',
                  style: (bold ? tt.bodyLarge : tt.bodyMedium)?.copyWith(
                      fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                      color: negative
                          ? AppColors.error
                          : (bold ? AppColors.primary : AppColors.onSurface))),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.lgR,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Earnings Breakdown',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          row('Job Amount', n('gross')),
          row('Platform Fee (${n('platformFeePercent')}%)', n('platformFee'), negative: true),
          row('GST on fee (${n('gstPercent')}%)', n('gstOnFee'), negative: true),
          const Divider(height: 20),
          row('You Receive', n('netPayout'), bold: true),
          const SizedBox(height: 8),
          Text(
            'Platform fee + GST are deducted from the job amount, like other on-demand platforms.',
            style: tt.labelSmall?.copyWith(color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}

/// Client-side PREVIEW calculator — lets the worker see, before accepting,
/// roughly what they'll take home. Mirrors the backend formula
/// (GST charged on the platform fee, not the whole amount). Backend remains
/// the source of truth at settlement.
class FeePreview {
  const FeePreview({
    required this.gross,
    required this.platformFee,
    required this.gstOnFee,
    required this.netPayout,
  });

  final double gross;
  final double platformFee;
  final double gstOnFee;
  final double netPayout;

  factory FeePreview.estimate(
    double gross, {
    double platformFeePercent = 10,
    double gstPercent = 18,
  }) {
    final fee = double.parse((gross * platformFeePercent / 100).toStringAsFixed(2));
    final gst = double.parse((fee * gstPercent / 100).toStringAsFixed(2));
    final net = double.parse((gross - fee - gst).toStringAsFixed(2));
    return FeePreview(gross: gross, platformFee: fee, gstOnFee: gst, netPayout: net);
  }
}
