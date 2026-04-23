import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/core/networking/signaling_service.dart';
import 'package:gungchat/features/chat/peer_invitation_builder.dart';
import 'package:gungchat/features/chat/peer_session_controller.dart';
import 'package:gungchat/models/contact.dart';

void main() {
  group('PeerInvitationBuilder', () {
    const builder = PeerInvitationBuilder();
    const contact = Contact(
      id: 'alice',
      displayName: 'Alice',
      fingerprint: 'aa:bb:cc:dd',
      lastKnownAddress: '192.168.1.24:45454',
    );

    test('describes connect flow before an offer exists', () {
      const state = PeerSessionState();

      final draft = builder.build(
        contact: contact,
        sessionState: state,
        manualUri: 'gungchat://192.168.1.24:45454?fingerprint=aa:bb:cc:dd',
      );

      expect(draft.hasOffer, isFalse);
      expect(draft.status, contains('generate a fresh offer'));
      expect(draft.steps.first, contains('Press Connect'));
    });

    test('builds clipboard text once an offer exists', () {
      final state = PeerSessionState(
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
      );

      final draft = builder.build(
        contact: contact,
        sessionState: state,
        manualUri: 'gungchat://192.168.1.24:45454?fingerprint=aa:bb:cc:dd',
      );

      expect(draft.hasOffer, isTrue);
      expect(draft.clipboardText, contains('offer-payload'));
      expect(draft.clipboardText, contains('ice-payload'));
      expect(draft.clipboardText, contains('192.168.1.24:45454'));
      expect(draft.clipboardText, contains('session-123'));
    });
  });
}