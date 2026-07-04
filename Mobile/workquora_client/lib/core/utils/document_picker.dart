import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';

/// Shows a bottom sheet with "Take Photo" / "Choose from Gallery" and
/// returns the picked file path, or null if the user cancelled.
Future<String?> pickDocumentImage(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        ListTile(
          leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
          title: const Text('Take Photo', style: TextStyle(color: AppColors.text)),
          onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
          title: const Text('Choose from Gallery', style: TextStyle(color: AppColors.text)),
          onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
        ),
        const SizedBox(height: 12),
      ]),
    ),
  );

  if (source == null) return null;
  final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
  return picked?.path;
}
