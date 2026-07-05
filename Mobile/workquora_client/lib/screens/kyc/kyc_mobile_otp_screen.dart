import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/kyc_provider.dart';
import '../../widgets/app_button.dart';

class KycMobileOtpScreen extends StatefulWidget {
  const KycMobileOtpScreen({super.key});
  @override State<KycMobileOtpScreen> createState() => _KycMobileOtpScreenState();
}

class _KycMobileOtpScreenState extends State<KycMobileOtpScreen> {
  final _pinCtrl = TextEditingController();
  bool _verifying = false;
  int _secondsLeft = 60;
  Timer? _timer;

  String get _mobileNumber => context.read<AuthProvider>().user?['mobileNumber']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp(showToast: false));
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _sendOtp({bool showToast = true}) async {
    if (_mobileNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No mobile number on file — add one in Edit Profile first'), backgroundColor: AppColors.error));
      }
      return;
    }
    final ok = await context.read<KycProvider>().sendMobileOtp(_mobileNumber);
    if (!mounted) return;
    if (ok) {
      _startCountdown();
      if (showToast) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP resent'), backgroundColor: AppColors.success));
    } else {
      final err = context.read<KycProvider>().error ?? 'Failed to send OTP';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    }
  }

  Future<void> _verify(String otp) async {
    if (otp.length != 6 || _verifying) return;
    setState(() => _verifying = true);
    final ok = await context.read<KycProvider>().verifyMobileOtp(otp);
    if (!mounted) return;
    setState(() => _verifying = false);
    if (ok) {
      context.pop();
    } else {
      _pinCtrl.clear();
      final err = context.read<KycProvider>().error ?? 'Invalid OTP';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    }
  }

  @override
  void dispose() { _pinCtrl.dispose(); _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48, height: 48,
      textStyle: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    );
    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(border: Border.all(color: AppColors.primary, width: 2)),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Mobile Verification'), backgroundColor: AppColors.bg, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SizedBox(height: 32),
            Icon(Icons.phone_android, size: 64, color: AppColors.primary),
            const SizedBox(height: 20),
            Text('Verify Mobile Number', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text)),
            const SizedBox(height: 8),
            Text(
              _mobileNumber.isNotEmpty ? 'Enter the OTP sent to $_mobileNumber' : 'Enter the OTP sent to your registered mobile number',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 36),
            Pinput(
              length: 6,
              controller: _pinCtrl,
              autofocus: true,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onCompleted: _verify,
            ),
            const SizedBox(height: 28),
            AppButton(label: 'Verify', loading: _verifying, onPressed: () => _verify(_pinCtrl.text)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _secondsLeft == 0 ? _sendOtp : null,
              child: Text(
                _secondsLeft == 0 ? 'Resend OTP' : 'Resend OTP in ${_secondsLeft}s',
                style: TextStyle(color: _secondsLeft == 0 ? AppColors.primary : AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
