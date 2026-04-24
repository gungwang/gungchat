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
    this.onToggleStar,
    this.onEdit,
    this.onDelete,
  });

  final Message message;
  final VoidCallback? onReply;
  final VoidCallback? onQuotedMessageTap;
  final bool isHighlighted;
  final String? currentUserId;
  final ValueChanged<String>? onToggleReaction;
  final VoidCallback? onToggleStar;
  final VoidCallback? onEdit;
  final ValueChanged<MessageDeleteMode>? onDelete;

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
    final availableActions = <_MessageBubbleAction>[
      if (onEdit != null && !message.isDeleted) _MessageBubbleAction.edit,
      if (onDelete != null && !message.isDeleted) _MessageBubbleAction.delete,
      if (onDelete != null) _MessageBubbleAction.erase,
    ];
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
          _buildBody(theme),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _metadataLabel(),
                  style: theme.textTheme.labelSmall,
                ),
              ),
              if (onToggleStar != null)
                IconButton(
                  tooltip: message.isStarred ? 'Remove star' : 'Star message',
                  onPressed: onToggleStar,
                  icon: Icon(
                    message.isStarred ? Icons.star : Icons.star_border,
                    size: 18,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                ),
              if (availableActions.isNotEmpty)
                PopupMenuButton<_MessageBubbleAction>(
                  key: const ValueKey('message-actions-button'),
                  tooltip: 'Message actions',
                  onSelected: (action) {
                    switch (action) {
                      case _MessageBubbleAction.edit:
                        onEdit?.call();
                      case _MessageBubbleAction.delete:
                        onDelete?.call(MessageDeleteMode.tombstone);
                      case _MessageBubbleAction.erase:
                        onDelete?.call(MessageDeleteMode.hardDelete);
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      if (availableActions.contains(_MessageBubbleAction.edit))
                        const PopupMenuItem<_MessageBubbleAction>(
                          key: ValueKey('message-action-edit'),
                          value: _MessageBubbleAction.edit,
                          child: Text('Edit message'),
                        ),
                      if (availableActions.contains(_MessageBubbleAction.delete))
                        const PopupMenuItem<_MessageBubbleAction>(
                          key: ValueKey('message-action-delete'),
                          value: _MessageBubbleAction.delete,
                          child: Text('Delete for everyone'),
                        ),
                      if (availableActions.contains(_MessageBubbleAction.erase))
                        const PopupMenuItem<_MessageBubbleAction>(
                          key: ValueKey('message-action-erase'),
                          value: _MessageBubbleAction.erase,
                          child: Text('Erase permanently'),
                        ),
                    ];
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  iconSize: 18,
                ),
            ],
          ),
          if (!message.isDeleted &&
              (reactionEntries.isNotEmpty || onToggleReaction != null)) ...[
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

  Widget _buildBody(ThemeData theme) {
    if (!message.isDeleted) {
      return Text(message.body);
    }

    return Text(
      'Message deleted',
      style: theme.textTheme.bodyMedium?.copyWith(
        fontStyle: FontStyle.italic,
        color: theme.colorScheme.onSurfaceVariant,
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
    final status = message.isDeleted
        ? 'deleted'
        : message.isEdited
            ? 'edited'
            : null;
    return [created, message.deliveryState.name, burnLabel, if (status != null) status]
        .join(' • ');
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

enum _MessageBubbleAction {
  edit,
  delete,
  erase,
}
