import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'data_channel_text_framer.dart';
import 'ice_manager.dart';

enum WebRtcSessionState {
  idle,
  connecting,
  open,
  disconnected,
  failed,
  closed,
}

class WebRtcManager {
  WebRtcManager({
    required IceManager iceManager,
    DataChannelTextFramer? textFramer,
  })  : _iceManager = iceManager,
        _textFramer = textFramer ?? DataChannelTextFramer();

  final IceManager _iceManager;
  final DataChannelTextFramer _textFramer;
  final StreamController<WebRtcSessionState> _stateController =
      StreamController<WebRtcSessionState>.broadcast();

  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  Stream<WebRtcSessionState> get states => _stateController.stream;

  bool get isOpen =>
      _dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen;

  Future<void> initialize({
    required bool initiator,
    required void Function(String message) onMessage,
    void Function(RTCIceCandidate candidate)? onIceCandidate,
  }) async {
    _peerConnection =
        await createPeerConnection(_iceManager.buildConfiguration());
    _stateController.add(WebRtcSessionState.connecting);

    _peerConnection!
      ..onConnectionState = (state) {
        _stateController.add(_mapConnectionState(state));
      }
      ..onIceCandidate = (candidate) {
        if (onIceCandidate != null) {
          onIceCandidate(candidate);
        }
      }
      ..onDataChannel = (channel) {
        _bindDataChannel(channel, onMessage);
      };

    if (initiator) {
      final channel = await _peerConnection!.createDataChannel(
        'messages',
        RTCDataChannelInit()..ordered = true,
      );
      _bindDataChannel(channel, onMessage);
    }
  }

  Future<RTCSessionDescription> createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer(
    RTCSessionDescription remoteOffer,
  ) async {
    await _peerConnection!.setRemoteDescription(remoteOffer);
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  Future<void> applyRemoteDescription(RTCSessionDescription description) async {
    await _peerConnection!.setRemoteDescription(description);
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    await _peerConnection!.addCandidate(candidate);
  }

  Future<void> sendText(String message) async {
    if (!isOpen) {
      throw StateError('RTC data channel is not open.');
    }
    for (final frame in _textFramer.frame(message)) {
      await _dataChannel!.send(RTCDataChannelMessage(frame));
    }
  }

  Future<void> close() async {
    _stateController.add(WebRtcSessionState.closed);
    await _dataChannel?.close();
    await _peerConnection?.close();
    _dataChannel = null;
    _peerConnection = null;
    _textFramer.clear();
  }

  void _bindDataChannel(
    RTCDataChannel channel,
    void Function(String message) onMessage,
  ) {
    _dataChannel = channel;

    channel
      ..onDataChannelState = (state) {
        switch (state) {
          case RTCDataChannelState.RTCDataChannelOpen:
            _stateController.add(WebRtcSessionState.open);
          case RTCDataChannelState.RTCDataChannelClosed:
            _stateController.add(WebRtcSessionState.closed);
          case RTCDataChannelState.RTCDataChannelClosing:
            _stateController.add(WebRtcSessionState.disconnected);
          case RTCDataChannelState.RTCDataChannelConnecting:
            _stateController.add(WebRtcSessionState.connecting);
        }
      }
      ..onMessage = (message) {
        if (!message.isBinary) {
          final reassembledMessage = _textFramer.consumeFrame(message.text);
          if (reassembledMessage != null) {
            onMessage(reassembledMessage);
          }
        }
      };
  }

  WebRtcSessionState _mapConnectionState(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        return WebRtcSessionState.connecting;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        return WebRtcSessionState.connecting;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        return WebRtcSessionState.disconnected;
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        return WebRtcSessionState.closed;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        return WebRtcSessionState.failed;
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
        return WebRtcSessionState.idle;
    }
  }
}
