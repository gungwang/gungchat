import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/core/networking/signaling_service.dart';

void main() {
  test('round-trips call signaling envelope types', () {
    final envelope = SignalingEnvelope(
      type: SignalingEnvelopeType.callOffer,
      sessionId: 'call-session-1',
      payload: const {
        'sdp': 'offer-sdp',
        'kind': 'video',
      },
      sentAt: DateTime.utc(2026, 5, 16, 10, 0, 0),
    );

    final encoded = const ManualSignalingService().encode(envelope);
    final decoded = const ManualSignalingService().decode(encoded);

    expect(decoded.type, SignalingEnvelopeType.callOffer);
    expect(decoded.sessionId, 'call-session-1');
    expect(decoded.payload['sdp'], 'offer-sdp');
    expect(decoded.payload['kind'], 'video');
  });

  test('distinguishes peer-session and call signal types', () {
    expect(SignalingEnvelopeType.offer.isPeerSessionSignal, isTrue);
    expect(SignalingEnvelopeType.answer.isPeerSessionSignal, isTrue);
    expect(SignalingEnvelopeType.iceCandidate.isPeerSessionSignal, isTrue);

    expect(SignalingEnvelopeType.callOffer.isCallSignal, isTrue);
    expect(SignalingEnvelopeType.callAnswer.isCallSignal, isTrue);
    expect(SignalingEnvelopeType.callIceCandidate.isCallSignal, isTrue);
    expect(SignalingEnvelopeType.callDecline.isCallSignal, isTrue);
    expect(SignalingEnvelopeType.callHangup.isCallSignal, isTrue);
  });
}