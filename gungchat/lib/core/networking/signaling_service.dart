import 'dart:convert';

import 'package:flutter/foundation.dart';

enum SignalingEnvelopeType {
  offer,
  answer,
  iceCandidate,
}

@immutable
class SignalingEnvelope {
  const SignalingEnvelope({
    required this.type,
    required this.sessionId,
    required this.payload,
    required this.sentAt,
  });

  final SignalingEnvelopeType type;
  final String sessionId;
  final Map<String, dynamic> payload;
  final DateTime sentAt;

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'sessionId': sessionId,
      'payload': payload,
      'sentAt': sentAt.toIso8601String(),
    };
  }

  factory SignalingEnvelope.fromJson(Map<String, dynamic> json) {
    return SignalingEnvelope(
      type: SignalingEnvelopeType.values.byName(json['type'] as String),
      sessionId: json['sessionId'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }
}

class ManualSignalingService {
  const ManualSignalingService();

  String encode(SignalingEnvelope envelope) => jsonEncode(envelope.toJson());

  SignalingEnvelope decode(String value) {
    return SignalingEnvelope.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }
}
