import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../application/kyc_controller.dart';
import '../widgets/document_picker.dart';

const _kStepLabels = ['Mobile', 'PAN', 'Aadhaar', 'Bank', 'Selfie'];

class KycScreen extends ConsumerWidget {
  const KycScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kycControllerProvider);

    if (state.isLoadingStatus) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.currentStep == KycStep.done) {
      return const _KycDoneScreen();
    }

    final stepIndex = state.currentStep.index;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify your identity')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin, vertical: AppSpacing.stackMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: (stepIndex + 1) / _kStepLabels.length,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: AppColors.surfaceContainerHigh,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Step ${stepIndex + 1} of ${_kStepLabels.length} — ${_kStepLabels[stepIndex]}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
                child: SingleChildScrollView(
                  child: switch (state.currentStep) {
                    KycStep.mobile => const _MobileStep(),
                    KycStep.pan => const _PanStep(),
                    KycStep.aadhaar => const _AadhaarStep(),
                    KycStep.bank => const _BankStep(),
                    KycStep.selfie => const _SelfieStep(),
                    KycStep.done => const SizedBox.shrink(),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileStep extends ConsumerStatefulWidget {
  const _MobileStep();
  @override
  ConsumerState<_MobileStep> createState() => _MobileStepState();
}

class _MobileStepState extends ConsumerState<_MobileStep> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycControllerProvider);
    final controller = ref.read(kycControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Verify your mobile number', style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.stackSm),
        Text("We use this to confirm it's really you.",
            style: textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.stackLg),
        TextField(
          controller: _mobileController,
          enabled: !_otpSent,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: 'Mobile number', prefixIcon: Icon(Icons.phone_outlined)),
        ),
        if (_otpSent) ...[
          const SizedBox(height: AppSpacing.stackMd),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '6-digit OTP',
              prefixIcon: const Icon(Icons.sms_outlined),
              errorText: state.error?.message,
            ),
          ),
        ] else if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(state.error!.message, style: textTheme.labelMedium?.copyWith(color: AppColors.error)),
          ),
        const SizedBox(height: AppSpacing.stackLg),
        PrimaryButton(
          label: _otpSent ? 'Verify OTP' : 'Send OTP',
          isLoading: state.isSubmitting,
          onPressed: () async {
            if (!_otpSent) {
              final ok = await controller.sendMobileOtp(_mobileController.text.trim());
              if (ok) setState(() => _otpSent = true);
            } else {
              await controller.verifyMobileOtp(_otpController.text.trim());
            }
          },
        ),
      ],
    );
  }
}

class _PanStep extends ConsumerStatefulWidget {
  const _PanStep();
  @override
  ConsumerState<_PanStep> createState() => _PanStepState();
}

class _PanStepState extends ConsumerState<_PanStep> {
  final _panController = TextEditingController();
  File? _document;

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycControllerProvider);
    final controller = ref.read(kycControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('PAN verification', style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.stackSm),
        Text('Required for posting jobs and withdrawals.',
            style: textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.stackLg),
        TextField(
          controller: _panController,
          textCapitalization: TextCapitalization.characters,
          maxLength: 10,
          decoration: InputDecoration(
            hintText: 'ABCDE1234F',
            prefixIcon: const Icon(Icons.badge_outlined),
            errorText: state.error?.message,
          ),
        ),
        DocumentPicker(
          label: 'Upload PAN card photo (optional)',
          file: _document,
          onChanged: (f) => setState(() => _document = f),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        PrimaryButton(
          label: 'Submit PAN',
          isLoading: state.isSubmitting,
          onPressed: () => controller.submitPan(_panController.text.trim(), document: _document),
        ),
      ],
    );
  }
}

class _AadhaarStep extends ConsumerStatefulWidget {
  const _AadhaarStep();
  @override
  ConsumerState<_AadhaarStep> createState() => _AadhaarStepState();
}

class _AadhaarStepState extends ConsumerState<_AadhaarStep> {
  final _aadhaarController = TextEditingController();
  File? _document;

  @override
  void dispose() {
    _aadhaarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycControllerProvider);
    final controller = ref.read(kycControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Aadhaar verification', style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.stackSm),
        Text('Required for posting jobs and withdrawals.',
            style: textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.stackLg),
        TextField(
          controller: _aadhaarController,
          keyboardType: TextInputType.number,
          maxLength: 12,
          decoration: InputDecoration(
            hintText: '12-digit Aadhaar number',
            prefixIcon: const Icon(Icons.fingerprint_rounded),
            errorText: state.error?.message,
          ),
        ),
        DocumentPicker(
          label: 'Upload Aadhaar photo (optional)',
          file: _document,
          onChanged: (f) => setState(() => _document = f),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        PrimaryButton(
          label: 'Submit Aadhaar',
          isLoading: state.isSubmitting,
          onPressed: () => controller.submitAadhaar(_aadhaarController.text.trim(), document: _document),
        ),
      ],
    );
  }
}

class _BankStep extends ConsumerStatefulWidget {
  const _BankStep();
  @override
  ConsumerState<_BankStep> createState() => _BankStepState();
}

class _BankStepState extends ConsumerState<_BankStep> {
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _holderController = TextEditingController();
  final _pinController = TextEditingController();
  File? _document;

  @override
  void dispose() {
    _accountController.dispose();
    _ifscController.dispose();
    _holderController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycControllerProvider);
    final controller = ref.read(kycControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Bank details', style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          "Also sets your wallet withdrawal PIN — the only place it's created.",
          style: textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        TextField(
          controller: _holderController,
          decoration: const InputDecoration(hintText: 'Account holder name', prefixIcon: Icon(Icons.person_outline_rounded)),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        TextField(
          controller: _accountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Account number', prefixIcon: Icon(Icons.numbers_rounded)),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        TextField(
          controller: _ifscController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'IFSC code',
            prefixIcon: const Icon(Icons.tag_rounded),
            errorText: state.error?.message,
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(hintText: 'Set a 4–6 digit withdrawal PIN', prefixIcon: Icon(Icons.pin_outlined)),
        ),
        DocumentPicker(
          label: 'Upload bank document (optional)',
          file: _document,
          onChanged: (f) => setState(() => _document = f),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        PrimaryButton(
          label: 'Submit bank details',
          isLoading: state.isSubmitting,
          onPressed: () => controller.submitBank(
            accountNumber: _accountController.text.trim(),
            ifsc: _ifscController.text.trim(),
            holderName: _holderController.text.trim(),
            pin: _pinController.text.trim().isEmpty ? null : _pinController.text.trim(),
            document: _document,
          ),
        ),
      ],
    );
  }
}

class _SelfieStep extends ConsumerStatefulWidget {
  const _SelfieStep();
  @override
  ConsumerState<_SelfieStep> createState() => _SelfieStepState();
}

class _SelfieStepState extends ConsumerState<_SelfieStep> {
  File? _selfie;

  Future<void> _takeSelfie() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _selfie = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycControllerProvider);
    final controller = ref.read(kycControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Take a quick selfie', style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.stackSm),
        Text('Final step — confirms the person matches their documents.',
            style: textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.stackLg),
        Center(
          child: GestureDetector(
            onTap: _takeSelfie,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainer,
                border: Border.all(color: AppColors.outlineVariant),
                image: _selfie != null ? DecorationImage(image: FileImage(_selfie!), fit: BoxFit.cover) : null,
              ),
              child: _selfie == null ? const Icon(Icons.camera_alt_outlined, size: 36, color: AppColors.outline) : null,
            ),
          ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.stackMd),
            child: Text(
              state.error!.message,
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(color: AppColors.error),
            ),
          ),
        const SizedBox(height: AppSpacing.stackLg),
        PrimaryButton(
          label: 'Submit selfie',
          isLoading: state.isSubmitting,
          onPressed: _selfie == null ? null : () => controller.submitSelfie(_selfie!),
        ),
      ],
    );
  }
}

class _KycDoneScreen extends StatelessWidget {
  const _KycDoneScreen();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.containerMargin),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: AppColors.secondaryContainer, shape: BoxShape.circle),
                  child: const Icon(Icons.verified_rounded, color: AppColors.secondary, size: 36),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                Text('Identity verified', style: textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  'You can now post jobs and manage your wallet without restrictions.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                PrimaryButton(label: 'Done', onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
