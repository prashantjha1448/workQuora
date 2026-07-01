import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../application/profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _titleController;
  late final TextEditingController _bioController;
  bool _isSaving = false;
  String? _error;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final failure = await ref.read(profileControllerProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          title: _titleController.text.trim(),
          bio: _bioController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (failure != null) {
      setState(() => _error = failure.message);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider).valueOrNull;

    if (!_initialized && profile != null) {
      _nameController = TextEditingController(text: profile.name);
      _titleController = TextEditingController(text: profile.title);
      _bioController = TextEditingController(text: profile.bio);
      _initialized = true;
    }

    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          children: [
            const Text('Company / Display name'),
            const SizedBox(height: AppSpacing.stackSm),
            TextField(controller: _nameController, decoration: const InputDecoration(prefixIcon: Icon(Icons.business_outlined))),
            const SizedBox(height: AppSpacing.stackMd),
            const Text('Title'),
            const SizedBox(height: AppSpacing.stackSm),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'e.g. Tech & Software', prefixIcon: Icon(Icons.work_outline_rounded)),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            const Text('Bio / Description'),
            const SizedBox(height: AppSpacing.stackSm),
            TextField(
              controller: _bioController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell freelancers about your company…',
                errorText: _error,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            PrimaryButton(label: 'Save changes', isLoading: _isSaving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}