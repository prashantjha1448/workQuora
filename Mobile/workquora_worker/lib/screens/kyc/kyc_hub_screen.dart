import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/kyc_provider.dart';

// Entry point for the worker KYC flow (route /kyc) — shows a checklist of
// each verification step and its status, and links into the step screens.
class KycHubScreen extends StatefulWidget {
  const KycHubScreen({super.key});
  @override
  State<KycHubScreen> createState() => _KycHubScreenState();
}

class _KycHubScreenState extends State<KycHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<KycProvider>().fetchStatus());
  }

  @override
  Widget build(BuildContext context) {
    final kyc = context.watch<KycProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('KYC Verification'), backgroundColor: AppColors.background, elevation: 0),
      body: kyc.isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: kyc.fetchStatus,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: (kyc.isFullyVerified ? AppColors.success : AppColors.warning).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: (kyc.isFullyVerified ? AppColors.success : AppColors.warning).withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Icon(kyc.isFullyVerified ? Icons.verified : Icons.hourglass_top_rounded, color: kyc.isFullyVerified ? AppColors.success : AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          kyc.isFullyVerified ? 'Your account is fully verified!' : 'Complete all steps below to start earning',
                          style: TextStyle(color: kyc.isFullyVerified ? AppColors.success : AppColors.warning, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  _step(context, 'Mobile Verification', 'Verify your mobile number via OTP', Icons.sms_outlined, kyc.isMobileVerified, () => context.push('/kyc/otp')),
                  _step(context, 'PAN Card', 'Submit your PAN details', Icons.badge_outlined, kyc.isPanVerified, () => context.push('/kyc/pan')),
                  _step(context, 'Aadhaar Card', 'Submit your Aadhaar details', Icons.credit_card_outlined, kyc.isAadhaarVerified, () => context.push('/kyc/aadhaar')),
                  _step(context, 'Bank Details', 'Link a bank account for withdrawals', Icons.account_balance_outlined, kyc.isBankVerified, () => context.push('/kyc/bank')),
                  _step(context, 'Selfie', 'Take a quick selfie to confirm identity', Icons.face_retouching_natural, kyc.isSelfieVerified, () => context.push('/kyc/selfie')),
                ],
              ),
            ),
    );
  }

  Widget _step(BuildContext context, String title, String subtitle, IconData icon, bool done, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: done ? null : onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: (done ? AppColors.success : AppColors.primary).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(done ? Icons.check : icon, color: done ? AppColors.success : AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(done ? 'Verified' : subtitle, style: TextStyle(color: done ? AppColors.success : AppColors.textSecondary, fontSize: 12)),
                ]),
              ),
              if (!done) Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ]),
          ),
        ),
      ),
    );
  }
}
