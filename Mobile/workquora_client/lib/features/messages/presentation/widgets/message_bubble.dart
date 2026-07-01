import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.isMine});

  final MessageModel message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.surfaceContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: textTheme.bodyLarge?.copyWith(color: isMine ? Colors.white : AppColors.onSurface),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat.Hm().format(message.createdAt),
                  style: textTheme.labelSmall?.copyWith(
                    color: isMine ? Colors.white.withValues(alpha: 0.75) : AppColors.outline,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(_statusIcon, size: 14, color: Colors.white.withValues(alpha: 0.85)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData get _statusIcon {
    if (message.isOptimistic) return Icons.schedule_rounded;
    switch (message.status) {
      case 'read':
        return Icons.done_all_rounded;
      case 'delivered':
        return Icons.done_all_rounded;
      default:
        return Icons.done_rounded;
    }
  }
}
