import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/core/networking/signaling_service.dart';
import 'package:gungchat/core/networking/webrtc_manager.dart';
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

      expect(draft.kind, PeerInvitationDraftKind.connect);
      expect(draft.hasReadyBundle, isFalse);
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

      expect(draft.kind, PeerInvitationDraftKind.offer);
      expect(draft.hasReadyBundle, isTrue);
      expect(draft.clipboardText, contains('offer-payload'));
      expect(draft.clipboardText, contains('ice-payload'));
      expect(draft.clipboardText, contains('192.168.1.24:45454'));
      expect(draft.clipboardText, contains('session-123'));
    });

    test('builds reply text once an answer exists', () {
      final state = PeerSessionState(
        sessionId: 'session-456',
        expectedRemoteFingerprint: 'aa:bb:cc:dd',
        role: PeerSessionRole.responder,
        localSignals: [
          ShareableSignal(
            type: SignalingEnvelopeType.answer,
            encoded: 'answer-payload',
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

      expect(draft.kind, PeerInvitationDraftKind.reply);
      expect(draft.hasReadyBundle, isTrue);
      expect(draft.isReply, isTrue);
      expect(draft.copyActionLabel, 'Copy Reply');
      expect(draft.clipboardText, contains('GungChat connection reply'));
      expect(draft.clipboardText, contains('answer-payload'));
      expect(draft.clipboardText, contains('ice-payload'));
    });

    test('offers a fresh connect path when an old reply session failed', () {
      final state = PeerSessionState(
        sessionId: 'session-789',
        expectedRemoteFingerprint: 'aa:bb:cc:dd',
        role: PeerSessionRole.responder,
        connectionState: WebRtcSessionState.failed,
        localSignals: [
          ShareableSignal(
            type: SignalingEnvelopeType.answer,
            encoded: 'stale-answer-payload',
            createdAt: DateTime(2026, 4, 23),
          ),
        ],
      );

      final draft = builder.build(
        contact: contact,
        sessionState: state,
        manualUri: 'gungchat://192.168.1.24:45454?fingerprint=aa:bb:cc:dd',
      );

      expect(draft.kind, PeerInvitationDraftKind.connect);
      expect(draft.hasReadyBundle, isFalse);
      expect(draft.status, contains('fresh offer'));
    });

    test('offers a fresh connect path when an old offer session failed', () {
      final state = PeerSessionState(
        sessionId: 'session-abc',
        expectedRemoteFingerprint: 'aa:bb:cc:dd',
        role: PeerSessionRole.initiator,
        connectionState: WebRtcSessionState.failed,
        localSignals: [
          ShareableSignal(
            type: SignalingEnvelopeType.offer,
            encoded: 'stale-offer-payload',
            createdAt: DateTime(2026, 4, 23),
          ),
        ],
      );

      final draft = builder.build(
        contact: contact,
        sessionState: state,
        manualUri: 'gungchat://192.168.1.24:45454?fingerprint=aa:bb:cc:dd',
      );

      expect(draft.kind, PeerInvitationDraftKind.connect);
      expect(draft.hasReadyBundle, isFalse);
      expect(draft.clipboardText, isEmpty);
    });
  });
}
