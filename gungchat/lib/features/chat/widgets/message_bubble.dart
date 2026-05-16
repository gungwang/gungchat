import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/text/spoiler_renderer.dart';
import '../reaction_service.dart';
import '../link_preview_service.dart';
import '../../../models/message.dart';

class MessageBubble extends ConsumerWidget {
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
    this.onPlayAudio,
    this.isPlayingAudio = false,
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
  final VoidCallback? onPlayAudio;
  final bool isPlayingAudio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSystemMessage = message.type == MessageType.system;
    final alignment = isSystemMessage
      ? Alignment.center
      : message.isOutgoing
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final backgroundColor = isSystemMessage
      ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.84)
      : message.isOutgoing
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
      constraints: BoxConstraints(maxWidth: isSystemMessage ? 320 : 420),
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
        crossAxisAlignment:
            isSystemMessage ? CrossAxisAlignment.center : CrossAxisAlignment.start,
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
          _buildBody(context, ref, theme),
          const SizedBox(height: 8),
          if (isSystemMessage)
            Text(
              _metadataLabel(),
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
            )
          else
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

  Widget _buildBody(BuildContext context, WidgetRef ref, ThemeData theme) {
    if (message.isDeleted) {
      return Text(
        'Message deleted',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (message.type == MessageType.system) {
      return Text(
        message.body,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    if (message.type == MessageType.location ||
        message.type == MessageType.contactCard ||
        message.type == MessageType.multiAttachment ||
        message.type == MessageType.image ||
        message.type == MessageType.video ||
        message.hasAttachments) {
      return _AttachmentMessageBody(message: message);
    }

    if (message.type == MessageType.audio && message.hasAudio) {
      return _AudioMessagePreview(
        durationLabel: _formatDuration(message.audioDurationMs),
        onPlayAudio: onPlayAudio,
        isPlayingAudio: isPlayingAudio,
      );
    }

    if (message.type == MessageType.text) {
      final hasSpoilers = SpoilerRenderer.hasSpoilers(message.body);
      final previewUrl = LinkPreviewService.extractFirstUrl(
        hasSpoilers ? SpoilerRenderer.visibleText(message.body) : message.body,
      );
      final body = hasSpoilers
          ? _SpoilerTextBody(text: message.body)
          : Text(message.body);
      if (previewUrl != null) {
        final previewAsync = ref.watch(linkPreviewProvider(previewUrl));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            body,
            const SizedBox(height: 8),
            previewAsync.when(
              data: (preview) {
                if (preview == null) {
                  return const SizedBox.shrink();
                }
                return _LinkPreviewCard(preview: preview);
              },
              loading: () => const _LinkPreviewLoadingCard(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        );
      }

      return body;
    }

    return Text(message.body);
  }

  String? _replyPreviewText() {
    final replyBody = message.replyToBody;
    if (replyBody == null) {
      return null;
    }

    final rawValue = SpoilerRenderer.previewText(replyBody);
    if (rawValue.isEmpty) {
      return null;
    }
    if (rawValue.length <= 96) {
      return rawValue;
    }
    return '${rawValue.substring(0, 96)}...';
  }

  String _metadataLabel() {
    final created = _formatTime(message.createdAt);
    if (message.type == MessageType.system) {
      return created;
    }
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

  String _formatDuration(int? durationMs) {
    if (durationMs == null || durationMs <= 0) {
      return '0:00';
    }

    final totalSeconds = (durationMs / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _SpoilerTextBody extends StatefulWidget {
  const _SpoilerTextBody({required this.text});

  final String text;

  @override
  State<_SpoilerTextBody> createState() => _SpoilerTextBodyState();
}

class _SpoilerTextBodyState extends State<_SpoilerTextBody> {
  List<SpoilerSegment> _segments = const <SpoilerSegment>[];
  final Set<int> _revealedIndices = <int>{};

  @override
  void initState() {
    super.initState();
    _segments = SpoilerRenderer.parse(widget.text);
  }

  @override
  void didUpdateWidget(covariant _SpoilerTextBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _segments = SpoilerRenderer.parse(widget.text);
      _revealedIndices.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium;

    return Text.rich(
      TextSpan(
        children: [
          for (var index = 0; index < _segments.length; index++)
            if (!_segments[index].isSpoiler || _revealedIndices.contains(index))
              TextSpan(
                text: _segments[index].text,
                style: _segments[index].isSpoiler
                    ? baseStyle?.copyWith(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      )
                    : baseStyle,
              )
            else
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _HiddenSpoilerChip(
                  key: ValueKey('spoiler-segment-$index'),
                  onTap: () {
                    setState(() {
                      _revealedIndices.add(index);
                    });
                  },
                ),
              ),
        ],
      ),
      style: baseStyle,
    );
  }
}

class _HiddenSpoilerChip extends StatelessWidget {
  const _HiddenSpoilerChip({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Spoiler, tap to reveal',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.inverseSurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                'Spoiler',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onInverseSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioMessagePreview extends StatelessWidget {
  const _AudioMessagePreview({
    required this.durationLabel,
    required this.onPlayAudio,
    required this.isPlayingAudio,
  });

  final String durationLabel;
  final VoidCallback? onPlayAudio;
  final bool isPlayingAudio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barHeights = const <double>[8, 14, 10, 18, 12, 16, 9, 15, 11, 7];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: isPlayingAudio ? 'Stop voice message' : 'Play voice message',
          onPressed: onPlayAudio,
          icon: Icon(isPlayingAudio ? Icons.stop_circle : Icons.play_circle),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voice message',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final height in barHeights) ...[
                    Container(
                      width: 4,
                      height: height,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 3),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(durationLabel, style: theme.textTheme.labelMedium),
      ],
    );
  }
}

class _AttachmentMessageBody extends StatelessWidget {
  const _AttachmentMessageBody({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.location && message.attachments.isNotEmpty) {
      return _LocationAttachmentCard(attachment: message.attachments.first);
    }
    if (message.type == MessageType.contactCard && message.attachments.isNotEmpty) {
      return _ContactAttachmentCard(attachment: message.attachments.first);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.body.trim().isNotEmpty) ...[
          Text(message.body),
          const SizedBox(height: 8),
        ],
        for (final attachment in message.attachments) ...[
          _AttachmentTile(attachment: attachment),
          if (attachment != message.attachments.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _LocationAttachmentCard extends StatelessWidget {
  const _LocationAttachmentCard({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final latitude = attachment.metadata['latitude'];
    final longitude = attachment.metadata['longitude'];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.place_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shared location',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text('Lat $latitude, Lng $longitude'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactAttachmentCard extends StatelessWidget {
  const _ContactAttachmentCard({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.contact_page_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (attachment.metadata['displayName'] as String?) ?? 'Shared contact',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text((attachment.metadata['fingerprint'] as String?) ?? ''),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final filePath = attachment.filePath;
    if (attachment.isImage && filePath != null && filePath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(filePath),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _AttachmentInfoRow(attachment: attachment),
        ),
      );
    }

    return _AttachmentInfoRow(attachment: attachment);
  }
}

class _AttachmentInfoRow extends StatelessWidget {
  const _AttachmentInfoRow({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(_iconForType(attachment.type)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.previewLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (attachment.mimeType != null || attachment.sizeBytes != null)
                    Text(
                      [
                        if (attachment.mimeType != null) attachment.mimeType!,
                        if (attachment.sizeBytes != null)
                          '${(attachment.sizeBytes! / 1024).ceil()} KB',
                      ].join(' • '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return Icons.image_outlined;
      case AttachmentType.video:
        return Icons.videocam_outlined;
      case AttachmentType.audio:
        return Icons.audio_file_outlined;
      case AttachmentType.document:
        return Icons.insert_drive_file_outlined;
      case AttachmentType.location:
        return Icons.place_outlined;
      case AttachmentType.contactCard:
        return Icons.contact_page_outlined;
    }
  }
}

class _LinkPreviewCard extends StatelessWidget {
  const _LinkPreviewCard({required this.preview});

  final LinkPreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface.withValues(alpha: 0.55),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (preview.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  preview.imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              preview.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            if (preview.description != null) ...[
              const SizedBox(height: 4),
              Text(
                preview.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 6),
            Text(
              preview.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkPreviewLoadingCard extends StatelessWidget {
  const _LinkPreviewLoadingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface.withValues(alpha: 0.45),
      ),
      child: const Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Loading link preview...'),
          ],
        ),
      ),
    );
  }
}

enum _MessageBubbleAction {
  edit,
  delete,
  erase,
}
