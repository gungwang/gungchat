import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/core/encryption/crypto_service.dart';
import 'package:gungchat/features/chat/peer_session_controller.dart';

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
      );

      final decoded = PeerTransportEnvelope.decodeTransportString(
        envelope.encodeTransportString(),
      );

      expect(decoded.kind, PeerTransportEnvelopeKind.message);
      expect(decoded.messageId, 'message-1');
      expect(decoded.senderFingerprint, 'aa:bb:cc:dd');
      expect(decoded.burnAfterRead, isTrue);
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