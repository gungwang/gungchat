import 'package:flutter/material.dart';

import '../reaction_service.dart';
import '../../../models/message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onReply,
    this.onQuotedMessageTap,
    this.isHighlighted = false,
    this.currentUserId,
    this.onToggleReaction,
  });

  final Message message;
  final VoidCallback? onReply;
  final VoidCallback? onQuotedMessageTap;
  final bool isHighlighted;
  final String? currentUserId;
  final ValueChanged<String>? onToggleReaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment =
        message.isOutgoing ? Alignment.centerRight : Alignment.centerLeft;
    final backgroundColor = message.isOutgoing
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final replyPreview = _replyPreviewText();
    final reactionEntries = message.reactions.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));
    final bubble = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted
            ? Border.all(
                color: theme.colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyPreview != null) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onQuotedMessageTap,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 3,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quoted message',
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        replyPreview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(message.body),
          const SizedBox(height: 8),
          Text(
            _metadataLabel(),
            style: theme.textTheme.labelSmall,
          ),
          if (reactionEntries.isNotEmpty || onToggleReaction != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in reactionEntries)
                  InputChip(
                    label: Text('${entry.key} ${entry.value.length}'),
                    selected: currentUserId != null &&
                        entry.value.contains(currentUserId),
                    onPressed: onToggleReaction == null
                        ? null
                        : () => onToggleReaction!(entry.key),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                if (onToggleReaction != null)
                  PopupMenuButton<String>(
                    tooltip: 'Add reaction',
                    onSelected: onToggleReaction,
                    itemBuilder: (context) {
                      return [
                        for (final emoji in ReactionService.defaultEmojis)
                          PopupMenuItem<String>(
                            value: emoji,
                            child: Text(emoji),
                          ),
                      ];
                    },
                    icon: const Icon(Icons.add_reaction_outlined),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    iconSize: 18,
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    return Align(
      alignment: alignment,
      child: onReply == null
          ? bubble
          : Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onLongPress: onReply,
                child: bubble,
              ),
            ),
    );
  }

  String? _replyPreviewText() {
    final rawValue = message.replyToBody?.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }
    if (rawValue.length <= 96) {
      return rawValue;
    }
    return '${rawValue.substring(0, 96)}...';
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
