import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        prefixIcon: icon != null ? Icon(icon, color: AppColors.outline, size: 20) : null,
      ),
    );
  }
}
