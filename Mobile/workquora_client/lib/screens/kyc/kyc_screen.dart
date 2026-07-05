import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/kyc_provider.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});
  @override State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<KycProvider>().fetchStatus());
  }

  double _calculateProgress(KycProvider kyc) {
    int done = 0;
    if (kyc.isMobileVerified) done++;
    if (kyc.isPanVerified) done++;
    if (kyc.isAadhaarVerified) done++;
    if (kyc.isBankVerified) done++;
    if (kyc.isSelfieVerified) done++;
    return done / 5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('KYC Verification'), backgroundColor: AppColors.bg, elevation: 0),
      body: Consumer<KycProvider>(
        builder: (ctx, kyc, _) {
          if (kyc.isLoading && kyc.status == null) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final progress = _calculateProgress(kyc);

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () => kyc.fetchStatus(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _StatusBanner(status: kyc.kycStatus),
                const SizedBox(height: 24),

                Text('Verification Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceAlt,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${(progress * 100).round()}% complete', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 24),

                _KycStepTile(
                  step: 1,
                  title: 'Mobile Verification',
                  subtitle: 'Verify your mobile number via OTP',
                  isCompleted: kyc.isMobileVerified,
                  isLocked: false,
                  onTap: kyc.isMobileVerified ? null : () => context.push('/kyc/mobile-otp'),
                ),
                _KycStepTile(
                  step: 2,
                  title: 'PAN Card',
                  subtitle: 'Upload your PAN card document',
                  isCompleted: kyc.isPanVerified,
                  isLocked: !kyc.isMobileVerified,
                  onTap: (kyc.isMobileVerified && !kyc.isPanVerified) ? () => context.push('/kyc/pan') : null,
                ),
                _KycStepTile(
                  step: 3,
                  title: 'Aadhaar Card',
                  subtitle: 'Upload your Aadhaar document',
                  isCompleted: kyc.isAadhaarVerified,
                  isLocked: !kyc.isMobileVerified,
                  onTap: (kyc.isMobileVerified && !kyc.isAadhaarVerified) ? () => context.push('/kyc/aadhaar') : null,
                ),
                _KycStepTile(
                  step: 4,
                  title: 'Bank Account',
                  subtitle: 'Add your bank account details',
                  isCompleted: kyc.isBankVerified,
                  isLocked: !(kyc.isPanVerified && kyc.isAadhaarVerified),
                  onTap: (kyc.isPanVerified && kyc.isAadhaarVerified && !kyc.isBankVerified) ? () => context.push('/kyc/bank') : null,
                ),
                _KycStepTile(
                  step: 5,
                  title: 'Selfie Verification',
                  subtitle: 'Take a selfie for identity confirmation',
                  isCompleted: kyc.isSelfieVerified,
                  isLocked: !kyc.isBankVerified,
                  onTap: (kyc.isBankVerified && !kyc.isSelfieVerified) ? () => context.push('/kyc/selfie') : null,
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'KYC verification is required to post jobs and receive payments. '
                        'Documents are reviewed by our team within 24 hours.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final IconData icon;
    late final String message;

    switch (status) {
      case 'verified':
        color = AppColors.emerald;
        icon = Icons.verified;
        message = 'KYC Verified! You can now post jobs';
        break;
      case 'rejected':
        color = AppColors.error;
        icon = Icons.error_outline;
        message = 'Verification failed. Please resubmit documents.';
        break;
      case 'pending':
        color = AppColors.warning;
        icon = Icons.hourglass_top;
        message = 'Under review — our team will verify within 24h';
        break;
      default:
        color = AppColors.primary;
        icon = Icons.info_outline;
        message = 'Complete all 5 steps to get verified';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }
}

class _KycStepTile extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isLocked;
  final VoidCallback? onTap;

  const _KycStepTile({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isCompleted ? AppColors.emerald : (isLocked ? AppColors.border : AppColors.primary);

    return Opacity(
      opacity: isLocked ? 0.5 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor.withOpacity(isCompleted ? 0.5 : 0.3)),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.emerald.withOpacity(0.15) : AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? Icon(Icons.check, color: AppColors.emerald, size: 18)
                    : Text('$step', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ])),
            Icon(
              isLocked ? Icons.lock_outline : (isCompleted ? Icons.check_circle : Icons.chevron_right),
              color: isCompleted ? AppColors.emerald : AppColors.textMuted,
              size: 20,
            ),
          ]),
        ),
      ),
    );
  }
}
