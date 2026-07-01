import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../application/registration_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  int _secondsLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify(RegistrationStep step) async {
    final notifier = ref.read(registrationControllerProvider.notifier);
    if (step == RegistrationStep.emailOtp) {
      await notifier.verifyEmailOtp(_otpController.text.trim());
    } else if (step == RegistrationStep.mobileOtp) {
      await notifier.verifyMobileOtp(_otpController.text.trim());
    }
    _otpController.clear();
  }

  Future<void> _resend(RegistrationStep step) async {
    final notifier = ref.read(registrationControllerProvider.notifier);
    if (step == RegistrationStep.mobileOtp) {
      await notifier.resendMobileOtp();
    }
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final isEmailStep = regState.step == RegistrationStep.emailOtp;

    ref.listen(registrationControllerProvider, (prev, next) {
      if (next.step == RegistrationStep.done && context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(isEmailStep ? 'Verify email' : 'Verify mobile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                isEmailStep ? 'Check your email' : 'Check your phone',
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                isEmailStep
                    ? 'We sent a 6-digit code to ${regState.email}'
                    : 'We sent a 6-digit code via SMS to confirm your number.',
                style: textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '——————',
                  errorText: regState.error?.message,
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              PrimaryButton(
                label: 'Verify',
                isLoading: regState.isLoading,
                onPressed: () => _verify(regState.step),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Center(
                child: _secondsLeft > 0
                    ? Text(
                        'Resend code in ${_secondsLeft}s',
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.outline),
                      )
                    : TextButton(
                        onPressed: () => _resend(regState.step),
                        child: const Text('Resend code'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}