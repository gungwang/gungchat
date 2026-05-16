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
import '../../models/contact.dart';
import '../../models/message.dart';
import 'attachment_message_payload.dart';
import 'attachment_message_service.dart';
import 'message_service.dart';
import 'presence_status.dart';
import 'reaction_service.dart';
import 'voice_message_payload.dart';
import 'voice_message_service.dart';

typedef LoadLocalIdentity = Future<DeviceIdentity> Function();
typedef LoadMessageService = Future<MessageService> Function();
typedef LoadVoiceMessageService = VoiceMessageService Function();
typedef LoadAttachmentMessageService = AttachmentMessageService Function();
typedef RefreshConversationMessages = void Function(String conversationId);
typedef DispatchLocalSignal = Future<void> Function({
  required String encodedSignal,
  required String targetAddress,
});
typedef IsBlockedFingerprint = bool Function(String fingerprint);

enum PeerSessionRole {
  initiator,
  responder,
}

enum PeerSessionHistoryDirection {
  incoming,
  outgoing,
  system,
}

enum PeerSessionHistoryActionKind {
  copy,
  apply,
}

@immutable
class PeerSessionHistoryAction {
  const PeerSessionHistoryAction({
    required this.kind,
    required this.label,
    required this.payload,
  });

  final PeerSessionHistoryActionKind kind;
  final String label;
  final String payload;
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
class PeerSessionHistoryEntry {
  const PeerSessionHistoryEntry({
    required this.title,
    required this.occurredAt,
    this.detail,
    this.direction = PeerSessionHistoryDirection.system,
    this.action,
  });

  final String title;
  final String? detail;
  final DateTime occurredAt;
  final PeerSessionHistoryDirection direction;
  final PeerSessionHistoryAction? action;
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
    this.expectedRemoteFingerprint,
    this.targetDisplayName,
    this.targetAddress,
    this.isRemoteTyping = false,
    this.remotePresenceStatus,
    this.remoteStatusText,
    this.history = const [],
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
  final String? expectedRemoteFingerprint;
  final String? targetDisplayName;
  final String? targetAddress;
  final bool isRemoteTyping;
  final PeerPresenceStatus? remotePresenceStatus;
  final String? remoteStatusText;
  final List<PeerSessionHistoryEntry> history;

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
    Object? expectedRemoteFingerprint = _sentinel,
    Object? targetDisplayName = _sentinel,
    Object? targetAddress = _sentinel,
    bool? isRemoteTyping,
    Object? remotePresenceStatus = _sentinel,
    Object? remoteStatusText = _sentinel,
    List<PeerSessionHistoryEntry>? history,
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
      expectedRemoteFingerprint: identical(expectedRemoteFingerprint, _sentinel)
          ? this.expectedRemoteFingerprint
          : expectedRemoteFingerprint as String?,
      targetDisplayName: identical(targetDisplayName, _sentinel)
          ? this.targetDisplayName
          : targetDisplayName as String?,
      targetAddress: identical(targetAddress, _sentinel)
          ? this.targetAddress
          : targetAddress as String?,
      isRemoteTyping: isRemoteTyping ?? this.isRemoteTyping,
      remotePresenceStatus: identical(remotePresenceStatus, _sentinel)
          ? this.remotePresenceStatus
          : remotePresenceStatus as PeerPresenceStatus?,
      remoteStatusText: identical(remoteStatusText, _sentinel)
          ? this.remoteStatusText
          : remoteStatusText as String?,
      history: history ?? this.history,
    );
  }
}

class PeerSessionController extends StateNotifier<PeerSessionState> {
  PeerSessionController({
    required LoadLocalIdentity loadIdentity,
    required LoadMessageService loadMessageService,
    required LoadVoiceMessageService loadVoiceMessageService,
    required LoadAttachmentMessageService loadAttachmentMessageService,
    required RefreshConversationMessages refreshConversation,
    required ReactionService reactionService,
    required WebRtcManager webRtcManager,
    required ManualSignalingService signalingService,
    required CryptoService cryptoService,
    required DispatchLocalSignal dispatchLocalSignal,
    required IsBlockedFingerprint isBlockedFingerprint,
    Uuid? uuid,
  })  : _loadIdentity = loadIdentity,
        _loadMessageService = loadMessageService,
        _loadVoiceMessageService = loadVoiceMessageService,
        _loadAttachmentMessageService = loadAttachmentMessageService,
        _refreshConversation = refreshConversation,
        _reactionService = reactionService,
        _webRtcManager = webRtcManager,
        _signalingService = signalingService,
        _cryptoService = cryptoService,
        _dispatchLocalSignal = dispatchLocalSignal,
        _isBlockedFingerprint = isBlockedFingerprint,
        _uuid = uuid ?? const Uuid(),
        super(const PeerSessionState()) {
    _stateSubscription = _webRtcManager.states.listen(_handleTransportState);
  }

  final LoadLocalIdentity _loadIdentity;
  final LoadMessageService _loadMessageService;
  final LoadVoiceMessageService _loadVoiceMessageService;
  final LoadAttachmentMessageService _loadAttachmentMessageService;
  final RefreshConversationMessages _refreshConversation;
  final ReactionService _reactionService;
  final WebRtcManager _webRtcManager;
  final ManualSignalingService _signalingService;
  final CryptoService _cryptoService;
  final DispatchLocalSignal _dispatchLocalSignal;
  final IsBlockedFingerprint _isBlockedFingerprint;
  final Uuid _uuid;

  StreamSubscription<WebRtcSessionState>? _stateSubscription;

  DeviceIdentity? _localIdentity;
  SecretKey? _sharedSecret;
  bool _peerConnectionReady = false;
  bool _hasRemoteDescription = false;
  final List<RTCIceCandidate> _pendingRemoteIceCandidates = [];
  Timer? _localTypingTimer;
  Timer? _remoteTypingTimer;
  bool _localTypingActive = false;
  PeerPresenceStatus? _lastSentPresenceStatus;
  String? _lastSentCustomStatusText;
  bool _automaticHelloSent = false;

  Future<void> startOffer({Contact? targetContact}) async {
    if (targetContact != null && _isBlockedFingerprint(targetContact.fingerprint)) {
      _setError('Blocked contacts cannot start peer sessions.');
      return;
    }

    final identity = await _ensureLocalIdentity();
    final sessionId = _uuid.v4();

    state = PeerSessionState(
      sessionId: sessionId,
      role: PeerSessionRole.initiator,
      connectionState: WebRtcSessionState.connecting,
      expectedRemoteFingerprint: targetContact?.fingerprint,
      targetDisplayName: targetContact?.displayName,
      targetAddress: targetContact?.lastKnownAddress,
      lastEvent: targetContact == null
          ? 'Offer is being prepared for manual sharing.'
          : 'Offer is being prepared for ${targetContact.displayName}.',
      history: [
        PeerSessionHistoryEntry(
          title: targetContact == null
              ? 'Offer started'
              : 'Offer started for ${targetContact.displayName}',
          detail: targetContact?.lastKnownAddress,
          occurredAt: DateTime.now(),
          direction: PeerSessionHistoryDirection.outgoing,
        ),
      ],
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
        lastEvent: targetContact == null
            ? 'Offer ready. Share it with your peer, then paste the answer and ICE payloads here.'
            : 'Offer ready for ${targetContact.displayName}. Share it through the selected contact channel, then paste the answer and ICE payloads here.',
      );
    } catch (error) {
      _setError('Could not start an offer: $error');
    }
  }

  Future<void> applyRemoteSignal(String rawValue,
      {Contact? targetContact}) async {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      _setError('Paste an offer, answer, or ICE payload before applying it.');
      return;
    }

    if (targetContact != null && _isBlockedFingerprint(targetContact.fingerprint)) {
      _setError('Signals from blocked contacts cannot be applied.');
      return;
    }

    state = state.copyWith(
      isApplyingSignal: true,
      lastError: null,
      expectedRemoteFingerprint:
          targetContact?.fingerprint ?? state.expectedRemoteFingerprint,
      targetDisplayName: targetContact?.displayName ?? state.targetDisplayName,
      targetAddress: targetContact?.lastKnownAddress ?? state.targetAddress,
    );

    try {
      final envelope = _signalingService.decode(trimmed);
      switch (envelope.type) {
        case SignalingEnvelopeType.offer:
          await _applyRemoteOffer(envelope, rawSignal: trimmed);
        case SignalingEnvelopeType.answer:
          await _applyRemoteAnswer(envelope, rawSignal: trimmed);
        case SignalingEnvelopeType.iceCandidate:
          await _applyRemoteIceCandidate(envelope, rawSignal: trimmed);
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
    String? replyToMessageId,
    String? replyToBody,
  }) async {
    if (!_ensurePeerAllowed('send messages')) {
      return false;
    }

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
      replyToMessageId: replyToMessageId,
      replyToBody: replyToBody,
    );
    _refreshConversation(conversationId);

    try {
      final encryptedPayload = await messageService.encryptForTransport(
        body: body,
        sharedSecret: sharedSecret,
      );
      final transportEnvelope = PeerTransportEnvelope.message(
        messageId: message.id,
        senderFingerprint: identity.fingerprint,
        payload: encryptedPayload,
        createdAt: message.createdAt,
        burnAfterRead: burnAfterRead,
        expiresAt: message.expiresAt,
        replyToMessageId: message.replyToMessageId,
        replyToBody: message.replyToBody,
      );

      await clearLocalTyping(notifyPeer: false);
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

  Future<bool> sendVoiceMessage({
    required RecordedVoiceClip clip,
    required bool burnAfterRead,
    String? replyToMessageId,
    String? replyToBody,
  }) async {
    if (!_ensurePeerAllowed('send voice messages')) {
      return false;
    }

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
    final voiceMessageService = _loadVoiceMessageService();

    final message = await messageService.createLocalMessage(
      conversationId: conversationId,
      senderId: identity.fingerprint,
      body: '',
      type: MessageType.audio,
      burnAfterRead: burnAfterRead,
      deliveryState: MessageDeliveryState.sending,
      replyToMessageId: replyToMessageId,
      replyToBody: replyToBody,
      audioFilePath: clip.filePath,
      audioDurationMs: clip.durationMs,
    );
    _refreshConversation(conversationId);

    try {
      final payloadText = VoiceMessagePayload(
        bytes: await voiceMessageService.loadClipBytes(clip.filePath),
        durationMs: clip.durationMs,
        mimeType: clip.mimeType,
      ).encodeTransportString();
      final encryptedPayload = await messageService.encryptForTransport(
        body: payloadText,
        sharedSecret: sharedSecret,
      );
      final transportEnvelope = PeerTransportEnvelope.message(
        messageId: message.id,
        senderFingerprint: identity.fingerprint,
        payload: encryptedPayload,
        createdAt: message.createdAt,
        burnAfterRead: burnAfterRead,
        expiresAt: message.expiresAt,
        replyToMessageId: message.replyToMessageId,
        replyToBody: message.replyToBody,
      );

      await clearLocalTyping(notifyPeer: false);
      await _webRtcManager.sendText(transportEnvelope.encodeTransportString());
      await messageService.updateDeliveryState(
        message.id,
        MessageDeliveryState.sent,
      );
      _refreshConversation(conversationId);
      state = state.copyWith(lastEvent: 'Secure voice message sent.');
      return true;
    } catch (error) {
      await messageService.updateDeliveryState(
        message.id,
        MessageDeliveryState.failed,
      );
      _refreshConversation(conversationId);
      _setError('Secure voice send failed: $error');
      return false;
    }
  }

  Future<bool> sendAttachments({
    required MessageType messageType,
    required List<Attachment> attachments,
    required bool burnAfterRead,
    String? replyToMessageId,
    String? replyToBody,
  }) async {
    if (!_ensurePeerAllowed('send attachments')) {
      return false;
    }

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
    if (attachments.isEmpty) {
      _setError('Choose at least one attachment before sending.');
      return false;
    }

    final identity = await _ensureLocalIdentity();
    final messageService = await _loadMessageService();
    final attachmentService = _loadAttachmentMessageService();

    final message = await messageService.createLocalMessage(
      conversationId: conversationId,
      senderId: identity.fingerprint,
      body: '',
      type: messageType,
      burnAfterRead: burnAfterRead,
      deliveryState: MessageDeliveryState.sending,
      replyToMessageId: replyToMessageId,
      replyToBody: replyToBody,
      attachments: attachments,
    );
    _refreshConversation(conversationId);

    try {
      final transportAttachments = await attachmentService.loadTransportAttachments(
        attachments,
      );
      final payloadText = AttachmentMessagePayload(
        messageType: messageType,
        attachments: transportAttachments,
      ).encodeTransportString();
      final encryptedPayload = await messageService.encryptForTransport(
        body: payloadText,
        sharedSecret: sharedSecret,
      );
      final transportEnvelope = PeerTransportEnvelope.message(
        messageId: message.id,
        senderFingerprint: identity.fingerprint,
        payload: encryptedPayload,
        createdAt: message.createdAt,
        burnAfterRead: burnAfterRead,
        expiresAt: message.expiresAt,
        replyToMessageId: message.replyToMessageId,
        replyToBody: message.replyToBody,
      );

      await clearLocalTyping(notifyPeer: false);
      await _webRtcManager.sendText(transportEnvelope.encodeTransportString());
      await messageService.updateDeliveryState(
        message.id,
        MessageDeliveryState.sent,
      );
      _refreshConversation(conversationId);
      state = state.copyWith(lastEvent: 'Secure attachments sent.');
      return true;
    } catch (error) {
      await messageService.updateDeliveryState(
        message.id,
        MessageDeliveryState.failed,
      );
      _refreshConversation(conversationId);
      _setError('Attachment send failed: $error');
      return false;
    }
  }

  Future<void> resetSession() async {
    await clearLocalTyping(notifyPeer: false);
    _remoteTypingTimer?.cancel();
    _lastSentPresenceStatus = null;
    _lastSentCustomStatusText = null;
    _sharedSecret = null;
    _peerConnectionReady = false;
    _hasRemoteDescription = false;
    _pendingRemoteIceCandidates.clear();
    await _webRtcManager.close();
    state = const PeerSessionState();
  }

  Future<void> syncPresence(PeerPresenceStatus status) async {
    if (!state.isTransportReady ||
        _lastSentPresenceStatus == status ||
        !_ensurePeerAllowed('share presence')) {
      return;
    }

    final identity = await _ensureLocalIdentity();

    try {
      await _webRtcManager.sendText(
        PeerTransportEnvelope.presence(
          senderFingerprint: identity.fingerprint,
          createdAt: DateTime.now(),
          presenceStatus: status,
        ).encodeTransportString(),
      );
      _lastSentPresenceStatus = status;
    } catch (error, stackTrace) {
      debugPrint('Presence update failed: $error\n$stackTrace');
    }
  }

  Future<void> syncCustomStatusText(String text) async {
    final normalized = text.trim();
    if (!state.isTransportReady ||
        _lastSentCustomStatusText == normalized ||
        !_ensurePeerAllowed('share custom status')) {
      return;
    }

    final identity = await _ensureLocalIdentity();

    try {
      await _webRtcManager.sendText(
        PeerTransportEnvelope.statusText(
          senderFingerprint: identity.fingerprint,
          createdAt: DateTime.now(),
          statusText: normalized.isEmpty ? null : normalized,
        ).encodeTransportString(),
      );
      _lastSentCustomStatusText = normalized;
    } catch (error, stackTrace) {
      debugPrint('Custom status update failed: $error\n$stackTrace');
    }
  }

  Future<void> markMessagesRead({
    required String conversationId,
    required Iterable<String> messageIds,
    required bool sendReceipt,
  }) async {
    final distinctIds = messageIds.toSet().toList(growable: false);
    if (distinctIds.isEmpty) {
      return;
    }

    final messageService = await _loadMessageService();
    for (final messageId in distinctIds) {
      await messageService.updateDeliveryState(
        messageId,
        MessageDeliveryState.read,
      );
      if (sendReceipt) {
        await _sendReadReceipt(messageId);
      }
    }

    _refreshConversation(conversationId);
  }

  Future<void> toggleReaction({
    required Message message,
    required String emoji,
  }) async {
    if (!_ensurePeerAllowed('update reactions')) {
      return;
    }

    final conversationId = state.conversationId;
    if (conversationId == null || !state.isTransportReady) {
      _setError('Open the secure channel before sending reactions.');
      return;
    }

    final identity = await _ensureLocalIdentity();
    final messageService = await _loadMessageService();
    final nextReactions = _reactionService.toggleReaction(
      emoji: emoji,
      myUserId: identity.fingerprint,
      currentReactions: message.reactions,
    );

    await messageService.updateReactions(message.id, nextReactions);
    _refreshConversation(message.conversationId);

    try {
      await _webRtcManager.sendText(
        PeerTransportEnvelope.reaction(
          messageId: message.id,
          senderFingerprint: identity.fingerprint,
          createdAt: DateTime.now(),
          reactions: nextReactions,
        ).encodeTransportString(),
      );
      state = state.copyWith(lastEvent: 'Message reaction updated.');
    } catch (error) {
      await messageService.updateReactions(message.id, message.reactions);
      _refreshConversation(message.conversationId);
      _setError('Reaction update failed: $error');
    }
  }

  Future<bool> editMessage({
    required Message message,
    required String body,
  }) async {
    if (!_ensurePeerAllowed('edit messages')) {
      return false;
    }

    final conversationId = state.conversationId;
    if (conversationId == null || !state.isTransportReady) {
      _setError('Open the secure channel before editing messages.');
      return false;
    }
    if (!message.isOutgoing || message.isDeleted) {
      _setError('Only active outgoing messages can be edited.');
      return false;
    }

    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      _setError('Edited message content cannot be empty.');
      return false;
    }
    if (trimmedBody == message.body.trim()) {
      return true;
    }

    final identity = await _ensureLocalIdentity();
    final messageService = await _loadMessageService();
    final editedAt = DateTime.now();

    try {
      await _webRtcManager.sendText(
        PeerTransportEnvelope.messageEdit(
          messageId: message.id,
          senderFingerprint: identity.fingerprint,
          createdAt: editedAt,
          content: trimmedBody,
        ).encodeTransportString(),
      );
      await messageService.updateMessageContent(
        messageId: message.id,
        body: trimmedBody,
        editedAt: editedAt,
      );
      _refreshConversation(message.conversationId);
      state = state.copyWith(lastEvent: 'Secure message edited.');
      return true;
    } catch (error) {
      _setError('Message edit failed: $error');
      return false;
    }
  }

  Future<bool> deleteMessage({
    required Message message,
    required MessageDeleteMode mode,
  }) async {
    if (!_ensurePeerAllowed('delete messages')) {
      return false;
    }

    final conversationId = state.conversationId;
    if (conversationId == null || !state.isTransportReady) {
      _setError('Open the secure channel before deleting messages.');
      return false;
    }
    if (!message.isOutgoing) {
      _setError('Only outgoing messages can be deleted.');
      return false;
    }

    final identity = await _ensureLocalIdentity();
    final messageService = await _loadMessageService();
    final deletedAt = DateTime.now();

    try {
      await _webRtcManager.sendText(
        PeerTransportEnvelope.messageDelete(
          messageId: message.id,
          senderFingerprint: identity.fingerprint,
          createdAt: deletedAt,
          deleteMode: mode,
        ).encodeTransportString(),
      );
      if (mode == MessageDeleteMode.hardDelete) {
        await messageService.deleteMessage(message.id);
      } else {
        await messageService.markMessageDeleted(
          messageId: message.id,
          deletedAt: deletedAt,
          mode: mode,
        );
      }
      _refreshConversation(message.conversationId);
      state = state.copyWith(
        lastEvent: mode == MessageDeleteMode.hardDelete
            ? 'Secure message erased.'
            : 'Secure message deleted.',
      );
      return true;
    } catch (error) {
      _setError('Message delete failed: $error');
      return false;
    }
  }

  void updateComposerActivity(String draft) {
    final shouldNotifyTyping =
        state.isTransportReady && draft.trim().isNotEmpty;

    if (!shouldNotifyTyping) {
      _localTypingTimer?.cancel();
      if (_localTypingActive) {
        unawaited(clearLocalTyping());
      }
      return;
    }

    if (!_localTypingActive) {
      unawaited(_sendTypingStatus(true));
    }

    _localTypingTimer?.cancel();
    _localTypingTimer = Timer(const Duration(seconds: 3), () {
      unawaited(clearLocalTyping());
    });
  }

  Future<void> clearLocalTyping({bool notifyPeer = true}) async {
    _localTypingTimer?.cancel();
    if (!notifyPeer || !_localTypingActive) {
      _localTypingActive = false;
      return;
    }

    await _sendTypingStatus(false);
  }

  void recordHistory({
    required String title,
    String? detail,
    PeerSessionHistoryDirection direction = PeerSessionHistoryDirection.system,
    DateTime? occurredAt,
    PeerSessionHistoryAction? action,
  }) {
    _pushHistory(
      title: title,
      detail: detail,
      direction: direction,
      occurredAt: occurredAt,
      action: action,
    );
  }

  @override
  void dispose() {
    _localTypingTimer?.cancel();
    _remoteTypingTimer?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _applyRemoteOffer(
    SignalingEnvelope envelope, {
    required String rawSignal,
  }) async {
    final identity = await _ensureLocalIdentity();

    if (state.sessionId != envelope.sessionId ||
        state.role != PeerSessionRole.responder ||
        !_peerConnectionReady) {
      state = PeerSessionState(
        sessionId: envelope.sessionId,
        role: PeerSessionRole.responder,
        connectionState: WebRtcSessionState.connecting,
        expectedRemoteFingerprint: state.expectedRemoteFingerprint,
        targetDisplayName: state.targetDisplayName,
        targetAddress: state.targetAddress,
        lastEvent: state.targetDisplayName == null
            ? 'Remote offer loaded. Preparing an answer.'
            : 'Remote offer loaded for ${state.targetDisplayName}. Preparing an answer.',
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
    _pushHistory(
      title: 'Offer imported',
      detail: 'Reply bundle is ready to share back to the sender.',
      direction: PeerSessionHistoryDirection.incoming,
      action: _signalHistoryAction(
        type: envelope.type,
        payload: rawSignal,
        direction: PeerSessionHistoryDirection.incoming,
      ),
    );
  }

  Future<void> _applyRemoteAnswer(
    SignalingEnvelope envelope, {
    required String rawSignal,
  }) async {
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
    _pushHistory(
      title: 'Answer imported',
      detail: 'The remote answer was applied to the active session.',
      direction: PeerSessionHistoryDirection.incoming,
      action: _signalHistoryAction(
        type: envelope.type,
        payload: rawSignal,
        direction: PeerSessionHistoryDirection.incoming,
      ),
    );
  }

  Future<void> _applyRemoteIceCandidate(
    SignalingEnvelope envelope, {
    required String rawSignal,
  }) async {
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
      _pushHistory(
        title: 'ICE imported',
        detail: 'Queued until the remote description is ready.',
        direction: PeerSessionHistoryDirection.incoming,
        action: _signalHistoryAction(
          type: envelope.type,
          payload: rawSignal,
          direction: PeerSessionHistoryDirection.incoming,
        ),
      );
      return;
    }

    await _webRtcManager.addIceCandidate(candidate);
    state = state.copyWith(lastEvent: 'Remote ICE candidate applied.');
    _pushHistory(
      title: 'ICE imported',
      detail: 'Applied immediately to the active peer connection.',
      direction: PeerSessionHistoryDirection.incoming,
      action: _signalHistoryAction(
        type: envelope.type,
        payload: rawSignal,
        direction: PeerSessionHistoryDirection.incoming,
      ),
    );
  }

  Future<void> _configureTransport({required bool initiator}) async {
    _sharedSecret = null;
    _peerConnectionReady = false;
    _hasRemoteDescription = false;
    _automaticHelloSent = false;
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
    final expectedRemoteFingerprint = state.expectedRemoteFingerprint;

    if (_isBlockedFingerprint(remoteFingerprint)) {
      throw StateError(
        'Remote fingerprint $remoteFingerprint is blocked on this device.',
      );
    }

    if (expectedRemoteFingerprint != null &&
        expectedRemoteFingerprint != remoteFingerprint) {
      throw StateError(
        'Remote fingerprint $remoteFingerprint does not match the selected contact $expectedRemoteFingerprint.',
      );
    }

    _sharedSecret = await _cryptoService.deriveSharedSecret(
      localPrivateKey: localIdentity.privateKey,
      localPublicKey: localIdentity.publicKey,
      remotePublicKey: remotePublicKey,
    );

    state = state.copyWith(
      remoteFingerprint: remoteFingerprint,
      conversationId: conversationIdForFingerprint(remoteFingerprint),
      hasSharedSecret: true,
      lastError: null,
      expectedRemoteFingerprint: remoteFingerprint,
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
    final encodedSignal = _signalingService.encode(envelope);
    final targetAddress = state.targetAddress;
    final targetDisplayName = state.targetDisplayName;
    final signals = List<ShareableSignal>.from(state.localSignals)
      ..add(
        ShareableSignal(
          type: envelope.type,
          encoded: encodedSignal,
          createdAt: envelope.sentAt,
        ),
      );

    state = state.copyWith(localSignals: signals, lastError: null);
    _pushHistory(
      title: '${signals.last.label} generated',
      detail: 'Ready to share with the peer.',
      direction: PeerSessionHistoryDirection.outgoing,
      occurredAt: envelope.sentAt,
      action: _signalHistoryAction(
        type: envelope.type,
        payload: encodedSignal,
        direction: PeerSessionHistoryDirection.outgoing,
      ),
    );

    if (targetAddress != null && targetAddress.isNotEmpty) {
      unawaited(
        _dispatchLocalSignalIfPossible(
          envelope: envelope,
          encodedSignal: encodedSignal,
          targetAddress: targetAddress,
          targetDisplayName: targetDisplayName,
        ),
      );
    }
  }

  Future<void> _dispatchLocalSignalIfPossible({
    required SignalingEnvelope envelope,
    required String encodedSignal,
    required String targetAddress,
    String? targetDisplayName,
  }) async {
    final destination = targetDisplayName ?? targetAddress;

    try {
      await _dispatchLocalSignal(
        encodedSignal: encodedSignal,
        targetAddress: targetAddress,
      );
      if (state.sessionId != envelope.sessionId) {
        return;
      }

      switch (envelope.type) {
        case SignalingEnvelopeType.offer:
          state = state.copyWith(
            lastEvent:
                'Offer sent to $destination over LAN. Waiting for the answer.',
            lastError: null,
          );
          _pushHistory(
            title: 'Offer sent over LAN',
            detail: 'Delivered directly to $destination.',
            direction: PeerSessionHistoryDirection.outgoing,
          );
        case SignalingEnvelopeType.answer:
          state = state.copyWith(
            lastEvent:
                'Answer sent to $destination over LAN. Waiting for the secure channel to finish connecting.',
            lastError: null,
          );
          _pushHistory(
            title: 'Answer sent over LAN',
            detail: 'Delivered directly to $destination.',
            direction: PeerSessionHistoryDirection.outgoing,
          );
        case SignalingEnvelopeType.iceCandidate:
          break;
      }
    } catch (error) {
      if (state.sessionId != envelope.sessionId) {
        return;
      }

      if (envelope.type == SignalingEnvelopeType.iceCandidate) {
        _pushHistory(
          title: 'ICE delivery failed',
          detail:
              'Could not deliver ICE to $destination automatically: $error',
          direction: PeerSessionHistoryDirection.system,
        );
        return;
      }

      final signalLabel = _signalTypeLabel(envelope.type);
      state = state.copyWith(
        lastError:
            'Could not deliver the $signalLabel to $destination automatically. Copy it manually instead.',
      );
      _pushHistory(
        title: 'LAN delivery failed',
        detail:
            'Could not deliver the $signalLabel to $destination automatically: $error',
        direction: PeerSessionHistoryDirection.system,
      );
    }
  }

  String _signalTypeLabel(SignalingEnvelopeType type) {
    switch (type) {
      case SignalingEnvelopeType.offer:
        return 'offer';
      case SignalingEnvelopeType.answer:
        return 'answer';
      case SignalingEnvelopeType.iceCandidate:
        return 'ICE payload';
    }
  }

  Future<void> _handleInboundTransport(String rawMessage) async {
    final sharedSecret = _sharedSecret;
    if (sharedSecret == null) {
      _setError('Received peer data before the shared secret was ready.');
      return;
    }

    try {
      final envelope = PeerTransportEnvelope.decodeTransportString(rawMessage);
      if (_isBlockedFingerprint(envelope.senderFingerprint)) {
        state = state.copyWith(
          lastEvent: 'Ignored transport data from a blocked contact.',
        );
        return;
      }
      if (envelope.kind == PeerTransportEnvelopeKind.typing) {
        _handleRemoteTypingEnvelope(envelope);
        return;
      }
      if (envelope.kind == PeerTransportEnvelopeKind.presence) {
        _handlePresenceEnvelope(envelope);
        return;
      }
      if (envelope.kind == PeerTransportEnvelopeKind.statusText) {
        _handleStatusTextEnvelope(envelope);
        return;
      }
      if (envelope.kind == PeerTransportEnvelopeKind.receipt) {
        await _handleReceiptEnvelope(envelope);
        return;
      }
      if (envelope.kind == PeerTransportEnvelopeKind.reaction) {
        await _handleReactionEnvelope(envelope);
        return;
      }
      if (envelope.kind == PeerTransportEnvelopeKind.messageEdit) {
        await _handleMessageEditEnvelope(envelope);
        return;
      }
      if (envelope.kind == PeerTransportEnvelopeKind.messageDelete) {
        await _handleMessageDeleteEnvelope(envelope);
        return;
      }

      final payload = envelope.payload;
      final messageId = envelope.messageId;
      if (payload == null || messageId == null) {
        throw const FormatException(
          'Incoming peer message is missing encrypted content.',
        );
      }

      final messageService = await _loadMessageService();
      final body = await messageService.decryptFromTransport(
        payload: payload,
        sharedSecret: sharedSecret,
      );

      if (body == null) {
        _setError('Could not decrypt an incoming peer message.');
        return;
      }

      final conversationId = state.conversationId ??
          conversationIdForFingerprint(envelope.senderFingerprint);

      final voicePayload = VoiceMessagePayload.tryDecodeTransportString(body);
      final attachmentPayload = voicePayload == null
          ? AttachmentMessagePayload.tryDecodeTransportString(body)
          : null;
      final message = voicePayload == null
          ? attachmentPayload == null
              ? Message(
                  id: messageId,
                  conversationId: conversationId,
                  senderId: envelope.senderFingerprint,
                  body: body,
                  type: MessageType.text,
                  deliveryState: MessageDeliveryState.delivered,
                  createdAt: envelope.createdAt,
                  isOutgoing: false,
                  burnAfterRead: envelope.burnAfterRead ?? true,
                  expiresAt: envelope.expiresAt,
                  replyToMessageId: envelope.replyToMessageId,
                  replyToBody: envelope.replyToBody,
                )
              : Message(
                  id: messageId,
                  conversationId: conversationId,
                  senderId: envelope.senderFingerprint,
                  body: '',
                  type: attachmentPayload.messageType,
                  deliveryState: MessageDeliveryState.delivered,
                  createdAt: envelope.createdAt,
                  isOutgoing: false,
                  burnAfterRead: envelope.burnAfterRead ?? true,
                  expiresAt: envelope.expiresAt,
                  replyToMessageId: envelope.replyToMessageId,
                  replyToBody: envelope.replyToBody,
                  attachments: await _loadAttachmentMessageService()
                      .saveInboundAttachments(
                    messageId: messageId,
                    attachments: attachmentPayload.attachments,
                  ),
                )
          : Message(
              id: messageId,
              conversationId: conversationId,
              senderId: envelope.senderFingerprint,
              body: '',
              type: MessageType.audio,
              deliveryState: MessageDeliveryState.delivered,
              createdAt: envelope.createdAt,
              isOutgoing: false,
              burnAfterRead: envelope.burnAfterRead ?? true,
              expiresAt: envelope.expiresAt,
              replyToMessageId: envelope.replyToMessageId,
              replyToBody: envelope.replyToBody,
              audioFilePath: await _loadVoiceMessageService().saveInboundClipBytes(
                bytes: voicePayload.bytes,
                messageId: messageId,
                extension: VoiceMessageService.extensionForMimeType(
                  voicePayload.mimeType,
                ),
              ),
              audioDurationMs: voicePayload.durationMs,
            );

      await messageService.saveInboundMessage(
        message,
      );
      await _sendDeliveryReceipt(messageId);
      _refreshConversation(conversationId);

      state = state.copyWith(
        remoteFingerprint: envelope.senderFingerprint,
        conversationId: conversationId,
        isRemoteTyping: false,
        lastEvent: voicePayload == null
          ? attachmentPayload == null
            ? 'Secure message received.'
            : 'Secure attachments received.'
          : 'Secure voice message received.',
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
    if (connectionState != WebRtcSessionState.open) {
      _localTypingTimer?.cancel();
      _remoteTypingTimer?.cancel();
      _localTypingActive = false;
      _lastSentPresenceStatus = null;
      nextState = nextState.copyWith(
        isRemoteTyping: false,
        remotePresenceStatus: null,
        remoteStatusText: null,
      );
    }

    if (connectionState == WebRtcSessionState.open) {
      nextState = nextState.copyWith(
        lastEvent: 'Secure data channel is open. Peer messaging is live.',
        lastError: null,
      );
      if (state.connectionState != WebRtcSessionState.open) {
        _pushHistory(
          title: 'Secure channel open',
          detail: 'Peer messaging is live.',
          direction: PeerSessionHistoryDirection.system,
        );
      }
    } else if (connectionState == WebRtcSessionState.failed) {
      nextState = nextState.copyWith(
        lastError:
            'Peer connection failed. Start a fresh offer and re-exchange the signaling payloads.',
      );
      if (state.connectionState != WebRtcSessionState.failed) {
        _pushHistory(
          title: 'Peer connection failed',
          detail: 'Start a fresh offer and re-exchange the signaling payloads.',
          direction: PeerSessionHistoryDirection.system,
        );
      }
    }

    state = nextState;

    if (connectionState == WebRtcSessionState.open) {
      unawaited(_sendAutomaticHelloIfNeeded());
    }
  }

  Future<void> _sendAutomaticHelloIfNeeded() async {
    if (_automaticHelloSent ||
        state.role != PeerSessionRole.initiator ||
        !state.isTransportReady) {
      return;
    }

    _automaticHelloSent = true;
    final sent = await sendMessage(
      body: 'hello',
      burnAfterRead: false,
    );
    if (!sent) {
      _automaticHelloSent = false;
    }
  }

  void _pushHistory({
    required String title,
    String? detail,
    PeerSessionHistoryDirection direction = PeerSessionHistoryDirection.system,
    DateTime? occurredAt,
    PeerSessionHistoryAction? action,
  }) {
    final next = <PeerSessionHistoryEntry>[
      PeerSessionHistoryEntry(
        title: title,
        detail: detail,
        direction: direction,
        occurredAt: occurredAt ?? DateTime.now(),
        action: action,
      ),
      ...state.history,
    ];

    if (next.length > 12) {
      next.removeRange(12, next.length);
    }

    state = state.copyWith(
      history: List<PeerSessionHistoryEntry>.unmodifiable(next),
    );
  }

  PeerSessionHistoryAction _signalHistoryAction({
    required SignalingEnvelopeType type,
    required String payload,
    required PeerSessionHistoryDirection direction,
  }) {
    final signalLabel = switch (type) {
      SignalingEnvelopeType.offer => 'Offer',
      SignalingEnvelopeType.answer => 'Answer',
      SignalingEnvelopeType.iceCandidate => 'ICE',
    };

    return PeerSessionHistoryAction(
      kind: direction == PeerSessionHistoryDirection.incoming
          ? PeerSessionHistoryActionKind.apply
          : PeerSessionHistoryActionKind.copy,
      label: direction == PeerSessionHistoryDirection.incoming
          ? 'Apply $signalLabel Again'
          : 'Copy $signalLabel',
      payload: payload,
    );
  }

  void _handleRemoteTypingEnvelope(PeerTransportEnvelope envelope) {
    final isTyping = envelope.isTyping ?? false;
    final conversationId = state.conversationId ??
        conversationIdForFingerprint(envelope.senderFingerprint);

    _remoteTypingTimer?.cancel();
    state = state.copyWith(
      remoteFingerprint: envelope.senderFingerprint,
      conversationId: conversationId,
      isRemoteTyping: isTyping,
    );

    if (!isTyping) {
      return;
    }

    _remoteTypingTimer = Timer(const Duration(seconds: 4), () {
      state = state.copyWith(isRemoteTyping: false);
    });
  }

  void _handlePresenceEnvelope(PeerTransportEnvelope envelope) {
    final conversationId = state.conversationId ??
        conversationIdForFingerprint(envelope.senderFingerprint);
    final presenceStatus = envelope.presenceStatus;

    state = state.copyWith(
      remoteFingerprint: envelope.senderFingerprint,
      conversationId: conversationId,
      remotePresenceStatus: presenceStatus,
      remoteStatusText: presenceStatus == null ||
              presenceStatus == PeerPresenceStatus.hidden
          ? null
          : state.remoteStatusText,
      lastEvent: presenceStatus == null ||
              presenceStatus == PeerPresenceStatus.hidden
          ? 'Peer presence is hidden.'
          : 'Peer is now ${presenceStatus.label.toLowerCase()}.',
    );
  }

  void _handleStatusTextEnvelope(PeerTransportEnvelope envelope) {
    final conversationId = state.conversationId ??
        conversationIdForFingerprint(envelope.senderFingerprint);
    final statusText = envelope.statusText?.trim();

    state = state.copyWith(
      remoteFingerprint: envelope.senderFingerprint,
      conversationId: conversationId,
      remoteStatusText: statusText == null || statusText.isEmpty
          ? null
          : statusText,
      lastEvent: statusText == null || statusText.isEmpty
          ? 'Peer cleared their custom status.'
          : 'Peer updated their custom status.',
    );
  }

  Future<void> _handleReceiptEnvelope(PeerTransportEnvelope envelope) async {
    final messageId = envelope.messageId;
    final receiptState = envelope.receiptState;
    if (messageId == null || receiptState == null) {
      throw const FormatException(
        'Incoming delivery receipt is missing receipt metadata.',
      );
    }

    final conversationId = state.conversationId ??
        conversationIdForFingerprint(envelope.senderFingerprint);
    final messageService = await _loadMessageService();
    await messageService.updateDeliveryState(messageId, receiptState);
    _refreshConversation(conversationId);

    state = state.copyWith(
      remoteFingerprint: envelope.senderFingerprint,
      conversationId: conversationId,
      lastEvent: switch (receiptState) {
        MessageDeliveryState.read => 'Peer read a secure message.',
        MessageDeliveryState.delivered => 'Peer received a secure message.',
        _ => 'Peer confirmed a secure message update.',
      },
    );
  }

  Future<void> _handleReactionEnvelope(PeerTransportEnvelope envelope) async {
    final messageId = envelope.messageId;
    final reactions = envelope.reactions;
    if (messageId == null || reactions == null) {
      throw const FormatException(
        'Incoming reaction update is missing reaction metadata.',
      );
    }

    final conversationId = state.conversationId ??
        conversationIdForFingerprint(envelope.senderFingerprint);
    final messageService = await _loadMessageService();
    await messageService.updateReactions(messageId, reactions);
    _refreshConversation(conversationId);

    state = state.copyWith(
      remoteFingerprint: envelope.senderFingerprint,
      conversationId: conversationId,
      lastEvent: 'Peer updated message reactions.',
    );
  }

  Future<void> _handleMessageEditEnvelope(PeerTransportEnvelope envelope) async {
    final messageId = envelope.messageId;
    final content = envelope.content;
    if (messageId == null || content == null || content.trim().isEmpty) {
      throw const FormatException(
        'Incoming message edit is missing edit metadata.',
      );
    }

    final conversationId = state.conversationId ??
        conversationIdForFingerprint(envelope.senderFingerprint);
    final messageService = await _loadMessageService();
    await messageService.updateMessageContent(
      messageId: messageId,
      body: content,
      editedAt: envelope.createdAt,
    );
    _refreshConversation(conversationId);

    state = state.copyWith(
      remoteFingerprint: envelope.senderFingerprint,
      conversationId: conversationId,
      lastEvent: 'Peer edited a message.',
    );
  }

  Future<void> _handleMessageDeleteEnvelope(
    PeerTransportEnvelope envelope,
  ) async {
    final messageId = envelope.messageId;
    final deleteMode = envelope.deleteMode;
    if (messageId == null || deleteMode == null) {
      throw const FormatException(
        'Incoming message delete is missing delete metadata.',
      );
    }

    final conversationId = state.conversationId ??
        conversationIdForFingerprint(envelope.senderFingerprint);
    final messageService = await _loadMessageService();
    if (deleteMode == MessageDeleteMode.hardDelete) {
      await messageService.deleteMessage(messageId);
    } else {
      await messageService.markMessageDeleted(
        messageId: messageId,
        deletedAt: envelope.createdAt,
        mode: deleteMode,
      );
    }
    _refreshConversation(conversationId);

    state = state.copyWith(
      remoteFingerprint: envelope.senderFingerprint,
      conversationId: conversationId,
      lastEvent: deleteMode == MessageDeleteMode.hardDelete
          ? 'Peer erased a message.'
          : 'Peer deleted a message.',
    );
  }

  Future<void> _sendTypingStatus(bool isTyping) async {
    if (!state.isTransportReady) {
      _localTypingActive = false;
      return;
    }

    final identity = await _ensureLocalIdentity();
    _localTypingActive = isTyping;

    try {
      await _webRtcManager.sendText(
        PeerTransportEnvelope.typing(
          senderFingerprint: identity.fingerprint,
          createdAt: DateTime.now(),
          isTyping: isTyping,
        ).encodeTransportString(),
      );
    } catch (error, stackTrace) {
      _localTypingActive = false;
      debugPrint('Typing update failed: $error\n$stackTrace');
    }
  }

  Future<void> _sendDeliveryReceipt(String messageId) async {
    await _sendReceipt(
      messageId: messageId,
      receiptState: MessageDeliveryState.delivered,
    );
  }

  Future<void> _sendReadReceipt(String messageId) async {
    await _sendReceipt(
      messageId: messageId,
      receiptState: MessageDeliveryState.read,
    );
  }

  Future<void> _sendReceipt({
    required String messageId,
    required MessageDeliveryState receiptState,
  }) async {
    if (!state.isTransportReady) {
      return;
    }

    final identity = await _ensureLocalIdentity();

    try {
      await _webRtcManager.sendText(
        PeerTransportEnvelope.receipt(
          messageId: messageId,
          senderFingerprint: identity.fingerprint,
          createdAt: DateTime.now(),
          receiptState: receiptState,
        ).encodeTransportString(),
      );
    } catch (error, stackTrace) {
      debugPrint('Receipt send failed: $error\n$stackTrace');
    }
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

  void _setError(String message) {
    state = state.copyWith(lastError: message);
  }

  bool _ensurePeerAllowed(String action) {
    final fingerprint = state.remoteFingerprint ?? state.expectedRemoteFingerprint;
    if (fingerprint == null || !_isBlockedFingerprint(fingerprint)) {
      return true;
    }

    _setError('Blocked contacts cannot $action.');
    return false;
  }
}

enum PeerTransportEnvelopeKind {
  message,
  typing,
  presence,
  statusText,
  receipt,
  reaction,
  messageEdit,
  messageDelete,
}

@immutable
class PeerTransportEnvelope {
  const PeerTransportEnvelope.message({
    required this.messageId,
    required this.senderFingerprint,
    required this.payload,
    required this.createdAt,
    required this.burnAfterRead,
    this.expiresAt,
    this.replyToMessageId,
    this.replyToBody,
  })  : kind = PeerTransportEnvelopeKind.message,
        isTyping = null,
        presenceStatus = null,
      statusText = null,
        receiptState = null,
      reactions = null,
      content = null,
      deleteMode = null;

  const PeerTransportEnvelope.typing({
    required this.senderFingerprint,
    required this.createdAt,
    required this.isTyping,
  })  : kind = PeerTransportEnvelopeKind.typing,
        presenceStatus = null,
      statusText = null,
        receiptState = null,
        messageId = null,
        payload = null,
        burnAfterRead = null,
        expiresAt = null,
        replyToMessageId = null,
        replyToBody = null,
        reactions = null,
        content = null,
        deleteMode = null;

  const PeerTransportEnvelope.presence({
    required this.senderFingerprint,
    required this.createdAt,
    required this.presenceStatus,
  })  : kind = PeerTransportEnvelopeKind.presence,
        isTyping = null,
      statusText = null,
        receiptState = null,
        messageId = null,
        payload = null,
        burnAfterRead = null,
        expiresAt = null,
        replyToMessageId = null,
        replyToBody = null,
        reactions = null,
        content = null,
        deleteMode = null;

  const PeerTransportEnvelope.statusText({
    required this.senderFingerprint,
    required this.createdAt,
    required this.statusText,
  })  : kind = PeerTransportEnvelopeKind.statusText,
        isTyping = null,
        presenceStatus = null,
        receiptState = null,
        messageId = null,
        payload = null,
        burnAfterRead = null,
        expiresAt = null,
        replyToMessageId = null,
        replyToBody = null,
        reactions = null,
        content = null,
        deleteMode = null;

  const PeerTransportEnvelope.receipt({
    required this.messageId,
    required this.senderFingerprint,
    required this.createdAt,
    required this.receiptState,
  })  : kind = PeerTransportEnvelopeKind.receipt,
        isTyping = null,
        presenceStatus = null,
      statusText = null,
        payload = null,
        burnAfterRead = null,
        expiresAt = null,
        replyToMessageId = null,
        replyToBody = null,
        reactions = null,
        content = null,
        deleteMode = null;

  const PeerTransportEnvelope.reaction({
    required this.messageId,
    required this.senderFingerprint,
    required this.createdAt,
    required this.reactions,
  })  : kind = PeerTransportEnvelopeKind.reaction,
        isTyping = null,
        presenceStatus = null,
      statusText = null,
        receiptState = null,
        payload = null,
        burnAfterRead = null,
        expiresAt = null,
        replyToMessageId = null,
        replyToBody = null,
        content = null,
        deleteMode = null;

  const PeerTransportEnvelope.messageEdit({
    required this.messageId,
    required this.senderFingerprint,
    required this.createdAt,
    required this.content,
  })  : kind = PeerTransportEnvelopeKind.messageEdit,
        isTyping = null,
        presenceStatus = null,
      statusText = null,
        receiptState = null,
        reactions = null,
        payload = null,
        burnAfterRead = null,
        expiresAt = null,
        replyToMessageId = null,
        replyToBody = null,
        deleteMode = null;

  const PeerTransportEnvelope.messageDelete({
    required this.messageId,
    required this.senderFingerprint,
    required this.createdAt,
    required this.deleteMode,
  })  : kind = PeerTransportEnvelopeKind.messageDelete,
        isTyping = null,
        presenceStatus = null,
      statusText = null,
        receiptState = null,
        reactions = null,
        payload = null,
        burnAfterRead = null,
        expiresAt = null,
        replyToMessageId = null,
        replyToBody = null,
        content = null;

  final PeerTransportEnvelopeKind kind;
  final String? messageId;
  final String senderFingerprint;
  final EncryptedPayload? payload;
  final DateTime createdAt;
  final bool? burnAfterRead;
  final DateTime? expiresAt;
  final String? replyToMessageId;
  final String? replyToBody;
  final bool? isTyping;
  final PeerPresenceStatus? presenceStatus;
  final String? statusText;
  final MessageDeliveryState? receiptState;
  final Map<String, List<String>>? reactions;
  final String? content;
  final MessageDeleteMode? deleteMode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'kind': kind.name,
      'senderFingerprint': senderFingerprint,
      'createdAt': createdAt.toIso8601String(),
      if (kind == PeerTransportEnvelopeKind.message) ...<String, dynamic>{
        'messageId': messageId,
        'payload': payload!.toJson(),
        'burnAfterRead': burnAfterRead,
        'expiresAt': expiresAt?.toIso8601String(),
        'replyToMessageId': replyToMessageId,
        'replyToBody': replyToBody,
      } else if (kind == PeerTransportEnvelopeKind.typing) ...<String, dynamic>{
        'isTyping': isTyping,
      } else if (kind == PeerTransportEnvelopeKind.presence) ...<String, dynamic>{
        'presenceStatus': presenceStatus!.name,
      } else if (kind == PeerTransportEnvelopeKind.statusText) ...<String, dynamic>{
        'statusText': statusText,
      } else if (kind == PeerTransportEnvelopeKind.reaction) ...<String, dynamic>{
        'messageId': messageId,
        'reactions': reactions,
      } else if (kind == PeerTransportEnvelopeKind.messageEdit) ...<String, dynamic>{
        'messageId': messageId,
        'content': content,
      } else if (kind == PeerTransportEnvelopeKind.messageDelete) ...<String, dynamic>{
        'messageId': messageId,
        'deleteMode': deleteMode!.name,
      } else ...<String, dynamic>{
        'messageId': messageId,
        'receiptState': receiptState!.name,
      },
    };
  }

  String encodeTransportString() => jsonEncode(toJson());

  factory PeerTransportEnvelope.fromJson(Map<String, dynamic> json) {
    final kind = switch (json['kind'] as String?) {
      'typing' => PeerTransportEnvelopeKind.typing,
      'presence' => PeerTransportEnvelopeKind.presence,
      'statusText' => PeerTransportEnvelopeKind.statusText,
      'receipt' => PeerTransportEnvelopeKind.receipt,
      'reaction' => PeerTransportEnvelopeKind.reaction,
      'messageEdit' => PeerTransportEnvelopeKind.messageEdit,
      'messageDelete' => PeerTransportEnvelopeKind.messageDelete,
      _ => PeerTransportEnvelopeKind.message,
    };

    if (kind == PeerTransportEnvelopeKind.typing) {
      return PeerTransportEnvelope.typing(
        senderFingerprint: json['senderFingerprint'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isTyping: json['isTyping'] as bool? ?? false,
      );
    }

    if (kind == PeerTransportEnvelopeKind.presence) {
      return PeerTransportEnvelope.presence(
        senderFingerprint: json['senderFingerprint'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        presenceStatus: json['presenceStatus'] == null
            ? PeerPresenceStatus.hidden
            : PeerPresenceStatus.values.byName(
                json['presenceStatus'] as String,
              ),
      );
    }

    if (kind == PeerTransportEnvelopeKind.receipt) {
      return PeerTransportEnvelope.receipt(
        messageId: json['messageId'] as String,
        senderFingerprint: json['senderFingerprint'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        receiptState: json['receiptState'] == null
            ? MessageDeliveryState.delivered
            : MessageDeliveryState.values.byName(
                json['receiptState'] as String,
              ),
      );
    }

    if (kind == PeerTransportEnvelopeKind.reaction) {
      return PeerTransportEnvelope.reaction(
        messageId: json['messageId'] as String,
        senderFingerprint: json['senderFingerprint'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        reactions: (json['reactions'] as Map<String, dynamic>).map(
          (emoji, users) => MapEntry(
            emoji,
            List<String>.from(users as List<dynamic>),
          ),
        ),
      );
    }

    if (kind == PeerTransportEnvelopeKind.statusText) {
      return PeerTransportEnvelope.statusText(
        senderFingerprint: json['senderFingerprint'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        statusText: json['statusText'] as String?,
      );
    }

    if (kind == PeerTransportEnvelopeKind.messageEdit) {
      return PeerTransportEnvelope.messageEdit(
        messageId: json['messageId'] as String,
        senderFingerprint: json['senderFingerprint'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        content: json['content'] as String,
      );
    }

    if (kind == PeerTransportEnvelopeKind.messageDelete) {
      return PeerTransportEnvelope.messageDelete(
        messageId: json['messageId'] as String,
        senderFingerprint: json['senderFingerprint'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        deleteMode: MessageDeleteMode.values.byName(
          json['deleteMode'] as String,
        ),
      );
    }

    return PeerTransportEnvelope.message(
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
      replyToMessageId: json['replyToMessageId'] as String?,
      replyToBody: json['replyToBody'] as String?,
    );
  }

  factory PeerTransportEnvelope.decodeTransportString(String value) {
    return PeerTransportEnvelope.fromJson(
      jsonDecode(value) as Map<String, dynamic>,
    );
  }
}

const Object _sentinel = Object();
