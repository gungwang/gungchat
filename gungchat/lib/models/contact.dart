import 'package:flutter/foundation.dart';

enum ContactTrustLevel {
  unknown,
  verified,
  blocked,
}

@immutable
class Contact {
  const Contact({
    required this.id,
    required this.displayName,
    required this.fingerprint,
    this.lastKnownAddress,
    this.lastSeenAt,
    this.trustLevel = ContactTrustLevel.unknown,
    this.isLanDiscovered = false,
    this.note,
  });

  final String id;
  final String displayName;
  final String fingerprint;
  final String? lastKnownAddress;
  final DateTime? lastSeenAt;
  final ContactTrustLevel trustLevel;
  final bool isLanDiscovered;
  final String? note;
}
