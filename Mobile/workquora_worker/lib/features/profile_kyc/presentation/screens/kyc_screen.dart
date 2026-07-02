import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/error/app_exception.dart';
import '../../application/kyc_controller.dart';
import '../../application/kyc_verification_gateway.dart';

/// Worker KYC — 3 steps: PAN → Aadhaar → Bank. Submitted via [kycGatewayProvider]
/// (manual admin review today; swap to DigiLocker/UIDAI automation later with a
/// one-line provider change — no UI edits). Mobile OTP step is disabled for now.
/// After submitting all three, status is "pending" until an admin approves.
class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});
  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  final _pan = TextEditingController();
  final _aadhaar = TextEditingController();
  final _acc = TextEditingController();
  final _ifsc = TextEditingController();
  final _holder = TextEditingController();
  File? _panDoc, _aadhaarDoc, _bankDoc;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_pan, _aadhaar, _acc, _ifsc, _holder]) c.dispose();
    super.dispose();
  }

  Future<File?> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    return x == null ? null : File(x.path);
  }

  Future<void> _run(Future<AppFailure?> Function() action, String ok) async {
    setState(() => _busy = true);
    final failure = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(failure?.message ?? ok),
      backgroundColor: failure == null ? AppColors.primary : AppColors.error,
    ));
    if (failure == null) ref.read(kycControllerProvider.notifier).loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    final kyc = ref.watch(kycControllerProvider);
    final gateway = ref.read(kycGatewayProvider);
    final tt = AppTypography.light;
    final s = kyc.status;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Identity Verification',
            style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        foregroundColor: AppColors.onSurface,
      ),
      body: kyc.isLoadingStatus
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s.status == 'verified')
                    _banner(Icons.verified_rounded, 'Your identity is verified.',
                        AppColors.primary, AppColors.primaryFixed)
                  else if (s.status == 'pending' && (s.panVerified || s.aadhaarVerified || s.bankVerified))
                    _banner(Icons.hourglass_top_rounded,
                        'Submitted — under admin review. You\'ll be notified once approved.',
                        AppColors.promoOrange, AppColors.primaryFixed)
                  else if (s.status == 'rejected')
                    _banner(Icons.error_outline_rounded,
                        'Some documents were rejected. Please re-submit.',
                        AppColors.error, AppColors.errorContainer),
                  const SizedBox(height: 20),

                  // PAN
                  _StepCard(
                    index: 1, title: 'PAN Card', done: s.panVerified,
                    child: Column(children: [
                      _field(_pan, 'PAN number (ABCDE1234F)'),
                      _docRow('Upload PAN', _panDoc, () async {
                        final f = await _pick(); if (f != null) setState(() => _panDoc = f);
                      }),
                      _submit('Submit PAN', s.panVerified || _busy, () => _run(
                        () => gateway.submitPan(panNumber: _pan.text.trim().toUpperCase(), document: _panDoc),
                        'PAN submitted for review.')),
                    ]),
                  ),

                  // Aadhaar
                  _StepCard(
                    index: 2, title: 'Aadhaar Card', done: s.aadhaarVerified,
                    child: Column(children: [
                      _field(_aadhaar, 'Aadhaar number (12 digits)'),
                      _docRow('Upload Aadhaar', _aadhaarDoc, () async {
                        final f = await _pick(); if (f != null) setState(() => _aadhaarDoc = f);
                      }),
                      _submit('Submit Aadhaar', s.aadhaarVerified || _busy, () => _run(
                        () => gateway.submitAadhaar(aadhaarNumber: _aadhaar.text.trim(), document: _aadhaarDoc),
                        'Aadhaar submitted for review.')),
                    ]),
                  ),

                  // Bank
                  _StepCard(
                    index: 3, title: 'Bank Account', done: s.bankVerified,
                    child: Column(children: [
                      _field(_holder, 'Account holder name'),
                      _field(_acc, 'Account number'),
                      _field(_ifsc, 'IFSC code'),
                      _docRow('Upload passbook/cheque', _bankDoc, () async {
                        final f = await _pick(); if (f != null) setState(() => _bankDoc = f);
                      }),
                      _submit('Submit Bank', s.bankVerified || _busy, () => _run(
                        () => gateway.submitBank(
                          accountNumber: _acc.text.trim(),
                          ifscCode: _ifsc.text.trim().toUpperCase(),
                          accountHolderName: _holder.text.trim(),
                          document: _bankDoc),
                        'Bank details submitted for review.')),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Text('Verification is reviewed by our team. This will move to instant automated checks (DigiLocker) in the future.',
                      style: tt.labelSmall?.copyWith(color: AppColors.outline)),
                ],
              ),
            ),
    );
  }

  Widget _banner(IconData i, String t, Color fg, Color bg) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.mdR),
        child: Row(children: [
          Icon(i, color: fg), const SizedBox(width: 10),
          Expanded(child: Text(t, style: AppTypography.light.bodyMedium?.copyWith(color: fg, fontWeight: FontWeight.w600))),
        ]),
      );

  Widget _field(TextEditingController c, String hint) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: AppRadius.mdR),
            focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.mdR,
                borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            isDense: true,
          ),
        ),
      );

  Widget _docRow(String label, File? file, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: file != null ? AppColors.primary : AppColors.onSurfaceVariant,
            side: BorderSide(color: file != null ? AppColors.primary : AppColors.outlineVariant),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdR),
            minimumSize: const Size(double.infinity, 44),
          ),
          onPressed: onTap,
          icon: Icon(file != null ? Icons.check_circle_rounded : Icons.upload_file_rounded, size: 18),
          label: Text(file != null ? 'Selected' : label),
        ),
      );

  Widget _submit(String label, bool disabled, VoidCallback onTap) => SizedBox(
        width: double.infinity, height: 46,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: disabled ? AppColors.surfaceContainerHigh : AppColors.primary,
            foregroundColor: disabled ? AppColors.outline : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdR),
          ),
          onPressed: disabled ? null : onTap,
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.index, required this.title, required this.done, required this.child});
  final int index; final String title; final bool done; final Widget child;
  @override
  Widget build(BuildContext context) {
    final tt = AppTypography.light;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.lgR,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: done ? AppColors.primary : AppColors.surfaceContainerHigh,
            child: done
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text('$index', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Text(title, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          if (done) Text('Verified', style: tt.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
        ]),
        if (!done) ...[const SizedBox(height: 14), child],
      ]),
    );
  }
}
