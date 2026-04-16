import 'package:flutter/foundation.dart';

enum CallType {
  voice,
  video,
}

enum CallStatus {
  idle,
  ringing,
  connecting,
  connected,
  ended,
  failed,
}

@immutable
class CallSession {
  const CallSession({
    required this.id,
    required this.peerId,
    required this.type,
    required this.status,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final String peerId;
  final CallType type;
  final CallStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
}
