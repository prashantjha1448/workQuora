import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class DocumentPicker extends StatelessWidget {
  const DocumentPicker({super.key, required this.label, required this.file, required this.onChanged});

  final String label;
  final File? file;
  final ValueChanged<File> onChanged;

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1600);
    if (picked != null) onChanged(File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
          image: file != null ? DecorationImage(image: FileImage(file!), fit: BoxFit.cover) : null,
        ),
        alignment: Alignment.center,
        child: file == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upload_file_rounded, color: AppColors.outline),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text(label, style: textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              )
            : Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                ),
              ),
      ),
    );
  }
}
