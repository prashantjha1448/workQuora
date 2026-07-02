import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/auth_providers.dart';

/// Real-time username availability field.
/// Debounces input (500ms), calls GET /auth/check-username, and shows a live
/// green tick / red cross so the worker knows before submitting whether the
/// username is free. Exposes availability upward via [onStatusChanged].
enum UsernameStatus { idle, checking, available, taken, invalid }

class UsernameField extends ConsumerStatefulWidget {
  const UsernameField({
    super.key,
    required this.controller,
    required this.onStatusChanged,
  });

  final TextEditingController controller;
  final ValueChanged<UsernameStatus> onStatusChanged;

  @override
  ConsumerState<UsernameField> createState() => _UsernameFieldState();
}

class _UsernameFieldState extends ConsumerState<UsernameField> {
  UsernameStatus _status = UsernameStatus.idle;
  Timer? _debounce;

  void _onChanged(String value) {
    _debounce?.cancel();
    final v = value.trim();
    if (v.isEmpty) {
      _set(UsernameStatus.idle);
      return;
    }
    // Basic client-side rule: 3-20 chars, alphanumeric + _ .
    final valid = RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(v);
    if (!valid) {
      _set(UsernameStatus.invalid);
      return;
    }
    _set(UsernameStatus.checking);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.checkUsernameAvailable(v);
      result.match(
        (_) => _set(UsernameStatus.idle),
        (available) => _set(available ? UsernameStatus.available : UsernameStatus.taken),
      );
    });
  }

  void _set(UsernameStatus s) {
    if (!mounted) return;
    setState(() => _status = s);
    widget.onStatusChanged(s);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: 'Choose a username',
            prefixIcon: const Icon(Icons.alternate_email_rounded),
            suffixIcon: _suffix(),
            border: OutlineInputBorder(borderRadius: AppRadius.mdR),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.mdR,
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        if (_hint() != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(_hint()!,
                style: TextStyle(fontSize: 12, color: _hintColor())),
          ),
      ],
    );
  }

  Widget? _suffix() => switch (_status) {
        UsernameStatus.checking => const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
          ),
        UsernameStatus.available =>
          const Icon(Icons.check_circle_rounded, color: AppColors.primary),
        UsernameStatus.taken || UsernameStatus.invalid =>
          const Icon(Icons.cancel_rounded, color: AppColors.error),
        _ => null,
      };

  String? _hint() => switch (_status) {
        UsernameStatus.available => 'Username is available',
        UsernameStatus.taken => 'Username is already taken',
        UsernameStatus.invalid => '3-20 chars, letters, numbers or _',
        _ => null,
      };

  Color _hintColor() =>
      _status == UsernameStatus.available ? AppColors.primary : AppColors.error;
}
