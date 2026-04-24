import 'dart:convert';

import 'package:flutter/foundation.dart';

enum MessageType {
  text,
  image,
  system,
}

enum MessageDeliveryState {
  local,
  sending,
  sent,
  delivered,
  read,
  failed,
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

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get hasReply => replyToBody != null && replyToBody!.trim().isNotEmpty;
  bool get hasReactions => reactions.isNotEmpty;

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
    );
  }
}
