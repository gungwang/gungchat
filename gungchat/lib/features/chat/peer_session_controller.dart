import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' hide MessageType;
import 'package:uuid/uuid.dart';

import '../../core/encryption/crypto_service.dart';
import '../../core/encryption/key_manager.dart';
import '../../core/networking/signaling_service.dart';
import '../../core/networking/webrtc_manager.dart';
import '../../models/message.dart';
import 'message_service.dart';

typedef LoadLocalIdentity = Future<DeviceIdentity> Function();
typedef LoadMessageService = Future<MessageService> Function();
typedef RefreshConversationMessages = void Function(String conversationId);

enum PeerSessionRole {
  initiator,
  responder,
}

@immutable
class ShareableSignal {
  const ShareableSignal({
    required this.type,
    required this.encoded,
    required this.createdAt,
  });

  final SignalingEnvelopeType type;
  final String encoded;
  final DateTime createdAt;

  String get label {
    switch (type) {
      case SignalingEnvelopeType.offer:
        return 'Offer';
      case SignalingEnvelopeType.answer:
        return 'Answer';
      case SignalingEnvelopeType.iceCandidate:
        return 'ICE';
    }
  }
}

@immutable
class PeerSessionState {
  const PeerSessionState({
    this.sessionId,
    this.role,
    this.connectionState = WebRtcSessionState.idle,
    this.localSignals = const [],
    this.remoteFingerprint,
    this.conversationId,
    this.hasSharedSecret = false,
    this.isApplyingSignal = false,
    this.lastError,
    this.lastEvent,
    this.pendingRemoteIceCount = 0,
  });

  final String? sessionId;
  final PeerSessionRole? role;
  final WebRtcSessionState connectionState;
  final List<ShareableSignal> localSignals;
  final String? remoteFingerprint;
  final String? conversationId;
  final bool hasSharedSecret;
  final bool isApplyingSignal;
  final String? lastError;
  final String? lastEvent;
  final int pendingRemoteIceCount;

  bool get isSessionActive => sessionId != null;

  bool get isTransportReady =>
      connectionState == WebRtcSessionState.open &&
      hasSharedSecret &&
      conversationId != null;

  PeerSessionState copyWith({
    Object? sessionId = _sentinel,
    Object? role = _sentinel,
    WebRtcSessionState? connectionState,
    List<ShareableSignal>? localSignals,
    Object? remoteFingerprint = _sentinel,
    Object? conversationId = _sentinel,
    bool? hasSharedSecret,
    bool? isApplyingSignal,
    Object? lastError = _sentinel,
    Object? lastEvent = _sentinel,
    int? pendingRemoteIceCount,
  }) {
    return PeerSessionState(
      sessionId: identical(sessionId, _sentinel)
          ? this.sessionId
          : sessionId as String?,
      role: identical(role, _sentinel) ? this.role : role as PeerSessionRole?,
      connectionState: connectionState ?? this.connectionState,
      localSignals: localSignals ?? this.localSignals,
      remoteFingerprint: identical(remoteFingerprint, _sentinel)
          ? this.remoteFingerprint
          : remoteFingerprint as String?,
      conversationId: identical(conversationId, _sentinel)
          ? this.conversationId
          : conversationId as String?,
      hasSharedSecret: hasSharedSecret ?? this.hasSharedSecret,
      isApplyingSignal: isApplyingSignal ?? this.isApplyingSignal,
      lastError: identical(lastError, _sentinel)
          ? this.lastError
          : lastError as String?,
      lastEvent: identical(lastEvent, _sentinel)
          ? this.lastEvent
          : lastEvent as String?,
      pendingRemoteIceCount:
          pendingRemoteIceCount ?? this.pendingRemoteIceCount,
    );
  }
}

class PeerSessionController extends StateNotifier<PeerSessionState> {
  PeerSessionController({
    required LoadLocalIdentity loadIdentity,
    required LoadMessageService loadMessageService,
    required RefreshConversationMessages refreshConversation,
    required WebRtcManager webRtcManager,
    required ManualSignalingService signalingService,
    required CryptoService cryptoService,
    Uuid? uuid,
  })  : _loadIdentity = loadIdentity,
        _loadMessageService = loadMessageService,
        _refreshConversation = refreshConversation,
        _webRtcManager = webRtcManager,
        _signalingService = signalingService,
        _cryptoService = cryptoService,
        _uuid = uuid ?? const Uuid(),
        super(const PeerSessionState()) {
    _stateSubscription = _webRtcManager.states.listen(_handleTransportState);
  }

  final LoadLocalIdentity _loadIdentity;
  final LoadMessageService _loadMessageService;
  final RefreshConversationMessages _refreshConversation;
  final WebRtcManager _webRtcManager;
  final ManualSignalingService _signalingService;
  final CryptoService _cryptoService;
  final Uuid _uuid;

  StreamSubscription<WebRtcSessionState>? _stateSubscription;

  DeviceIdentity? _localIdentity;
  SecretKey? _sharedSecret;
  bool _peerConnectionReady = false;
  bool _hasRemoteDescription = false;
  final List<RTCIceCandidate> _pendingRemoteIceCandidates = [];

  Future<void> startOffer() async {
    final identity = await _ensureLocalIdentity();
    final sessionId = _uuid.v4();

    state = PeerSessionState(
      sessionId: sessionId,
      role: PeerSessionRole.initiator,
      connectionState: WebRtcSessionState.connecting,
      lastEvent: 'Offer is being prepared for manual sharing.',
    );

    try {
      await _configureTransport(initiator: true);
      final offer = await _webRtcManager.createOffer();
      _appendLocalSignal(
        SignalingEnvelope(
          type: SignalingEnvelopeType.offer,
          sessionId: sessionId,
          payload: _descriptionPayload(offer, identity),
          sentAt: DateTime.now(),
        ),
      );
      state = state.copyWith(
        lastEvent:
            'Offer ready. Share it with your peer, then paste the answer and ICE payloads here.',
      );
    } catch (error) {
      _setError('Could not start an offer: $error');
    }
  }

  Future<void> applyRemoteSignal(String rawValue) async {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      _setError('Paste an offer, answer, or ICE payload before applying it.');
      return;
    }

    state = state.copyWith(isApplyingSignal: true, lastError: null);

    try {
      final envelope = _signalingService.decode(trimmed);
      switch (envelope.type) {
        case SignalingEnvelopeType.offer:
          await _applyRemoteOffer(envelope);
        case SignalingEnvelopeType.answer:
          await _applyRemoteAnswer(envelope);
        case SignalingEnvelopeType.iceCandidate:
          await _applyRemoteIceCandidate(envelope);
      }
    } catch (error) {
      _setError('Could not apply the remote signal: $error');
    } finally {
      state = state.copyWith(isApplyingSignal: false);
    }
  }

  Future<bool> sendMessage({
    required String body,
    required bool burnAfterRead,
  }) async {
    final conversationId = state.conversationId;
    final sharedSecret = _sharedSecret;
    if (conversationId == null ||
        sharedSecret == null ||
        !state.isTransportReady) {
      _setError(
        'The secure data channel is not open yet. Finish the signal exchange first.',
      );
      return false;
    }

    final identity = await _ensureLocalIdentity();
    final messageService = await _loadMessageService();

    final message = await messageService.createLocalMessage(
      conversationId: conversationId,
      senderId: identity.fingerprint,
      body: body,
      burnAfterRead: burnAfterRead,
      deliveryState: MessageDeliveryState.sending,
    );
    _refreshConversation(conversationId);

    try {
      final encryptedPayload = await messageService.encryptForTransport(
        body: body,
        sharedSecret: sharedSecret,
      );
      final transportEnvelope = PeerTransportEnvelope(
        messageId: message.id,
        senderFingerprint: identity.fingerprint,
        payload: encryptedPayload,
        createdAt: message.createdAt,
        burnAfterRead: burnAfterRead,
        expiresAt: message.expiresAt,
      );

      await _webRtcManager.sendText(transportEnvelope.encodeTransportString());
      await messageService.updateDeliveryState(
        message.id,
        MessageDeliveryState.sent,
      );
      _refreshConversation(conversationId);
      state = state.copyWith(lastEvent: 'Secure message sent.');
      return true;
    } catch (error) {
      await messageService.updateDeliveryState(
        message.id,
        MessageDeliveryState.failed,
      );
      _refreshConversation(conversationId);
      _setError('Secure send failed: $error');
      return false;
    }
  }

  Future<void> resetSession() async {
    _sharedSecret = null;
    _peerConnectionReady = false;
    _hasRemoteDescription = false;
    _pendingRemoteIceCandidates.clear();
    await _webRtcManager.close();
    state = const PeerSessionState();
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _applyRemoteOffer(SignalingEnvelope envelope) async {
    final identity = await _ensureLocalIdentity();

    if (state.sessionId != envelope.sessionId ||
        state.role != PeerSessionRole.responder ||
        !_peerConnectionReady) {
      state = PeerSessionState(
        sessionId: envelope.sessionId,
        role: PeerSessionRole.responder,
        connectionState: WebRtcSessionState.connecting,
        lastEvent: 'Remote offer loaded. Preparing an answer.',
      );
      await _configureTransport(initiator: false);
    }

    await _establishSharedSecret(
      localIdentity: identity,
      payload: envelope.payload,
    );

    final answer = await _webRtcManager.createAnswer(
      _sessionDescriptionFromPayload(envelope.payload),
    );
    _hasRemoteDescription = true;
    await _flushPendingRemoteIceCandidates();

    _appendLocalSignal(
      SignalingEnvelope(
        type: SignalingEnvelopeType.answer,
        sessionId: envelope.sessionId,
        payload: _descriptionPayload(answer, identity),
        sentAt: DateTime.now(),
      ),
    );

    state = state.copyWith(
      lastEvent:
          'Answer ready. Share it back, then keep exchanging ICE payloads until the channel opens.',
    );
  }

  Future<void> _applyRemoteAnswer(SignalingEnvelope envelope) async {
    if (state.sessionId == null ||
        state.sessionId != envelope.sessionId ||
        state.role != PeerSessionRole.initiator) {
      throw StateError('Start an offer before applying an answer.');
    }

    if (!_peerConnectionReady) {
      throw StateError('The local peer connection is not ready yet.');
    }

    final identity = await _ensureLocalIdentity();
    await _establishSharedSecret(
      localIdentity: identity,
      payload: envelope.payload,
    );

    await _webRtcManager.applyRemoteDescription(
      _sessionDescriptionFromPayload(envelope.payload),
    );
    _hasRemoteDescription = true;
    await _flushPendingRemoteIceCandidates();

    state = state.copyWith(
      lastEvent:
          'Answer applied. Add any remaining ICE payloads while the secure channel finishes connecting.',
    );
  }

  Future<void> _applyRemoteIceCandidate(SignalingEnvelope envelope) async {
    if (state.sessionId == null || state.sessionId != envelope.sessionId) {
      throw StateError('This ICE payload does not match the active session.');
    }

    final candidate = _iceCandidateFromPayload(envelope.payload);

    if (!_peerConnectionReady || !_hasRemoteDescription) {
      _pendingRemoteIceCandidates.add(candidate);
      state = state.copyWith(
        pendingRemoteIceCount: _pendingRemoteIceCandidates.length,
        lastEvent:
            'Remote ICE stored for this session. It will apply after the remote description is ready.',
      );
      return;
    }

    await _webRtcManager.addIceCandidate(candidate);
    state = state.copyWith(lastEvent: 'Remote ICE candidate applied.');
  }

  Future<void> _configureTransport({required bool initiator}) async {
    _sharedSecret = null;
    _peerConnectionReady = false;
    _hasRemoteDescription = false;
    _pendingRemoteIceCandidates.clear();

    await _webRtcManager.close();
    await _webRtcManager.initialize(
      initiator: initiator,
      onMessage: (message) {
        unawaited(_handleInboundTransport(message));
      },
      onIceCandidate: _handleLocalIceCandidate,
    );
    _peerConnectionReady = true;
  }

  Future<DeviceIdentity> _ensureLocalIdentity() async {
    final cachedIdentity = _localIdentity;
    if (cachedIdentity != null) {
      return cachedIdentity;
    }

    final identity = await _loadIdentity();
    _localIdentity = identity;
    return identity;
  }

  Future<void> _establishSharedSecret({
    required DeviceIdentity localIdentity,
    required Map<String, dynamic> payload,
  }) async {
    final remotePublicKey = _remotePublicKeyFromPayload(payload);
    final remoteFingerprint = await _fingerprintForPublicKey(remotePublicKey);

    _sharedSecret = await _cryptoService.deriveSharedSecret(
      localPrivateKey: localIdentity.privateKey,
      localPublicKey: localIdentity.publicKey,
      remotePublicKey: remotePublicKey,
    );

    state = state.copyWith(
      remoteFingerprint: remoteFingerprint,
      conversationId: _conversationIdForFingerprint(remoteFingerprint),
      hasSharedSecret: true,
      lastError: null,
    );
  }

  Future<void> _flushPendingRemoteIceCandidates() async {
    if (!_peerConnectionReady || !_hasRemoteDescription) {
      return;
    }

    final queuedCandidates =
        List<RTCIceCandidate>.from(_pendingRemoteIceCandidates);
    _pendingRemoteIceCandidates.clear();
    for (final candidate in queuedCandidates) {
      await _webRtcManager.addIceCandidate(candidate);
    }

    state = state.copyWith(pendingRemoteIceCount: 0);
  }

  void _appendLocalSignal(SignalingEnvelope envelope) {
    final signals = List<ShareableSignal>.from(state.localSignals)
      ..add(
        ShareableSignal(
          type: envelope.type,
          encoded: _signalingService.encode(envelope),
          createdAt: envelope.sentAt,
        ),
      );

    state = state.copyWith(localSignals: signals, lastError: null);
  }

  Future<void> _handleInboundTransport(String rawMessage) async {
    final sharedSecret = _sharedSecret;
    if (sharedSecret == null) {
      _setError('Received peer data before the shared secret was ready.');
      return;
    }

    try {
      final envelope = PeerTransportEnvelope.decodeTransportString(rawMessage);
      final messageService = await _loadMessageService();
      final body = await messageService.decryptFromTransport(
        payload: envelope.payload,
        sharedSecret: sharedSecret,
      );

      if (body == null) {
        _setError('Could not decrypt an incoming peer message.');
        return;
      }

      final conversationId = state.conversationId ??
          _conversationIdForFingerprint(envelope.senderFingerprint);

      await messageService.saveInboundMessage(
        Message(
          id: envelope.messageId,
          conversationId: conversationId,
          senderId: envelope.senderFingerprint,
          body: body,
          type: MessageType.text,
          deliveryState: MessageDeliveryState.delivered,
          createdAt: envelope.createdAt,
          isOutgoing: false,
          burnAfterRead: envelope.burnAfterRead,
          expiresAt: envelope.expiresAt,
        ),
      );
      _refreshConversation(conversationId);

      state = state.copyWith(
        remoteFingerprint: envelope.senderFingerprint,
        conversationId: conversationId,
        lastEvent: 'Secure message received.',
      );
    } catch (error) {
      _setError('Incoming peer message failed to process: $error');
    }
  }

  void _handleLocalIceCandidate(RTCIceCandidate candidate) {
    final sessionId = state.sessionId;
    final candidateValue = candidate.candidate;
    if (sessionId == null || candidateValue == null || candidateValue.isEmpty) {
      return;
    }

    _appendLocalSignal(
      SignalingEnvelope(
        type: SignalingEnvelopeType.iceCandidate,
        sessionId: sessionId,
        payload: <String, dynamic>{
          'candidate': candidate.toMap(),
        },
        sentAt: DateTime.now(),
      ),
    );
  }

  void _handleTransportState(WebRtcSessionState connectionState) {
    if (!state.isSessionActive &&
        connectionState == WebRtcSessionState.closed) {
      return;
    }

    var nextState = state.copyWith(connectionState: connectionState);
    if (connectionState == WebRtcSessionState.open) {
      nextState = nextState.copyWith(
        lastEvent: 'Secure data channel is open. Peer messaging is live.',
        lastError: null,
      );
    } else if (connectionState == WebRtcSessionState.failed) {
      nextState = nextState.copyWith(
        lastError:
            'Peer connection failed. Start a fresh offer and re-exchange the signaling payloads.',
      );
    }

    state = nextState;
  }

  Map<String, dynamic> _descriptionPayload(
    RTCSessionDescription description,
    DeviceIdentity identity,
  ) {
    return <String, dynamic>{
      'description': description.toMap(),
      'identity': <String, dynamic>{
        'publicKey': base64Encode(identity.publicKey),
        'fingerprint': identity.fingerprint,
      },
    };
  }

  RTCSessionDescription _sessionDescriptionFromPayload(
    Map<String, dynamic> payload,
  ) {
    final description = Map<String, dynamic>.from(
        payload['description'] as Map<dynamic, dynamic>);
    return RTCSessionDescription(
      description['sdp'] as String?,
      description['type'] as String?,
    );
  }

  RTCIceCandidate _iceCandidateFromPayload(Map<String, dynamic> payload) {
    final candidate = Map<String, dynamic>.from(
        payload['candidate'] as Map<dynamic, dynamic>);
    return RTCIceCandidate(
      candidate['candidate'] as String?,
      candidate['sdpMid'] as String?,
      candidate['sdpMLineIndex'] as int?,
    );
  }

  Uint8List _remotePublicKeyFromPayload(Map<String, dynamic> payload) {
    final identity =
        Map<String, dynamic>.from(payload['identity'] as Map<dynamic, dynamic>);
    final publicKey = identity['publicKey'] as String?;
    if (publicKey == null || publicKey.isEmpty) {
      throw const FormatException(
          'Signal payload is missing the peer public key.');
    }

    return Uint8List.fromList(base64Decode(publicKey));
  }

  Future<String> _fingerprintForPublicKey(Uint8List publicKey) async {
    final digest = await Sha256().hash(publicKey);
    return digest.bytes
        .take(8)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(':');
  }

  String _conversationIdForFingerprint(String fingerprint) =>
      'peer:$fingerprint';

  void _setError(String message) {
    state = state.copyWith(lastError: message);
  }
}

@immutable
class PeerTransportEnvelope {
  const PeerTransportEnvelope({
    required this.messageId,
    required this.senderFingerprint,
    required this.payload,
    required this.createdAt,
    required this.burnAfterRead,
    this.expiresAt,
  });

  final String messageId;
  final String senderFingerprint;
  final EncryptedPayload payload;
  final DateTime createdAt;
  final bool burnAfterRead;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'messageId': messageId,
      'senderFingerprint': senderFingerprint,
      'payload': payload.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'burnAfterRead': burnAfterRead,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  String encodeTransportString() => jsonEncode(toJson());

  factory PeerTransportEnvelope.fromJson(Map<String, dynamic> json) {
    return PeerTransportEnvelope(
      messageId: json['messageId'] as String,
      senderFingerprint: json['senderFingerprint'] as String,
      payload: EncryptedPayload.fromJson(
        Map<String, dynamic>.from(json['payload'] as Map<dynamic, dynamic>),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      burnAfterRead: json['burnAfterRead'] as bool? ?? true,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
    );
  }

  factory PeerTransportEnvelope.decodeTransportString(String value) {
    return PeerTransportEnvelope.fromJson(
      jsonDecode(value) as Map<String, dynamic>,
    );
  }
}

const Object _sentinel = Object();
