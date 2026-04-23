import 'package:flutter/foundation.dart';

String conversationIdForFingerprint(String fingerprint) => 'peer:$fingerprint';

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

  Contact copyWith({
    String? id,
    String? displayName,
    String? fingerprint,
    String? lastKnownAddress,
    DateTime? lastSeenAt,
    ContactTrustLevel? trustLevel,
    bool? isLanDiscovered,
    String? note,
    bool clearLastKnownAddress = false,
    bool clearLastSeenAt = false,
    bool clearNote = false,
  }) {
    return Contact(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      fingerprint: fingerprint ?? this.fingerprint,
      lastKnownAddress: clearLastKnownAddress
          ? null
          : lastKnownAddress ?? this.lastKnownAddress,
      lastSeenAt: clearLastSeenAt ? null : lastSeenAt ?? this.lastSeenAt,
      trustLevel: trustLevel ?? this.trustLevel,
      isLanDiscovered: isLanDiscovered ?? this.isLanDiscovered,
      note: clearNote ? null : note ?? this.note,
    );
  }
}
