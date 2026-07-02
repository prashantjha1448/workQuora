import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/profile_controller.dart';
import '../../application/profile_settings_controller.dart';

/// Skills editor — enforces the 1–5 rule in the UI (min 1, max 5). A worker
/// only gets jobs matching these skills (used by the Phase-2 ranking algorithm),
/// so this screen makes the rule obvious and hard to violate.
class SkillsEditorScreen extends ConsumerStatefulWidget {
  const SkillsEditorScreen({super.key});
  @override
  ConsumerState<SkillsEditorScreen> createState() => _SkillsEditorScreenState();
}

class _SkillsEditorScreenState extends ConsumerState<SkillsEditorScreen> {
  List<String> _skills = [];
  final _input = TextEditingController();
  bool _saving = false;
  bool _init = false;

  static const _suggestions = [
    'Plumbing', 'Electrical', 'Carpentry', 'Painting', 'Cleaning',
    'AC Repair', 'IT Support', 'Web Development', 'Graphic Design', 'Photography',
  ];

  @override
  void dispose() { _input.dispose(); super.dispose(); }

  void _add(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return;
    if (_skills.length >= 5) {
      _snack('Maximum 5 skills allowed.', isError: true);
      return;
    }
    if (_skills.any((e) => e.toLowerCase() == s.toLowerCase())) return;
    setState(() { _skills.add(s); _input.clear(); });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final failure =
        await ref.read(profileSettingsControllerProvider).updateSkills(_skills);
    if (!mounted) return;
    setState(() => _saving = false);
    _snack(failure?.message ?? 'Skills updated.', isError: failure != null);
    if (failure == null) Navigator.of(context).pop();
  }

  void _snack(String m, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m), backgroundColor: isError ? AppColors.error : AppColors.primary));

  @override
  Widget build(BuildContext context) {
    final tt = AppTypography.light;
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    if (!_init && profile != null) {
      _skills = [...profile.skills];
      _init = true;
    }

    final canSave = _skills.isNotEmpty && _skills.length <= 5;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.onSurface,
        title: Text('Your Skills', style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: canSave && !_saving ? _save : null,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save',
                    style: tt.labelLarge?.copyWith(
                        color: canSave ? AppColors.primary : AppColors.outline,
                        fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add 1 to 5 skills. You\'ll be matched to gigs that need them.',
                style: tt.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text('${_skills.length}/5 selected',
                style: tt.labelMedium?.copyWith(
                    color: _skills.length == 5 ? AppColors.promoOrange : AppColors.primary,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),

            // Current skills
            if (_skills.isNotEmpty)
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _skills.map((s) => Chip(
                      label: Text(s),
                      backgroundColor: AppColors.primaryFixed,
                      labelStyle: tt.labelMedium?.copyWith(
                          color: AppColors.onPrimaryFixed, fontWeight: FontWeight.w700),
                      deleteIconColor: AppColors.onPrimaryFixed,
                      onDeleted: () => setState(() => _skills.remove(s)),
                    )).toList(),
              ),
            const SizedBox(height: 20),

            // Input
            TextField(
              controller: _input,
              textInputAction: TextInputAction.done,
              onSubmitted: _add,
              enabled: _skills.length < 5,
              decoration: InputDecoration(
                hintText: _skills.length >= 5 ? 'Max 5 reached' : 'Type a skill and press enter',
                prefixIcon: const Icon(Icons.add_rounded),
                border: OutlineInputBorder(borderRadius: AppRadius.mdR),
                focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.mdR,
                    borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              ),
            ),
            const SizedBox(height: 20),

            Text('Suggestions', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _suggestions
                  .where((s) => !_skills.any((e) => e.toLowerCase() == s.toLowerCase()))
                  .map((s) => ActionChip(
                        label: Text(s),
                        backgroundColor: AppColors.surfaceContainer,
                        labelStyle: tt.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
                        onPressed: _skills.length < 5 ? () => _add(s) : null,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
