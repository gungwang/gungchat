import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/core/encryption/crypto_service.dart';
import 'package:gungchat/features/chat/presence_status.dart';
import 'package:gungchat/features/chat/peer_session_controller.dart';
import 'package:gungchat/models/message.dart';

void main() {
  group('PeerTransportEnvelope', () {
    final payload = EncryptedPayload(
      nonce: Uint8List.fromList(const [1, 2, 3]),
      cipherText: Uint8List.fromList(const [4, 5, 6]),
      mac: Uint8List.fromList(const [7, 8, 9]),
    );

    test('round-trips secure message envelopes', () {
      final envelope = PeerTransportEnvelope.message(
        messageId: 'message-1',
        senderFingerprint: 'aa:bb:cc:dd',
        payload: payload,
        createdAt: DateTime.utc(2025, 1, 2, 3, 4, 5),
        burnAfterRead: true,
        replyToMessageId: 'message-0',
        replyToBody: 'earlier encrypted message',
      );

      final decoded = PeerTransportEnvelope.decodeTransportString(
        envelope.encodeTransportString(),
      );

      expect(decoded.kind, PeerTransportEnvelopeKind.message);
      expect(decoded.messageId, 'message-1');
      expect(decoded.senderFingerprint, 'aa:bb:cc:dd');
      expect(decoded.burnAfterRead, isTrue);
      expect(decoded.replyToMessageId, 'message-0');
      expect(decoded.replyToBody, 'earlier encrypted message');
      expect(decoded.payload, isNotNull);
      expect(decoded.payload!.cipherText, payload.cipherText);
    });

    test('round-trips typing envelopes', () {
      final envelope = PeerTransportEnvelope.typing(
        senderFingerprint: 'ff:ee:dd:cc',
        createdAt: DateTime.utc(2025, 1, 2, 3, 4, 5),
        isTyping: true,
      );

      final decoded = PeerTransportEnvelope.decodeTransportString(
        envelope.encodeTransportString(),
      );

      expect(decoded.kind, PeerTransportEnvelopeKind.typing);
      expect(decoded.senderFingerprint, 'ff:ee:dd:cc');
      expect(decoded.isTyping, isTrue);
      expect(decoded.messageId, isNull);
      expect(decoded.payload, isNull);
    });

    test('round-trips delivery receipt envelopes', () {
      final envelope = PeerTransportEnvelope.receipt(
        messageId: 'message-2',
        senderFingerprint: '55:66:77:88',
        createdAt: DateTime.utc(2025, 1, 2, 3, 4, 5),
        receiptState: MessageDeliveryState.delivered,
      );

      final decoded = PeerTransportEnvelope.decodeTransportString(
        envelope.encodeTransportString(),
      );

      expect(decoded.kind, PeerTransportEnvelopeKind.receipt);
      expect(decoded.messageId, 'message-2');
      expect(decoded.senderFingerprint, '55:66:77:88');
      expect(decoded.receiptState, MessageDeliveryState.delivered);
      expect(decoded.payload, isNull);
      expect(decoded.isTyping, isNull);
    });

    test('round-trips presence envelopes', () {
      final envelope = PeerTransportEnvelope.presence(
        senderFingerprint: '12:34:56:78',
        createdAt: DateTime.utc(2025, 1, 2, 3, 4, 5),
        presenceStatus: PeerPresenceStatus.away,
      );

      final decoded = PeerTransportEnvelope.decodeTransportString(
        envelope.encodeTransportString(),
      );

      expect(decoded.kind, PeerTransportEnvelopeKind.presence);
      expect(decoded.senderFingerprint, '12:34:56:78');
      expect(decoded.presenceStatus, PeerPresenceStatus.away);
      expect(decoded.payload, isNull);
      expect(decoded.isTyping, isNull);
      expect(decoded.receiptState, isNull);
    });

    test('round-trips custom status text envelopes', () {
      final envelope = PeerTransportEnvelope.statusText(
        senderFingerprint: '22:33:44:55',
        createdAt: DateTime.utc(2025, 1, 2, 3, 4, 5),
        statusText: 'In a meeting',
      );

      final decoded = PeerTransportEnvelope.decodeTransportString(
        envelope.encodeTransportString(),
      );

      expect(decoded.kind, PeerTransportEnvelopeKind.statusText);
      expect(decoded.senderFingerprint, '22:33:44:55');
      expect(decoded.statusText, 'In a meeting');
    });

    test('round-trips read receipt envelopes', () {
      final envelope = PeerTransportEnvelope.receipt(
        messageId: 'message-3',
        senderFingerprint: '99:aa:bb:cc',
        createdAt: DateTime.utc(2025, 1, 2, 3, 4, 5),
        receiptState: MessageDeliveryState.read,
      );

      final decoded = PeerTransportEnvelope.decodeTransportString(
        envelope.encodeTransportString(),
      );

      expect(decoded.kind, PeerTransportEnvelopeKind.receipt);
      expect(decoded.messageId, 'message-3');
      expect(decoded.receiptState, MessageDeliveryState.read);
    });

    test('round-trips reaction envelopes', () {
      final envelope = PeerTransportEnvelope.reaction(
        messageId: 'message-4',
        senderFingerprint: '00:11:22:33',
        createdAt: DateTime.utc(2025, 1, 2, 3, 4, 5),
        reactions: const {
          '👍': ['00:11:22:33'],
          '❤️': ['44:55:66:77', '00:11:22:33'],
        },
      );

      final decoded = PeerTransportEnvelope.decodeTransportString(
        envelope.encodeTransportString(),
      );

      expect(decoded.kind, PeerTransportEnvelopeKind.reaction);
      expect(decoded.messageId, 'message-4');
      expect(decoded.reactions, const {
        '👍': ['00:11:22:33'],
        '❤️': ['44:55:66:77', '00:11:22:33'],
      });
    });

    test('round-trips message edit envelopes', () {
      final envelope = PeerTransportEnvelope.messageEdit(
        messageId: 'message-5',
        senderFingerprint: 'ab:cd:ef:12',
        createdAt: DateTime.utc(2025, 1, 2, 3, 4, 5),
        content: 'updated body',
      );

      final decoded = PeerTransportEnvelope.decodeTransportString(
        envelope.encodeTransportString(),
      );

      expect(decoded.kind, PeerTransportEnvelopeKind.messageEdit);
      expect(decoded.messageId, 'message-5');
      expect(decoded.content, 'updated body');
    });

    test('round-trips message delete envelopes', () {
      final envelope = PeerTransportEnvelope.messageDelete(
        messageId: 'message-6',
        senderFingerprint: 'ab:cd:ef:34',
        createdAt: DateTime.utc(2025, 1, 2, 3, 4, 5),
        deleteMode: MessageDeleteMode.hardDelete,
      );

      final decoded = PeerTransportEnvelope.decodeTransportString(
        envelope.encodeTransportString(),
      );

      expect(decoded.kind, PeerTransportEnvelopeKind.messageDelete);
      expect(decoded.messageId, 'message-6');
      expect(decoded.deleteMode, MessageDeleteMode.hardDelete);
    });

    test('decodes legacy message envelopes without kind', () {
      final legacyJson = jsonEncode({
        'messageId': 'legacy-message',
        'senderFingerprint': '11:22:33:44',
        'payload': payload.toJson(),
        'createdAt': DateTime.utc(2025, 1, 2, 3, 4, 5).toIso8601String(),
        'burnAfterRead': false,
      });

      final decoded =
          PeerTransportEnvelope.decodeTransportString(legacyJson);

      expect(decoded.kind, PeerTransportEnvelopeKind.message);
      expect(decoded.messageId, 'legacy-message');
      expect(decoded.burnAfterRead, isFalse);
      expect(decoded.payload, isNotNull);
    });
  });
}