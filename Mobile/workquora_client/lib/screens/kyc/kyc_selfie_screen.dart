import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/kyc_provider.dart';
import '../../widgets/app_button.dart';

class KycSelfieScreen extends StatefulWidget {
  const KycSelfieScreen({super.key});
  @override State<KycSelfieScreen> createState() => _KycSelfieScreenState();
}

class _KycSelfieScreenState extends State<KycSelfieScreen> {
  String? _selfiePath;
  bool _submitting = false;

  Future<void> _takeSelfie() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _selfiePath = picked.path);
  }

  Future<void> _submit() async {
    if (_selfiePath == null) return;
    setState(() => _submitting = true);
    final ok = await context.read<KycProvider>().submitSelfie(_selfiePath!);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      context.pop();
    } else {
      final err = context.read<KycProvider>().error ?? 'Failed to submit selfie';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Selfie Verification'), backgroundColor: AppColors.bg, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _selfiePath == null
                ? Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Icon(Icons.person, size: 80, color: AppColors.textMuted),
                  )
                : CircleAvatar(radius: 100, backgroundImage: FileImage(File(_selfiePath!))),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _takeSelfie,
              icon: Icon(Icons.camera_alt, color: AppColors.primary),
              label: Text(_selfiePath == null ? 'Take Selfie' : 'Retake Selfie', style: TextStyle(color: AppColors.primary)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), side: BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
            const SizedBox(height: 8),
            Text(
              'Use front camera. Make sure your face is clearly visible.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 32),
            _selfiePath == null
                ? Container(
                    width: double.infinity, height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                    child: Text('Submit Selfie', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                  )
                : AppButton(label: 'Submit Selfie', loading: _submitting, onPressed: _submit),
          ]),
        ),
      ),
    );
  }
}
