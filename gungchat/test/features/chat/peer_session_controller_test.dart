import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/core/encryption/crypto_service.dart';
import 'package:gungchat/core/encryption/key_manager.dart';
import 'package:gungchat/core/networking/ice_manager.dart';
import 'package:gungchat/core/networking/signaling_service.dart';
import 'package:gungchat/core/networking/webrtc_manager.dart';
import 'package:gungchat/features/chat/presence_status.dart';
import 'package:gungchat/features/chat/peer_session_controller.dart';
import 'package:gungchat/features/chat/reaction_service.dart';
import 'package:gungchat/features/chat/voice_message_service.dart';
import 'package:gungchat/features/chat/attachment_message_service.dart';
import 'package:gungchat/features/chat/message_service.dart';
import 'package:gungchat/features/contacts/contact_exchange_service.dart';
import 'package:gungchat/features/contacts/discovery_service.dart';
import 'package:gungchat/models/message.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' hide MessageType;

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

  group('PeerSessionController', () {
    test('sends hello automatically when QR-initiated session opens', () async {
      final cryptoService = CryptoService();
      final localIdentity = await _buildIdentity(cryptoService);
      final remoteIdentity = await _buildIdentity(cryptoService);
      final remoteContactCard = ContactCard(
        displayName: 'Device B',
        fingerprint: remoteIdentity.fingerprint,
        addresses: const ['192.168.1.25'],
        port: DiscoveryService.discoveryPort,
      );
      final remoteContact =
          const ContactExchangeService().contactFromCard(remoteContactCard);
      final webRtcManager = _FakeWebRtcManager();
      final messageService = _FakeMessageService(
        cryptoService: cryptoService,
      );
      final controller = PeerSessionController(
        loadIdentity: () async => localIdentity,
        loadMessageService: () async => messageService,
        loadVoiceMessageService: () => _UnusedVoiceMessageService(),
        loadAttachmentMessageService: () => _UnusedAttachmentMessageService(),
        refreshConversation: (_) {},
        reactionService: const ReactionService(),
        webRtcManager: webRtcManager,
        signalingService: const ManualSignalingService(),
        cryptoService: cryptoService,
        dispatchLocalSignal: ({
          required encodedSignal,
          required targetAddress,
        }) async {},
        isBlockedFingerprint: (_) => false,
      );
      addTearDown(controller.dispose);
      addTearDown(webRtcManager.dispose);

      await controller.startOffer(targetContact: remoteContact);
      final answer = SignalingEnvelope(
        type: SignalingEnvelopeType.answer,
        sessionId: controller.state.sessionId!,
        payload: {
          'description': RTCSessionDescription('answer-sdp', 'answer').toMap(),
          'identity': {
            'publicKey': base64Encode(remoteIdentity.publicKey),
            'fingerprint': remoteIdentity.fingerprint,
          },
        },
        sentAt: DateTime.now(),
      );
      await controller.applyRemoteSignal(
        const ManualSignalingService().encode(answer),
        targetContact: remoteContact,
      );

      webRtcManager.emitState(WebRtcSessionState.open);
      await Future<void>.delayed(Duration.zero);

      expect(messageService.createdLocalBodies, ['hello']);
      expect(webRtcManager.sentTexts, hasLength(1));
      expect(controller.state.lastEvent, 'Secure message sent.');
    });
  });
}

Future<DeviceIdentity> _buildIdentity(CryptoService cryptoService) async {
  final keyPair = await cryptoService.generateIdentityKeyPair();
  final publicKey = Uint8List.fromList(keyPair.publicKey.bytes);
  final privateKey = Uint8List.fromList(keyPair.bytes);
  final digest = await Sha256().hash(publicKey);
  final fingerprint = digest.bytes
      .take(8)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join(':');

  return DeviceIdentity(
    publicKey: publicKey,
    privateKey: privateKey,
    fingerprint: fingerprint,
  );
}

class _FakeWebRtcManager extends WebRtcManager {
  _FakeWebRtcManager() : super(iceManager: const IceManager());

  final StreamController<WebRtcSessionState> _states =
      StreamController<WebRtcSessionState>.broadcast();
  final List<String> sentTexts = <String>[];

  @override
  Stream<WebRtcSessionState> get states => _states.stream;

  @override
  bool get isOpen => true;

  @override
  Future<void> initialize({
    required bool initiator,
    required void Function(String message) onMessage,
    void Function(RTCIceCandidate candidate)? onIceCandidate,
  }) async {}

  @override
  Future<RTCSessionDescription> createOffer() async {
    return RTCSessionDescription('offer-sdp', 'offer');
  }

  @override
  Future<void> applyRemoteDescription(RTCSessionDescription description) async {}

  @override
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {}

  @override
  Future<void> sendText(String message) async {
    sentTexts.add(message);
  }

  @override
  Future<void> close() async {}

  void emitState(WebRtcSessionState state) {
    _states.add(state);
  }

  void dispose() {
    _states.close();
  }
}

class _FakeMessageService implements MessageService {
  _FakeMessageService({required CryptoService cryptoService})
      : _cryptoService = cryptoService;

  final CryptoService _cryptoService;
  final List<String> createdLocalBodies = <String>[];
  final Map<String, MessageDeliveryState> deliveryStates =
      <String, MessageDeliveryState>{};

  @override
  Future<Message> createLocalMessage({
    required String conversationId,
    required String senderId,
    required String body,
    MessageType type = MessageType.text,
    bool burnAfterRead = true,
    Duration? ttl,
    MessageDeliveryState deliveryState = MessageDeliveryState.local,
    String? replyToMessageId,
    String? replyToBody,
    String? audioFilePath,
    int? audioDurationMs,
    List<Attachment> attachments = const <Attachment>[],
  }) async {
    createdLocalBodies.add(body);
    final message = Message(
      id: 'message-${createdLocalBodies.length}',
      conversationId: conversationId,
      senderId: senderId,
      body: body,
      type: type,
      deliveryState: deliveryState,
      createdAt: DateTime.now(),
      isOutgoing: true,
      burnAfterRead: burnAfterRead,
      expiresAt: null,
      replyToMessageId: replyToMessageId,
      replyToBody: replyToBody,
      audioFilePath: audioFilePath,
      audioDurationMs: audioDurationMs,
      attachments: attachments,
    );
    deliveryStates[message.id] = deliveryState;
    return message;
  }

  @override
  Future<EncryptedPayload> encryptForTransport({
    required String body,
    required SecretKey sharedSecret,
  }) {
    return _cryptoService.encryptString(
      plaintext: body,
      secretKey: sharedSecret,
    );
  }

  @override
  Future<void> updateDeliveryState(
    String messageId,
    MessageDeliveryState deliveryState,
  ) async {
    deliveryStates[messageId] = deliveryState;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedVoiceMessageService implements VoiceMessageService {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedAttachmentMessageService implements AttachmentMessageService {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
