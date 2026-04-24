import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:gungchat/core/text/spoiler_renderer.dart';

enum MessageType {
  text,
  image,
  audio,
  video,
  location,
  contactCard,
  multiAttachment,
  system,
}

enum AttachmentType {
  image,
  video,
  audio,
  document,
  location,
  contactCard,
}

enum MessageDeliveryState {
  local,
  sending,
  sent,
  delivered,
  read,
  failed,
}

enum MessageDeleteMode {
  tombstone,
  hardDelete,
}

@immutable
class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.type,
    required this.deliveryState,
    required this.createdAt,
    required this.isOutgoing,
    this.burnAfterRead = true,
    this.expiresAt,
    this.replyToMessageId,
    this.replyToBody,
    this.reactions = const {},
    this.isStarred = false,
    this.editedAt,
    this.deletedAt,
    this.deleteMode,
    this.audioFilePath,
    this.audioDurationMs,
    this.attachments = const [],
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final MessageType type;
  final MessageDeliveryState deliveryState;
  final DateTime createdAt;
  final bool isOutgoing;
  final bool burnAfterRead;
  final DateTime? expiresAt;
  final String? replyToMessageId;
  final String? replyToBody;
  final Map<String, List<String>> reactions;
  final bool isStarred;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final MessageDeleteMode? deleteMode;
  final String? audioFilePath;
  final int? audioDurationMs;
  final List<Attachment> attachments;

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get hasReply => replyToBody != null && replyToBody!.trim().isNotEmpty;
  bool get hasReactions => reactions.isNotEmpty;
  bool get isEdited => editedAt != null && !isDeleted;
  bool get isDeleted => deletedAt != null;
  bool get hasAttachments => attachments.isNotEmpty;
  bool get hasAudio =>
      type == MessageType.audio &&
      audioFilePath != null &&
      audioFilePath!.trim().isNotEmpty;
  String get previewText {
    if (isDeleted) {
      return 'Message deleted';
    }
    if (type == MessageType.audio) {
      return 'Voice message';
    }
    if (type == MessageType.location) {
      return 'Shared location';
    }
    if (type == MessageType.contactCard) {
      return 'Shared contact card';
    }
    if (type == MessageType.multiAttachment) {
      return attachments.isEmpty
          ? 'Attachments'
          : '${attachments.length} attachment${attachments.length == 1 ? '' : 's'}';
    }
    if (type == MessageType.image) {
      return hasAttachments ? attachments.first.previewLabel : 'Image';
    }
    if (type == MessageType.video) {
      return hasAttachments ? attachments.first.previewLabel : 'Video';
    }

    final compact = SpoilerRenderer.previewText(body);
    if (compact.isEmpty) {
      return 'Message';
    }
    return compact;
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? body,
    MessageType? type,
    MessageDeliveryState? deliveryState,
    DateTime? createdAt,
    bool? isOutgoing,
    bool? burnAfterRead,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    String? replyToMessageId,
    String? replyToBody,
    bool clearReplyTo = false,
    Map<String, List<String>>? reactions,
    bool? isStarred,
    DateTime? editedAt,
    bool clearEditedAt = false,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    MessageDeleteMode? deleteMode,
    bool clearDeleteMode = false,
    String? audioFilePath,
    bool clearAudioFilePath = false,
    int? audioDurationMs,
    bool clearAudioDurationMs = false,
    List<Attachment>? attachments,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      body: body ?? this.body,
      type: type ?? this.type,
      deliveryState: deliveryState ?? this.deliveryState,
      createdAt: createdAt ?? this.createdAt,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      burnAfterRead: burnAfterRead ?? this.burnAfterRead,
      expiresAt: clearExpiresAt ? null : expiresAt ?? this.expiresAt,
      replyToMessageId:
          clearReplyTo ? null : replyToMessageId ?? this.replyToMessageId,
      replyToBody: clearReplyTo ? null : replyToBody ?? this.replyToBody,
      reactions: reactions ?? this.reactions,
      isStarred: isStarred ?? this.isStarred,
      editedAt: clearEditedAt ? null : editedAt ?? this.editedAt,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
      deleteMode: clearDeleteMode ? null : deleteMode ?? this.deleteMode,
      audioFilePath:
          clearAudioFilePath ? null : audioFilePath ?? this.audioFilePath,
      audioDurationMs: clearAudioDurationMs
          ? null
          : audioDurationMs ?? this.audioDurationMs,
        attachments: attachments ?? this.attachments,
    );
  }

  static String? encodeReactions(Map<String, List<String>> reactions) {
    if (reactions.isEmpty) {
      return null;
    }

    return jsonEncode(
      reactions.map(
        (emoji, users) => MapEntry(emoji, List<String>.from(users)),
      ),
    );
  }

  static Map<String, List<String>> decodeReactions(Object? rawValue) {
    if (rawValue == null) {
      return const {};
    }

    final encoded = rawValue as String;
    if (encoded.isEmpty) {
      return const {};
    }

    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    return decoded.map(
      (emoji, users) => MapEntry(
        emoji,
        List<String>.from(users as List<dynamic>),
      ),
    );
  }

  static String? encodeAttachments(List<Attachment> attachments) {
    if (attachments.isEmpty) {
      return null;
    }

    return jsonEncode(
      attachments.map((attachment) => attachment.toJson()).toList(growable: false),
    );
  }

  static List<Attachment> decodeAttachments(Object? rawValue) {
    if (rawValue == null) {
      return const [];
    }

    final encoded = rawValue as String;
    if (encoded.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded
        .map((entry) => Attachment.fromJson(Map<String, dynamic>.from(entry as Map)))
        .toList(growable: false);
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'body': body,
      'type': type.name,
      'delivery_state': deliveryState.name,
      'created_at': createdAt.toIso8601String(),
      'is_outgoing': isOutgoing ? 1 : 0,
      'burn_after_read': burnAfterRead ? 1 : 0,
      'expires_at': expiresAt?.toIso8601String(),
      'reply_to_message_id': replyToMessageId,
      'reply_to_body': replyToBody,
      'reactions_json': encodeReactions(reactions),
      'edited_at': editedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'delete_mode': deleteMode?.name,
      'audio_file_path': audioFilePath,
      'audio_duration_ms': audioDurationMs,
      'attachments_json': encodeAttachments(attachments),
    };
  }

  factory Message.fromMap(Map<String, Object?> map) {
    return Message(
      id: map['id']! as String,
      conversationId: map['conversation_id']! as String,
      senderId: map['sender_id']! as String,
      body: map['body']! as String,
      type: MessageType.values.byName(map['type']! as String),
      deliveryState: MessageDeliveryState.values.byName(
        map['delivery_state']! as String,
      ),
      createdAt: DateTime.parse(map['created_at']! as String),
      isOutgoing: (map['is_outgoing']! as int) == 1,
      burnAfterRead: (map['burn_after_read']! as int) == 1,
      expiresAt: map['expires_at'] == null
          ? null
          : DateTime.parse(map['expires_at']! as String),
      replyToMessageId: map['reply_to_message_id'] as String?,
      replyToBody: map['reply_to_body'] as String?,
      reactions: decodeReactions(map['reactions_json']),
      isStarred: (map['is_starred'] as int?) == 1,
      editedAt: map['edited_at'] == null
          ? null
          : DateTime.parse(map['edited_at']! as String),
      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.parse(map['deleted_at']! as String),
      deleteMode: map['delete_mode'] == null
          ? null
          : MessageDeleteMode.values.byName(map['delete_mode']! as String),
      audioFilePath: map['audio_file_path'] as String?,
      audioDurationMs: map['audio_duration_ms'] as int?,
      attachments: decodeAttachments(map['attachments_json']),
    );
  }
}

@immutable
class Attachment {
  const Attachment({
    required this.id,
    required this.type,
    required this.displayName,
    this.filePath,
    this.mimeType,
    this.sizeBytes,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final AttachmentType type;
  final String displayName;
  final String? filePath;
  final String? mimeType;
  final int? sizeBytes;
  final Map<String, Object?> metadata;

  bool get hasFilePath => filePath != null && filePath!.trim().isNotEmpty;
  bool get isMedia =>
      type == AttachmentType.image ||
      type == AttachmentType.video ||
      type == AttachmentType.audio;
  bool get isImage => type == AttachmentType.image;
  String get previewLabel {
    switch (type) {
      case AttachmentType.location:
        return 'Location';
      case AttachmentType.contactCard:
        return metadata['displayName'] as String? ?? 'Contact card';
      case AttachmentType.audio:
        return displayName.isEmpty ? 'Audio' : displayName;
      case AttachmentType.video:
        return displayName.isEmpty ? 'Video' : displayName;
      case AttachmentType.image:
        return displayName.isEmpty ? 'Image' : displayName;
      case AttachmentType.document:
        return displayName.isEmpty ? 'Document' : displayName;
    }
  }

  Attachment copyWith({
    String? id,
    AttachmentType? type,
    String? displayName,
    String? filePath,
    bool clearFilePath = false,
    String? mimeType,
    bool clearMimeType = false,
    int? sizeBytes,
    bool clearSizeBytes = false,
    Map<String, Object?>? metadata,
  }) {
    return Attachment(
      id: id ?? this.id,
      type: type ?? this.type,
      displayName: displayName ?? this.displayName,
      filePath: clearFilePath ? null : filePath ?? this.filePath,
      mimeType: clearMimeType ? null : mimeType ?? this.mimeType,
      sizeBytes: clearSizeBytes ? null : sizeBytes ?? this.sizeBytes,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'type': type.name,
      'displayName': displayName,
      'filePath': filePath,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'metadata': metadata,
    };
  }

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      type: AttachmentType.values.byName(json['type'] as String),
      displayName: json['displayName'] as String? ?? '',
      filePath: json['filePath'] as String?,
      mimeType: json['mimeType'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
      metadata: Map<String, Object?>.from(
        json['metadata'] as Map? ?? const <String, Object?>{},
      ),
    );
  }
}
