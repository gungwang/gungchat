import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' hide MessageType;

import '../../core/networking/ice_manager.dart';
import '../../core/networking/signaling_service.dart';
import '../../models/call.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import 'message_service.dart';

typedef DispatchMediaCallSignal = Future<void> Function({
  required String encodedSignal,
  required String targetAddress,
});

const Object _sentinel = Object();
final Uint8List _ringtoneBytes = _buildRingtoneBytes();

@immutable
class MediaCallState {
  const MediaCallState({
    this.type = CallType.video,
    this.status = CallStatus.idle,
    this.sessionId,
    this.contact,
    this.targetAddress,
    this.note,
    this.connectedAt,
    this.callDuration = Duration.zero,
    this.isMuted = false,
    this.isCameraEnabled = true,
    this.isSpeakerOn = true,
    this.isFrontCamera = true,
    this.hasLocalVideo = false,
    this.hasRemoteVideo = false,
    this.localRenderer,
    this.remoteRenderer,
  });

  final CallType type;
  final CallStatus status;
  final String? sessionId;
  final Contact? contact;
  final String? targetAddress;
  final String? note;
  final DateTime? connectedAt;
  final Duration callDuration;
  final bool isMuted;
  final bool isCameraEnabled;
  final bool isSpeakerOn;
  final bool isFrontCamera;
  final bool hasLocalVideo;
  final bool hasRemoteVideo;
  final RTCVideoRenderer? localRenderer;
  final RTCVideoRenderer? remoteRenderer;

  bool get isIdle => status == CallStatus.idle;

  bool get isIncoming => status == CallStatus.incoming;

  bool get isConnected => status == CallStatus.connected;

  bool get hasDuration => callDuration > Duration.zero;

  String get durationLabel => _formatCallDuration(callDuration);

  bool get isTerminal =>
      status == CallStatus.ended || status == CallStatus.failed;

  bool get isOngoing {
    switch (status) {
      case CallStatus.idle:
      case CallStatus.ended:
      case CallStatus.failed:
        return false;
      case CallStatus.outgoing:
      case CallStatus.incoming:
      case CallStatus.connecting:
      case CallStatus.connected:
        return true;
    }
  }

  bool get hasOverlay => !isIdle;

  bool get showIncomingActions => status == CallStatus.incoming;

  bool get showCallControls {
    switch (status) {
      case CallStatus.outgoing:
      case CallStatus.connecting:
      case CallStatus.connected:
        return true;
      case CallStatus.idle:
      case CallStatus.incoming:
      case CallStatus.ended:
      case CallStatus.failed:
        return false;
    }
  }

  bool get showLocalPreview =>
      localRenderer != null &&
      status != CallStatus.idle &&
      status != CallStatus.incoming;

  bool get showRemoteVideo => remoteRenderer != null && hasRemoteVideo;

  String get statusText {
    if (note != null && note!.trim().isNotEmpty) {
      return note!;
    }

    switch (status) {
      case CallStatus.idle:
        return '';
      case CallStatus.outgoing:
        return 'Calling…';
      case CallStatus.incoming:
        return 'Incoming video call';
      case CallStatus.connecting:
        return 'Connecting…';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.ended:
        return 'Call ended';
      case CallStatus.failed:
        return 'Call failed';
    }
  }

  MediaCallState copyWith({
    CallType? type,
    CallStatus? status,
    Object? sessionId = _sentinel,
    Object? contact = _sentinel,
    Object? targetAddress = _sentinel,
    Object? note = _sentinel,
    Object? connectedAt = _sentinel,
    Duration? callDuration,
    bool? isMuted,
    bool? isCameraEnabled,
    bool? isSpeakerOn,
    bool? isFrontCamera,
    bool? hasLocalVideo,
    bool? hasRemoteVideo,
    Object? localRenderer = _sentinel,
    Object? remoteRenderer = _sentinel,
  }) {
    return MediaCallState(
      type: type ?? this.type,
      status: status ?? this.status,
      sessionId:
          identical(sessionId, _sentinel) ? this.sessionId : sessionId as String?,
      contact: identical(contact, _sentinel) ? this.contact : contact as Contact?,
      targetAddress: identical(targetAddress, _sentinel)
          ? this.targetAddress
          : targetAddress as String?,
      note: identical(note, _sentinel) ? this.note : note as String?,
      connectedAt: identical(connectedAt, _sentinel)
          ? this.connectedAt
          : connectedAt as DateTime?,
      callDuration: callDuration ?? this.callDuration,
      isMuted: isMuted ?? this.isMuted,
      isCameraEnabled: isCameraEnabled ?? this.isCameraEnabled,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      hasLocalVideo: hasLocalVideo ?? this.hasLocalVideo,
      hasRemoteVideo: hasRemoteVideo ?? this.hasRemoteVideo,
      localRenderer: identical(localRenderer, _sentinel)
          ? this.localRenderer
          : localRenderer as RTCVideoRenderer?,
      remoteRenderer: identical(remoteRenderer, _sentinel)
          ? this.remoteRenderer
          : remoteRenderer as RTCVideoRenderer?,
    );
  }
}

class MediaCallController extends StateNotifier<MediaCallState> {
  MediaCallController({
    required IceManager iceManager,
    required ManualSignalingService signalingService,
    required DispatchMediaCallSignal dispatchLocalSignal,
    required Future<MessageService> Function() loadMessageService,
    required Future<String> Function() loadLocalSenderId,
    required void Function(String conversationId) refreshConversation,
    AudioPlayer? ringtonePlayer,
    DateTime Function()? now,
  })  : _iceManager = iceManager,
        _signalingService = signalingService,
        _dispatchLocalSignal = dispatchLocalSignal,
        _loadMessageService = loadMessageService,
        _loadLocalSenderId = loadLocalSenderId,
        _refreshConversation = refreshConversation,
        _ringtonePlayer =
            ringtonePlayer ?? AudioPlayer(playerId: 'media-call-ringtone'),
        _now = now ?? DateTime.now,
        super(const MediaCallState());

  final IceManager _iceManager;
  final ManualSignalingService _signalingService;
  final DispatchMediaCallSignal _dispatchLocalSignal;
  final Future<MessageService> Function() _loadMessageService;
  final Future<String> Function() _loadLocalSenderId;
  final void Function(String conversationId) _refreshConversation;
  final AudioPlayer _ringtonePlayer;
  final DateTime Function() _now;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  RTCSessionDescription? _pendingRemoteOffer;
  final List<RTCIceCandidate> _pendingRemoteIceCandidates = <RTCIceCandidate>[];
  bool _hasRemoteDescription = false;
  bool _isCleaningUp = false;
  Timer? _durationTimer;
  Timer? _systemAlertTimer;

  Future<void> startOutgoingCall(Contact contact) async {
    final targetAddress = contact.lastKnownAddress?.trim();
    if (targetAddress == null || targetAddress.isEmpty) {
      throw StateError(
        'This contact does not have a reachable LAN address for video calling yet.',
      );
    }

    if (state.isOngoing) {
      throw StateError('Another call is already in progress.');
    }

    final sessionId = _nextSessionId(contact.fingerprint);
    await _prepareFreshCall(
      contact: contact,
      sessionId: sessionId,
      targetAddress: targetAddress,
      status: CallStatus.outgoing,
      note: 'Calling ${contact.displayName}…',
    );
    await _startRinging();

    try {
      await _ensureLocalMedia();
      await _ensurePeerConnection();
      await _addLocalTracks();

      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      await _sendSignal(
        type: SignalingEnvelopeType.callOffer,
        sessionId: sessionId,
        targetAddress: targetAddress,
        payload: _descriptionPayload(offer),
      );

      if (!mounted) {
        return;
      }

      state = state.copyWith(
        note: 'Waiting for ${contact.displayName} to answer…',
      );
    } catch (error, stackTrace) {
      debugPrint('Outgoing video call failed: $error\n$stackTrace');
      await _setTerminalState(
        CallStatus.failed,
        _describeStartCallFailure(error),
      );
      rethrow;
    }
  }

  Future<void> acceptIncomingCall() async {
    if (!state.isIncoming || _pendingRemoteOffer == null) {
      return;
    }

    final sessionId = state.sessionId;
    final targetAddress = state.targetAddress;
    if (sessionId == null || targetAddress == null || targetAddress.isEmpty) {
      await _setTerminalState(
        CallStatus.failed,
        'This incoming call is missing routing information.',
      );
      return;
    }

    await _stopRinging();
    try {
      await _ensureLocalMedia();
      await _ensurePeerConnection();
      await _addLocalTracks();
      await _peerConnection!.setRemoteDescription(_pendingRemoteOffer!);
      _hasRemoteDescription = true;
      await _flushPendingRemoteIceCandidates();

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      await _sendSignal(
        type: SignalingEnvelopeType.callAnswer,
        sessionId: sessionId,
        targetAddress: targetAddress,
        payload: _descriptionPayload(answer),
      );
      _pendingRemoteOffer = null;

      if (!mounted) {
        return;
      }

      state = state.copyWith(
        status: CallStatus.connecting,
        note: 'Joining ${state.contact?.displayName ?? 'video call'}…',
      );
    } catch (error, stackTrace) {
      debugPrint('Accepting video call failed: $error\n$stackTrace');
      await _sendSignal(
        type: SignalingEnvelopeType.callDecline,
        sessionId: sessionId,
        targetAddress: targetAddress,
        payload: const <String, dynamic>{'reason': 'media-unavailable'},
      );
      await _setTerminalState(
        CallStatus.failed,
        _describeMediaAccessFailure(error),
      );
    }
  }

  Future<void> declineIncomingCall() async {
    if (!state.isIncoming) {
      return;
    }

    await _sendSignalForCurrentCall(
      SignalingEnvelopeType.callDecline,
      payload: const <String, dynamic>{'reason': 'declined'},
    );
    await dismiss();
  }

  Future<void> hangUp() async {
    if (!state.isOngoing) {
      await dismiss();
      return;
    }

    final hangupReason = state.isConnected ? 'ended' : 'canceled';
    await _sendSignalForCurrentCall(
      SignalingEnvelopeType.callHangup,
      payload: <String, dynamic>{'reason': hangupReason},
    );
    await dismiss();
  }

  Future<void> dismiss() async {
    await _resetToIdle();
  }

  Future<void> toggleMute() async {
    final stream = _localStream;
    if (stream == null) {
      return;
    }

    final nextMuted = !state.isMuted;
    for (final track in stream.getAudioTracks()) {
      track.enabled = !nextMuted;
    }

    if (!mounted) {
      return;
    }

    state = state.copyWith(isMuted: nextMuted);
  }

  Future<void> toggleCamera() async {
    final stream = _localStream;
    if (stream == null) {
      return;
    }

    final nextEnabled = !state.isCameraEnabled;
    for (final track in stream.getVideoTracks()) {
      track.enabled = nextEnabled;
    }

    if (!mounted) {
      return;
    }

    state = state.copyWith(
      isCameraEnabled: nextEnabled,
      hasLocalVideo: nextEnabled,
    );
  }

  Future<void> switchCamera() async {
    final stream = _localStream;
    if (stream == null) {
      return;
    }

    final tracks = stream.getVideoTracks();
    if (tracks.isEmpty) {
      return;
    }

    try {
      final isFrontCamera = await Helper.switchCamera(tracks.first);
      if (!mounted) {
        return;
      }
      state = state.copyWith(isFrontCamera: isFrontCamera);
    } catch (error, stackTrace) {
      debugPrint('Switch camera failed: $error\n$stackTrace');
    }
  }

  Future<void> toggleSpeaker() async {
    final nextSpeakerOn = !state.isSpeakerOn;
    try {
      await Helper.setSpeakerphoneOn(nextSpeakerOn);
    } catch (error, stackTrace) {
      debugPrint('Speaker toggle failed: $error\n$stackTrace');
    }

    if (!mounted) {
      return;
    }

    state = state.copyWith(isSpeakerOn: nextSpeakerOn);
  }

  Future<void> applyRemoteSignal(
    String rawSignal, {
    Contact? targetContact,
  }) async {
    final trimmed = rawSignal.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final envelope = _signalingService.decode(trimmed);
    if (!envelope.type.isCallSignal) {
      return;
    }

    switch (envelope.type) {
      case SignalingEnvelopeType.callOffer:
        await _handleRemoteOffer(envelope, targetContact: targetContact);
      case SignalingEnvelopeType.callAnswer:
        await _handleRemoteAnswer(envelope, targetContact: targetContact);
      case SignalingEnvelopeType.callIceCandidate:
        await _handleRemoteIceCandidate(envelope);
      case SignalingEnvelopeType.callDecline:
        await _handleRemoteDecline(envelope);
      case SignalingEnvelopeType.callHangup:
        await _handleRemoteHangup(envelope);
      case SignalingEnvelopeType.offer:
      case SignalingEnvelopeType.answer:
      case SignalingEnvelopeType.iceCandidate:
        return;
    }
  }

  Future<void> _handleRemoteOffer(
    SignalingEnvelope envelope, {
    Contact? targetContact,
  }) async {
    final targetAddress = targetContact?.lastKnownAddress?.trim();
    if (targetAddress == null || targetAddress.isEmpty) {
      return;
    }

    if (state.isOngoing && state.sessionId != envelope.sessionId) {
      await _sendSignal(
        type: SignalingEnvelopeType.callDecline,
        sessionId: envelope.sessionId,
        targetAddress: targetAddress,
        payload: const <String, dynamic>{'reason': 'busy'},
      );
      return;
    }

    await _clearSessionResources();
    await _ensureRenderers();
    _pendingRemoteOffer = _sessionDescriptionFromPayload(envelope.payload);
    _pendingRemoteIceCandidates.clear();
    _hasRemoteDescription = false;

    if (!mounted) {
      return;
    }

    state = MediaCallState(
      type: CallType.video,
      status: CallStatus.incoming,
      sessionId: envelope.sessionId,
      contact: targetContact,
      targetAddress: targetAddress,
      note: 'Incoming video call',
      localRenderer: _localRenderer,
      remoteRenderer: _remoteRenderer,
    );
    await _startRinging();
  }

  Future<void> _handleRemoteAnswer(
    SignalingEnvelope envelope, {
    Contact? targetContact,
  }) async {
    if (state.sessionId != envelope.sessionId || _peerConnection == null) {
      return;
    }

    await _peerConnection!.setRemoteDescription(
      _sessionDescriptionFromPayload(envelope.payload),
    );
    _hasRemoteDescription = true;
    await _flushPendingRemoteIceCandidates();
    await _stopRinging();

    if (!mounted) {
      return;
    }

    state = state.copyWith(
      contact: targetContact ?? state.contact,
      note: 'Connecting video…',
      status: CallStatus.connecting,
    );
  }

  Future<void> _handleRemoteIceCandidate(SignalingEnvelope envelope) async {
    if (state.sessionId != envelope.sessionId) {
      return;
    }

    final candidate = _iceCandidateFromPayload(envelope.payload);
    if (_peerConnection == null || !_hasRemoteDescription) {
      _pendingRemoteIceCandidates.add(candidate);
      return;
    }

    await _peerConnection!.addCandidate(candidate);
  }

  Future<void> _handleRemoteDecline(SignalingEnvelope envelope) async {
    if (state.sessionId != envelope.sessionId) {
      return;
    }

    final reason = envelope.payload['reason'] as String?;
    final displayName = state.contact?.displayName ?? 'Peer';
    final message = switch (reason) {
      'busy' => '$displayName is already on another call.',
      'media-unavailable' =>
        '$displayName could not access their camera or microphone.',
      _ => '$displayName declined the video call.',
    };

    await _setTerminalState(CallStatus.ended, message);
  }

  Future<void> _handleRemoteHangup(SignalingEnvelope envelope) async {
    if (state.sessionId != envelope.sessionId) {
      return;
    }

    final reason = envelope.payload['reason'] as String?;
    final wasIncoming = state.status == CallStatus.incoming;
    final displayName = state.contact?.displayName ?? 'Peer';
    if (wasIncoming) {
      await _logConversationEvent('Missed video call from $displayName');
      await _setTerminalState(CallStatus.ended, 'Missed video call');
      return;
    }

    final message = switch (reason) {
      'canceled' => '$displayName canceled the video call.',
      _ when _currentCallDuration() > Duration.zero => 'The video call ended.',
      _ => '$displayName ended the video call before it connected.',
    };
    await _setTerminalState(CallStatus.ended, message);
  }

  Future<void> _prepareFreshCall({
    required Contact contact,
    required String sessionId,
    required String targetAddress,
    required CallStatus status,
    required String note,
  }) async {
    await _clearSessionResources();
    await _ensureRenderers();
    _pendingRemoteOffer = null;
    _pendingRemoteIceCandidates.clear();
    _hasRemoteDescription = false;

    if (!mounted) {
      return;
    }

    state = MediaCallState(
      type: CallType.video,
      status: status,
      sessionId: sessionId,
      contact: contact,
      targetAddress: targetAddress,
      note: note,
      localRenderer: _localRenderer,
      remoteRenderer: _remoteRenderer,
    );
  }

  Future<void> _ensureRenderers() async {
    if (_localRenderer == null) {
      _localRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();
    }
    if (_remoteRenderer == null) {
      _remoteRenderer = RTCVideoRenderer();
      await _remoteRenderer!.initialize();
    }

    if (!mounted) {
      return;
    }

    state = state.copyWith(
      localRenderer: _localRenderer,
      remoteRenderer: _remoteRenderer,
    );
  }

  Future<void> _ensureLocalMedia() async {
    if (_localStream != null) {
      return;
    }

    await _ensureRenderers();
    final stream = await navigator.mediaDevices.getUserMedia(
      <String, dynamic>{
        'audio': <String, dynamic>{
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': <String, dynamic>{
          'mandatory': <String, dynamic>{
            'minWidth': '320',
            'minHeight': '240',
            'minFrameRate': '15',
          },
          'facingMode': 'user',
          'optional': const <dynamic>[],
        },
      },
    );

    _localStream = stream;
    _localRenderer?.srcObject = stream;

    try {
      await Helper.setSpeakerphoneOn(true);
    } catch (error, stackTrace) {
      debugPrint('Default speaker route failed: $error\n$stackTrace');
    }

    if (!mounted) {
      return;
    }

    state = state.copyWith(
      hasLocalVideo: stream.getVideoTracks().isNotEmpty,
      isCameraEnabled: true,
      isSpeakerOn: true,
    );
  }

  Future<void> _ensurePeerConnection() async {
    if (_peerConnection != null) {
      return;
    }

    final peerConnection =
        await createPeerConnection(_iceManager.buildConfiguration());

    peerConnection
      ..onConnectionState = (connectionState) {
        if (_isCleaningUp || !mounted || state.isIdle || state.isTerminal) {
          return;
        }

        switch (connectionState) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            final connectedAt = state.connectedAt ?? _now();
            _startDurationTicker(connectedAt);
            unawaited(_stopRinging());
            state = state.copyWith(
              status: CallStatus.connected,
              note: 'Connected',
              connectedAt: connectedAt,
              callDuration: _now().difference(connectedAt),
            );
          case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
            if (state.status == CallStatus.connecting) {
              state = state.copyWith(note: 'Connecting video…');
            }
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            unawaited(
              _setTerminalState(
                _currentCallDuration() > Duration.zero
                    ? CallStatus.ended
                    : CallStatus.failed,
                _currentCallDuration() > Duration.zero
                    ? 'Connection lost. Check Wi-Fi or LAN stability and try again.'
                    : 'Could not connect to the other device. Keep both devices on the same LAN and try again.',
              ),
            );
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            unawaited(
              _setTerminalState(
                CallStatus.failed,
                _currentCallDuration() > Duration.zero
                    ? 'The video call became unstable and had to stop.'
                    : 'Could not establish a stable video stream. Check camera permissions and LAN connectivity, then try again.',
              ),
            );
          case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
            unawaited(_setTerminalState(CallStatus.ended, 'The video call ended.'));
          case RTCPeerConnectionState.RTCPeerConnectionStateNew:
            break;
        }
      }
      ..onIceCandidate = (candidate) {
        final candidateValue = candidate.candidate;
        final sessionId = state.sessionId;
        final targetAddress = state.targetAddress;
        if (_isCleaningUp ||
            sessionId == null ||
            targetAddress == null ||
            targetAddress.isEmpty ||
            candidateValue == null ||
            candidateValue.isEmpty) {
          return;
        }

        unawaited(
          _sendSignal(
            type: SignalingEnvelopeType.callIceCandidate,
            sessionId: sessionId,
            targetAddress: targetAddress,
            payload: <String, dynamic>{'candidate': candidate.toMap()},
          ),
        );
      }
      ..onTrack = (event) {
        if (_isCleaningUp || !mounted || event.streams.isEmpty) {
          return;
        }

        final remoteStream = event.streams.first;
        _remoteRenderer?.srcObject = remoteStream;
        state = state.copyWith(
          hasRemoteVideo: remoteStream.getVideoTracks().isNotEmpty,
        );
      };

    _peerConnection = peerConnection;
  }

  Future<void> _addLocalTracks() async {
    final peerConnection = _peerConnection;
    final localStream = _localStream;
    if (peerConnection == null || localStream == null) {
      return;
    }

    for (final track in localStream.getTracks()) {
      await peerConnection.addTrack(track, localStream);
    }
  }

  Future<void> _flushPendingRemoteIceCandidates() async {
    final peerConnection = _peerConnection;
    if (peerConnection == null) {
      return;
    }

    final queuedCandidates = List<RTCIceCandidate>.from(
      _pendingRemoteIceCandidates,
    );
    _pendingRemoteIceCandidates.clear();

    for (final candidate in queuedCandidates) {
      await peerConnection.addCandidate(candidate);
    }
  }

  Future<void> _sendSignalForCurrentCall(
    SignalingEnvelopeType type, {
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) async {
    final sessionId = state.sessionId;
    final targetAddress = state.targetAddress;
    if (sessionId == null || targetAddress == null || targetAddress.isEmpty) {
      return;
    }

    await _sendSignal(
      type: type,
      sessionId: sessionId,
      targetAddress: targetAddress,
      payload: payload,
    );
  }

  Future<void> _sendSignal({
    required SignalingEnvelopeType type,
    required String sessionId,
    required String targetAddress,
    required Map<String, dynamic> payload,
  }) async {
    final encodedSignal = _signalingService.encode(
      SignalingEnvelope(
        type: type,
        sessionId: sessionId,
        payload: payload,
        sentAt: _now(),
      ),
    );

    await _dispatchLocalSignal(
      encodedSignal: encodedSignal,
      targetAddress: targetAddress,
    );
  }

  Future<void> _setTerminalState(CallStatus status, String note) async {
    final sessionId = state.sessionId;
    final contact = state.contact;
    final targetAddress = state.targetAddress;
    final connectedAt = state.connectedAt;
    final callDuration = _currentCallDuration();

    await _clearSessionResources();
    await _ensureRenderers();

    if (!mounted) {
      return;
    }

    state = MediaCallState(
      type: CallType.video,
      status: status,
      sessionId: sessionId,
      contact: contact,
      targetAddress: targetAddress,
      note: note,
      connectedAt: connectedAt,
      callDuration: callDuration,
      localRenderer: _localRenderer,
      remoteRenderer: _remoteRenderer,
    );
  }

  Future<void> _resetToIdle() async {
    await _clearSessionResources();
    await _ensureRenderers();

    if (!mounted) {
      return;
    }

    state = MediaCallState(
      localRenderer: _localRenderer,
      remoteRenderer: _remoteRenderer,
    );
  }

  Future<void> _clearSessionResources() async {
    if (_isCleaningUp) {
      return;
    }

    _isCleaningUp = true;
    try {
      _durationTimer?.cancel();
      _durationTimer = null;
      await _stopRinging();
      _pendingRemoteOffer = null;
      _pendingRemoteIceCandidates.clear();
      _hasRemoteDescription = false;

      final remoteStream = _remoteRenderer?.srcObject;
      _remoteRenderer?.srcObject = null;
      if (remoteStream != null) {
        for (final track in remoteStream.getTracks()) {
          try {
            await track.stop();
          } catch (_) {
            // Ignore cleanup failures while tearing the call down.
          }
        }
        await remoteStream.dispose();
      }

      _localRenderer?.srcObject = null;

      final peerConnection = _peerConnection;
      _peerConnection = null;
      if (peerConnection != null) {
        try {
          await peerConnection.close();
        } catch (_) {
          // Ignore cleanup failures while tearing the call down.
        }
        await peerConnection.dispose();
      }

      final localStream = _localStream;
      _localStream = null;
      if (localStream != null) {
        for (final track in localStream.getTracks()) {
          try {
            await track.stop();
          } catch (_) {
            // Ignore cleanup failures while tearing the call down.
          }
        }
        await localStream.dispose();
      }
    } finally {
      _isCleaningUp = false;
    }
  }

  void _startDurationTicker(DateTime connectedAt) {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !state.isConnected || state.connectedAt == null) {
        return;
      }

      state = state.copyWith(
        callDuration: _now().difference(state.connectedAt!),
      );
    });
  }

  Duration _currentCallDuration() {
    final connectedAt = state.connectedAt;
    if (connectedAt == null) {
      return state.callDuration;
    }

    final liveDuration = _now().difference(connectedAt);
    return liveDuration > state.callDuration ? liveDuration : state.callDuration;
  }

  Future<void> _startRinging() async {
    await _stopRinging();
    try {
      await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
      await _ringtonePlayer.play(
        BytesSource(_ringtoneBytes, mimeType: 'audio/wav'),
        volume: 0.72,
      );
    } catch (error, stackTrace) {
      debugPrint('Ringtone playback failed: $error\n$stackTrace');
      unawaited(SystemSound.play(SystemSoundType.alert));
      _systemAlertTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        unawaited(SystemSound.play(SystemSoundType.alert));
      });
    }
  }

  Future<void> _stopRinging() async {
    _systemAlertTimer?.cancel();
    _systemAlertTimer = null;
    try {
      await _ringtonePlayer.stop();
    } catch (error, stackTrace) {
      debugPrint('Ringtone stop failed: $error\n$stackTrace');
    }
  }

  String _describeStartCallFailure(Object error) {
    final message = error.toString().toLowerCase();
    if (_looksLikeMediaAccessError(message)) {
      return _describeMediaAccessFailure(error);
    }

    return 'Could not start the video call. Keep both devices on the same LAN and try again.';
  }

  String _describeMediaAccessFailure(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('permission') ||
        message.contains('denied') ||
        message.contains('notallowed')) {
      return 'Camera or microphone access was denied. Check app permissions and device privacy settings.';
    }
    if (message.contains('notfound') ||
        message.contains('no device') ||
        message.contains('no such device') ||
        message.contains('device not found')) {
      return 'No usable camera or microphone was found on this device.';
    }
    if (message.contains('busy') ||
        message.contains('notreadable') ||
        message.contains('in use')) {
      return 'The camera or microphone is busy in another app. Close the other app and try again.';
    }

    return 'Could not access the camera or microphone. Check app permissions and device privacy settings.';
  }

  bool _looksLikeMediaAccessError(String message) {
    return message.contains('permission') ||
        message.contains('denied') ||
        message.contains('notallowed') ||
        message.contains('notfound') ||
        message.contains('no device') ||
        message.contains('busy') ||
        message.contains('notreadable') ||
        message.contains('getusermedia');
  }

  Future<void> _logConversationEvent(String body) async {
    final contact = state.contact;
    if (contact == null) {
      return;
    }

    final conversationId = conversationIdForFingerprint(contact.fingerprint);
    try {
      final messageService = await _loadMessageService();
      final senderId = await _loadLocalSenderId();
      await messageService.createLocalMessage(
        conversationId: conversationId,
        senderId: senderId,
        body: body,
        type: MessageType.system,
        burnAfterRead: false,
      );
      _refreshConversation(conversationId);
    } catch (error, stackTrace) {
      debugPrint('Call event log failed: $error\n$stackTrace');
    }
  }

  String _nextSessionId(String fingerprint) {
    return 'call-${fingerprint.replaceAll(':', '')}-${_now().microsecondsSinceEpoch}';
  }

  Map<String, dynamic> _descriptionPayload(RTCSessionDescription description) {
    return <String, dynamic>{
      'description': description.toMap(),
      'kind': CallType.video.name,
    };
  }

  RTCSessionDescription _sessionDescriptionFromPayload(
    Map<String, dynamic> payload,
  ) {
    final description = Map<String, dynamic>.from(
      payload['description'] as Map<dynamic, dynamic>,
    );
    return RTCSessionDescription(
      description['sdp'] as String?,
      description['type'] as String?,
    );
  }

  RTCIceCandidate _iceCandidateFromPayload(Map<String, dynamic> payload) {
    final candidate = Map<String, dynamic>.from(
      payload['candidate'] as Map<dynamic, dynamic>,
    );
    return RTCIceCandidate(
      candidate['candidate'] as String?,
      candidate['sdpMid'] as String?,
      candidate['sdpMLineIndex'] as int?,
    );
  }

  Future<void> _disposeAsync() async {
    await _clearSessionResources();
    await _ringtonePlayer.dispose();

    final localRenderer = _localRenderer;
    _localRenderer = null;
    if (localRenderer != null) {
      await localRenderer.dispose();
    }

    final remoteRenderer = _remoteRenderer;
    _remoteRenderer = null;
    if (remoteRenderer != null) {
      await remoteRenderer.dispose();
    }
  }

  @override
  void dispose() {
    unawaited(_disposeAsync());
    super.dispose();
  }
}

String _formatCallDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

Uint8List _buildRingtoneBytes() {
  const sampleRate = 22050;
  const amplitude = 0.22;
  final samples = <int>[];

  void appendTone(double frequencyHz, int milliseconds) {
    final sampleCount = (sampleRate * milliseconds / 1000).round();
    for (var index = 0; index < sampleCount; index++) {
      final time = index / sampleRate;
      final sample =
          (math.sin(2 * math.pi * frequencyHz * time) * 32767 * amplitude)
              .round();
      samples.add(sample.clamp(-32768, 32767));
    }
  }

  void appendSilence(int milliseconds) {
    final sampleCount = (sampleRate * milliseconds / 1000).round();
    samples.addAll(List<int>.filled(sampleCount, 0));
  }

  appendTone(660, 180);
  appendSilence(90);
  appendTone(880, 180);
  appendSilence(1050);

  final dataLength = samples.length * 2;
  final byteData = ByteData(44 + dataLength);

  void writeAscii(int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      byteData.setUint8(offset + index, value.codeUnitAt(index));
    }
  }

  writeAscii(0, 'RIFF');
  byteData.setUint32(4, 36 + dataLength, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  byteData.setUint32(16, 16, Endian.little);
  byteData.setUint16(20, 1, Endian.little);
  byteData.setUint16(22, 1, Endian.little);
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(28, sampleRate * 2, Endian.little);
  byteData.setUint16(32, 2, Endian.little);
  byteData.setUint16(34, 16, Endian.little);
  writeAscii(36, 'data');
  byteData.setUint32(40, dataLength, Endian.little);

  var offset = 44;
  for (final sample in samples) {
    byteData.setInt16(offset, sample, Endian.little);
    offset += 2;
  }

  return byteData.buffer.asUint8List();
}