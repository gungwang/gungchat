import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/encryption/key_manager.dart';
import '../../models/contact.dart';
import 'discovery_service.dart';

@immutable
class ContactCard {
  const ContactCard({
    required this.displayName,
    required this.fingerprint,
    required this.addresses,
    required this.port,
    this.createdAt,
  });

  final String displayName;
  final String fingerprint;
  final List<String> addresses;
  final int port;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'displayName': displayName,
      'fingerprint': fingerprint,
      'addresses': addresses,
      'port': port,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory ContactCard.fromJson(Map<String, dynamic> json) {
    return ContactCard(
      displayName: json['displayName'] as String,
      fingerprint: json['fingerprint'] as String,
      addresses: List<String>.from(json['addresses'] as List<dynamic>),
      port: json['port'] as int,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ContactExchangeService {
  const ContactExchangeService();

  Future<ContactCard> buildLocalContactCard({
    required DeviceIdentity identity,
    required String displayName,
    int port = DiscoveryService.discoveryPort,
  }) async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );

    final addresses = <String>{
      for (final interface in interfaces)
        for (final address in interface.addresses)
          if (_isUsableAddress(address)) address.address,
    }.toList()
      ..sort();

    return ContactCard(
      displayName: displayName.trim().isEmpty ? 'GungChat' : displayName.trim(),
      fingerprint: identity.fingerprint,
      addresses: addresses,
      port: port,
      createdAt: DateTime.now(),
    );
  }

  String encodeContactCard(ContactCard card) {
    final payload = base64UrlEncode(utf8.encode(jsonEncode(card.toJson())));
    return 'gungchat-contact:$payload';
  }

  ContactCard decodeContactCard(String rawValue) {
    final trimmed = rawValue.trim();
    if (!trimmed.startsWith('gungchat-contact:')) {
      throw const FormatException(
        'Contact payload must start with gungchat-contact:',
      );
    }

    final encoded = trimmed.substring('gungchat-contact:'.length);
    final decoded = utf8.decode(base64Url.decode(base64Url.normalize(encoded)));
    return ContactCard.fromJson(jsonDecode(decoded) as Map<String, dynamic>);
  }

  Contact contactFromCard(ContactCard card) {
    return Contact(
      id: card.fingerprint,
      displayName: card.displayName,
      fingerprint: card.fingerprint,
      lastKnownAddress: card.addresses.isEmpty
          ? null
          : '${card.addresses.first}:${card.port}',
      lastSeenAt: card.createdAt ?? DateTime.now(),
      trustLevel: ContactTrustLevel.unknown,
    );
  }

  String buildQrReadyPayload(ContactCard card) {
    return encodeContactCard(card);
  }

  bool _isUsableAddress(InternetAddress address) {
    final value = address.address;
    return value != InternetAddress.anyIPv4.address &&
        value != InternetAddress.loopbackIPv4.address &&
        !value.startsWith('169.254.');
  }
}
