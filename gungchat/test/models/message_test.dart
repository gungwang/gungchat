import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/models/message.dart';

void main() {
  test('Message.fromMap reads derived star state', () {
    final message = Message.fromMap({
      'id': 'message-1',
      'conversation_id': 'bootstrap',
      'sender_id': 'peer-a',
      'body': 'starred message',
      'type': 'text',
      'delivery_state': 'sent',
      'created_at': DateTime.utc(2026, 4, 23, 12, 0, 0).toIso8601String(),
      'is_outgoing': 1,
      'burn_after_read': 1,
      'expires_at': null,
      'reply_to_message_id': null,
      'reply_to_body': null,
      'reactions_json': null,
      'is_starred': 1,
    });

    expect(message.isStarred, isTrue);
  });

  test('Message.fromMap reads edit and delete metadata', () {
    final message = Message.fromMap({
      'id': 'message-2',
      'conversation_id': 'secure-peer',
      'sender_id': 'peer-a',
      'body': '',
      'type': 'text',
      'delivery_state': 'read',
      'created_at': DateTime.utc(2026, 4, 23, 12, 0, 0).toIso8601String(),
      'is_outgoing': 1,
      'burn_after_read': 0,
      'expires_at': null,
      'reply_to_message_id': null,
      'reply_to_body': null,
      'reactions_json': null,
      'edited_at': DateTime.utc(2026, 4, 23, 12, 2, 0).toIso8601String(),
      'deleted_at': DateTime.utc(2026, 4, 23, 12, 3, 0).toIso8601String(),
      'delete_mode': 'tombstone',
      'is_starred': 0,
    });

    expect(message.isEdited, isFalse);
    expect(message.isDeleted, isTrue);
    expect(message.deleteMode, MessageDeleteMode.tombstone);
    expect(message.editedAt, isNotNull);
    expect(message.deletedAt, isNotNull);
  });
}