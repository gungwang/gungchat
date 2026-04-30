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

  String defaultDisplayName(DeviceIdentity identity) {
    final fingerprintHint = identity.fingerprint
        .split(':')
        .where((segment) => segment.isNotEmpty)
        .take(2)
        .join()
        .toUpperCase();
    if (fingerprintHint.isEmpty) {
      return 'GungChat';
    }

    return 'GungChat $fingerprintHint';
  }

  String resolveDisplayName({
    required DeviceIdentity identity,
    String? preferredDisplayName,
  }) {
    final trimmed = preferredDisplayName?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return trimmed;
    }

    return defaultDisplayName(identity);
  }

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
      ..sort((left, right) {
        final priorityCompare =
            _addressPriority(right).compareTo(_addressPriority(left));
        if (priorityCompare != 0) {
          return priorityCompare;
        }

        return left.compareTo(right);
      });

    return ContactCard(
      displayName: resolveDisplayName(
        identity: identity,
        preferredDisplayName: displayName,
      ),
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
    final preferredAddress = selectPreferredAddress(card.addresses);
    return Contact(
      id: card.fingerprint,
      displayName: card.displayName,
      fingerprint: card.fingerprint,
      lastKnownAddress:
          preferredAddress == null ? null : '$preferredAddress:${card.port}',
      lastSeenAt: card.createdAt ?? DateTime.now(),
      trustLevel: ContactTrustLevel.unknown,
    );
  }

  String buildQrReadyPayload(ContactCard card) {
    return encodeContactCard(card);
  }

  String? selectPreferredAddress(Iterable<String> addresses) {
    final ranked = addresses
        .map((address) => address.trim())
        .where((address) => address.isNotEmpty)
        .toList(growable: false);
    if (ranked.isEmpty) {
      return null;
    }

    final sorted = List<String>.from(ranked)
      ..sort((left, right) {
        final priorityCompare =
            _addressPriority(right).compareTo(_addressPriority(left));
        if (priorityCompare != 0) {
          return priorityCompare;
        }

        return left.compareTo(right);
      });
    return sorted.first;
  }

  bool _isUsableAddress(InternetAddress address) {
    final value = address.address;
    return value != InternetAddress.anyIPv4.address &&
        value != InternetAddress.loopbackIPv4.address &&
        !value.startsWith('169.254.');
  }

  int _addressPriority(String address) {
    final octets = address.split('.');
    if (octets.length != 4) {
      return 0;
    }

    final first = int.tryParse(octets[0]);
    final second = int.tryParse(octets[1]);
    if (first == null || second == null) {
      return 0;
    }

    if (first == 192 && second == 168) {
      return 300;
    }
    if (first == 10) {
      return 250;
    }
    if (first == 172 && second >= 16 && second <= 31) {
      return 200;
    }
    if (first == 169 && second == 254) {
      return -100;
    }

    return 100;
  }
}
