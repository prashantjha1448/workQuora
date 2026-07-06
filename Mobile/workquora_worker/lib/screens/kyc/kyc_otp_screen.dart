import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/kyc_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class KycOtpScreen extends StatefulWidget {
  const KycOtpScreen({super.key});
  @override
  State<KycOtpScreen> createState() => _KycOtpScreenState();
}

class _KycOtpScreenState extends State<KycOtpScreen> {
  final _mobileCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final mobile = _mobileCtrl.text.trim();
    if (mobile.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter a valid mobile number'), backgroundColor: AppColors.error));
      return;
    }
    final kyc = context.read<KycProvider>();
    final ok = await kyc.sendOtp(mobile);
    if (!mounted) return;
    if (ok) {
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('OTP sent'), backgroundColor: AppColors.success));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(kyc.error ?? 'Could not send OTP'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty) return;
    final kyc = context.read<KycProvider>();
    final ok = await kyc.verifyOtp(otp);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Mobile verified!'), backgroundColor: AppColors.success));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(kyc.error ?? 'Invalid OTP'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kyc = context.watch<KycProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mobile Verification'), backgroundColor: AppColors.background, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('We\'ll send a 6-digit OTP to verify your mobile number.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          AppTextField(controller: _mobileCtrl, hint: 'Mobile number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          if (!_otpSent)
            AppButton(label: 'Send OTP', loading: kyc.isSubmitting, onPressed: _sendOtp)
          else ...[
            AppTextField(controller: _otpCtrl, hint: 'Enter OTP', icon: Icons.lock_outline, keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            AppButton(label: 'Verify OTP', loading: kyc.isSubmitting, onPressed: _verifyOtp),
            const SizedBox(height: 10),
            TextButton(onPressed: _sendOtp, child: Text('Resend OTP', style: TextStyle(color: AppColors.primary))),
          ],
        ]),
      ),
    );
  }
}
