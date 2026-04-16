import 'package:flutter/material.dart';

import '../../../models/message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment =
        message.isOutgoing ? Alignment.centerRight : Alignment.centerLeft;
    final backgroundColor = message.isOutgoing
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.body),
            const SizedBox(height: 8),
            Text(
              _metadataLabel(),
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  String _metadataLabel() {
    final created = _formatTime(message.createdAt);
    final burnLabel = message.burnAfterRead ? 'Burn-after-read' : 'Persistent';
    return '$created • ${message.deliveryState.name} • $burnLabel';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
