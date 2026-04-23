import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/core/networking/signaling_service.dart';
import 'package:gungchat/features/chat/peer_invitation_builder.dart';
import 'package:gungchat/features/chat/peer_invitation_parser.dart';
import 'package:gungchat/features/chat/peer_session_controller.dart';
import 'package:gungchat/models/contact.dart';

void main() {
  group('PeerInvitationParser', () {
    const parser = PeerInvitationParser();
    const builder = PeerInvitationBuilder();
    const contact = Contact(
      id: 'alice',
      displayName: 'Alice',
      fingerprint: 'aa:bb:cc:dd',
      lastKnownAddress: '192.168.1.24:45454',
    );

    test('parses the current invite format built by the app', () {
      final draft = builder.build(
        contact: contact,
        sessionState: PeerSessionState(
          sessionId: 'session-123',
          expectedRemoteFingerprint: 'aa:bb:cc:dd',
          localSignals: [
            ShareableSignal(
              type: SignalingEnvelopeType.offer,
              encoded: 'offer-payload',
              createdAt: DateTime(2026, 4, 23),
            ),
            ShareableSignal(
              type: SignalingEnvelopeType.iceCandidate,
              encoded: 'ice-payload',
              createdAt: DateTime(2026, 4, 23),
            ),
          ],
        ),
        manualUri: 'gungchat://192.168.1.24:45454?fingerprint=aa:bb:cc:dd',
      );

      final parsed = parser.parse(draft.clipboardText);

      expect(parsed.kind, PeerInvitationKind.invite);
      expect(parsed.displayName, 'Alice');
      expect(parsed.expectedFingerprint, 'aa:bb:cc:dd');
      expect(parsed.savedAddress, '192.168.1.24:45454');
      expect(parsed.manualUriText,
          'gungchat://192.168.1.24:45454?fingerprint=aa:bb:cc:dd');
      expect(parsed.sessionId, 'session-123');
      expect(parsed.offerSignal, 'offer-payload');
      expect(parsed.iceSignals, ['ice-payload']);
      expect(parsed.toContact(), isNotNull);
      expect(parsed.toContact()!.lastKnownAddress, '192.168.1.24:45454');
    });

    test('parses reply text with answer and multiple ice payloads', () {
      const raw = '''
GungChat connection reply
Contact: Alice
Expected fingerprint: aa:bb:cc:dd
Session: session-456

Remote steps:
1. Copy this reply back to the offer sender.
2. They should apply the ANSWER first.

ANSWER:
answer-payload

ICE PAYLOADS:
ice-one
ice-two
''';

      final parsed = parser.parse(raw);

      expect(parsed.kind, PeerInvitationKind.reply);
      expect(parsed.answerSignal, 'answer-payload');
      expect(parsed.iceSignals, ['ice-one', 'ice-two']);
      expect(parsed.signalsInApplyOrder, ['answer-payload', 'ice-one', 'ice-two']);
    });
  });
}