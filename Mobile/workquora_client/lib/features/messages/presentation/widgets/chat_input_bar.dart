import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({super.key, required this.onSend, required this.onTypingChanged});

  final ValueChanged<String> onSend;
  final ValueChanged<bool> onTypingChanged;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  Timer? _stopTypingTimer;
  bool _isTyping = false;

  void _handleChanged(String value) {
    if (!_isTyping && value.isNotEmpty) {
      _isTyping = true;
      widget.onTypingChanged(true);
    }
    // Emit "stopped typing" 1.5s after the last keystroke instead of on
    // every change — keeps socket traffic (and the other user's UI churn)
    // proportional to typing pauses, not keystrokes.
    _stopTypingTimer?.cancel();
    _stopTypingTimer = Timer(const Duration(milliseconds: 1500), () {
      _isTyping = false;
      widget.onTypingChanged(false);
    });
  }

  void _handleSend() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    _stopTypingTimer?.cancel();
    _isTyping = false;
    widget.onTypingChanged(false);
  }

  @override
  void dispose() {
    _stopTypingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerMargin,
        AppSpacing.stackSm,
        AppSpacing.containerMargin,
        AppSpacing.stackSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [BoxShadow(color: AppColors.outlineVariant.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _handleChanged,
                onSubmitted: (_) => _handleSend(),
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Type a message…'),
              ),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _handleSend,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
