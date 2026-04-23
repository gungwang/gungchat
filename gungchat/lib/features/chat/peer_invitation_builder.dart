import '../../core/networking/signaling_service.dart';
import '../../models/contact.dart';
import 'peer_session_controller.dart';

class PeerInvitationDraft {
  const PeerInvitationDraft({
    required this.title,
    required this.status,
    required this.steps,
    required this.clipboardText,
    required this.hasOffer,
    this.manualUri,
  });

  final String title;
  final String status;
  final List<String> steps;
  final String clipboardText;
  final bool hasOffer;
  final String? manualUri;
}

class PeerInvitationBuilder {
  const PeerInvitationBuilder();

  PeerInvitationDraft build({
    required Contact contact,
    required PeerSessionState sessionState,
    String? manualUri,
  }) {
    final isTargetingContact = sessionState.expectedRemoteFingerprint == null
        ? sessionState.remoteFingerprint == contact.fingerprint
        : sessionState.expectedRemoteFingerprint == contact.fingerprint;
    final offerSignal = isTargetingContact
        ? _latestSignal(sessionState, SignalingEnvelopeType.offer)
        : null;
    final iceSignals = isTargetingContact
        ? _signals(sessionState, SignalingEnvelopeType.iceCandidate)
        : const <String>[];

    final title = 'Invite ${contact.displayName}';
    if (offerSignal == null) {
      return PeerInvitationDraft(
        title: title,
        status: contact.lastKnownAddress == null
            ? 'Connect will generate a fresh offer for ${contact.displayName}. They do not have a saved address yet, so share the invite through QR or another side channel.'
            : 'Connect will generate a fresh offer for ${contact.displayName} and target ${contact.lastKnownAddress} first.',
        steps: [
          'Press Connect to generate a fresh offer for this contact.',
          if (contact.lastKnownAddress != null)
            'Use the saved address ${contact.lastKnownAddress} as the first route to try.',
          'Copy the invitation once the offer is ready and send it to ${contact.displayName}.',
          'Paste their answer and ICE payloads here until the secure channel opens.',
        ],
        clipboardText: '',
        hasOffer: false,
        manualUri: manualUri,
      );
    }

    return PeerInvitationDraft(
      title: title,
      status: 'Offer ready. Send the invitation text to ${contact.displayName}, then paste their answer and any ICE payloads below.',
      steps: [
        'Send the invitation text to ${contact.displayName}.',
        'Have them open GungChat and apply the OFFER first.',
        'Paste their ANSWER here when they send it back.',
        'Keep exchanging ICE payloads until the secure channel opens.',
      ],
      clipboardText: _buildClipboardText(
        contact: contact,
        sessionState: sessionState,
        manualUri: manualUri,
        offerSignal: offerSignal,
        iceSignals: iceSignals,
      ),
      hasOffer: true,
      manualUri: manualUri,
    );
  }

  String? _latestSignal(
    PeerSessionState sessionState,
    SignalingEnvelopeType type,
  ) {
    for (final signal in sessionState.localSignals.reversed) {
      if (signal.type == type) {
        return signal.encoded;
      }
    }
    return null;
  }

  List<String> _signals(
    PeerSessionState sessionState,
    SignalingEnvelopeType type,
  ) {
    return [
      for (final signal in sessionState.localSignals)
        if (signal.type == type) signal.encoded,
    ];
  }

  String _buildClipboardText({
    required Contact contact,
    required PeerSessionState sessionState,
    required String? manualUri,
    required String offerSignal,
    required List<String> iceSignals,
  }) {
    final buffer = StringBuffer()
      ..writeln('GungChat connection invite')
      ..writeln('Contact: ${contact.displayName}')
      ..writeln('Expected fingerprint: ${contact.fingerprint}');

    if (contact.lastKnownAddress != null) {
      buffer.writeln('Saved address: ${contact.lastKnownAddress}');
    }
    if (manualUri != null) {
      buffer.writeln('Manual URI: $manualUri');
    }
    if (sessionState.sessionId != null) {
      buffer.writeln('Session: ${sessionState.sessionId}');
    }

    buffer
      ..writeln()
      ..writeln('Remote steps:')
      ..writeln('1. Open GungChat and select our contact.')
      ..writeln('2. Apply the OFFER below.')
      ..writeln('3. Send back your ANSWER and any ICE payloads.')
      ..writeln('4. Keep exchanging ICE payloads until the secure channel opens.')
      ..writeln()
      ..writeln('OFFER:')
      ..writeln(offerSignal);

    if (iceSignals.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('ICE PAYLOADS:');
      for (final signal in iceSignals) {
        buffer.writeln(signal);
      }
    }

    return buffer.toString().trimRight();
  }
}