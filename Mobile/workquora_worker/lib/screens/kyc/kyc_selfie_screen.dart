import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/kyc_provider.dart';
import '../../widgets/app_button.dart';

class KycSelfieScreen extends StatefulWidget {
  const KycSelfieScreen({super.key});
  @override
  State<KycSelfieScreen> createState() => _KycSelfieScreenState();
}

class _KycSelfieScreenState extends State<KycSelfieScreen> {
  String? _filePath;

  Future<void> _takeSelfie() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front, imageQuality: 85);
    if (picked != null) setState(() => _filePath = picked.path);
  }

  Future<void> _submit() async {
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Take a selfie first'), backgroundColor: AppColors.error));
      return;
    }
    final kyc = context.read<KycProvider>();
    final ok = await kyc.submitSelfie(_filePath!);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Selfie submitted!'), backgroundColor: AppColors.success));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(kyc.error ?? 'Could not submit selfie'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kyc = context.watch<KycProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Selfie Verification'), backgroundColor: AppColors.background, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text('Take a clear selfie in good lighting to confirm your identity.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _takeSelfie,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2)),
              clipBehavior: Clip.antiAlias,
              child: _filePath != null
                  ? Image.file(File(_filePath!), fit: BoxFit.cover)
                  : Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary, size: 48),
            ),
          ),
          const SizedBox(height: 14),
          TextButton(onPressed: _takeSelfie, child: Text(_filePath != null ? 'Retake Selfie' : 'Open Camera', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
          const Spacer(),
          AppButton(label: 'Submit Selfie', loading: kyc.isSubmitting, onPressed: _submit),
        ]),
      ),
    );
  }
}
