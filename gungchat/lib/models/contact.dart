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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'displayName': displayName,
      'fingerprint': fingerprint,
      'lastKnownAddress': lastKnownAddress,
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'trustLevel': trustLevel.name,
      'isLanDiscovered': isLanDiscovered,
      'note': note,
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      fingerprint: json['fingerprint'] as String,
      lastKnownAddress: json['lastKnownAddress'] as String?,
      lastSeenAt: json['lastSeenAt'] == null
          ? null
          : DateTime.parse(json['lastSeenAt'] as String),
      trustLevel: ContactTrustLevel.values.byName(
        json['trustLevel'] as String? ?? ContactTrustLevel.unknown.name,
      ),
      isLanDiscovered: json['isLanDiscovered'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }

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
