import 'package:flutter/foundation.dart';

@immutable
class PeerConnectIntent {
  PeerConnectIntent({
    required this.fingerprint,
    this.autoStartOffer = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String fingerprint;
  final bool autoStartOffer;
  final DateTime createdAt;
}