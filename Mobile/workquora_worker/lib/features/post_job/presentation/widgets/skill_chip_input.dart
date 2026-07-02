import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class SkillChipInput extends StatefulWidget {
  const SkillChipInput({super.key, required this.skills, required this.onAdd, required this.onRemove});

  final List<String> skills;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<SkillChipInput> createState() => _SkillChipInputState();
}

class _SkillChipInputState extends State<SkillChipInput> {
  final _controller = TextEditingController();

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    widget.onAdd(_controller.text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onSubmitted: (_) => _submit(),
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'e.g. Figma, React, Plumbing…',
            prefixIcon: const Icon(Icons.label_outline_rounded, color: AppColors.outline, size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
              onPressed: _submit,
            ),
          ),
        ),
        if (widget.skills.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.stackMd),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.skills
                .map((s) => Chip(
                      label: Text(s),
                      onDeleted: () => widget.onRemove(s),
                      deleteIconColor: AppColors.onSurfaceVariant,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
