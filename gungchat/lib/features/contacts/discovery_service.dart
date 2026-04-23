import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/encryption/key_manager.dart';
import 'contact_exchange_service.dart';

@immutable
class DiscoveryCandidate {
  const DiscoveryCandidate({
    required this.displayName,
    required this.host,
    required this.port,
    this.fingerprint,
    this.contactPayload,
  });

  final String displayName;
  final String host;
  final int port;
  final String? fingerprint;
  final String? contactPayload;
}

class DiscoveryService {
  const DiscoveryService({ContactExchangeService? contactExchangeService})
      : _contactExchangeService =
            contactExchangeService ?? const ContactExchangeService();

  static const int discoveryPort = 45454;
  static const String discoveryMessageType = 'discover';
  static const String announcementMessageType = 'announce';

  final ContactExchangeService _contactExchangeService;

  Future<List<DiscoveryCandidate>> discoverLanPeers({
    required DeviceIdentity identity,
    required String displayName,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final localCard = await _contactExchangeService.buildLocalContactCard(
      identity: identity,
      displayName: displayName,
      port: discoveryPort,
    );

    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      discoveryPort,
      reuseAddress: true,
      reusePort: true,
    );
    socket.broadcastEnabled = true;

    final candidates = <String, DiscoveryCandidate>{};
    final completer = Completer<void>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    late final StreamSubscription<RawSocketEvent> subscription;
    subscription = socket.listen((event) {
      if (event != RawSocketEvent.read) {
        return;
      }

      Datagram? datagram;
      while ((datagram = socket.receive()) != null) {
        final currentDatagram = datagram!;
        final packet = _decodePacket(currentDatagram.data);
        if (packet == null || packet.fingerprint == identity.fingerprint) {
          continue;
        }

        if (packet.type == discoveryMessageType) {
          final response = _encodePacket(
            type: announcementMessageType,
            card: localCard,
          );
          socket.send(
            response,
            currentDatagram.address,
            currentDatagram.port,
          );
          continue;
        }

        if (packet.type != announcementMessageType) {
          continue;
        }

        final candidate = DiscoveryCandidate(
          displayName: packet.displayName,
          host: currentDatagram.address.address,
          port: packet.port,
          fingerprint: packet.fingerprint,
          contactPayload: packet.contactPayload,
        );
        candidates[_candidateKey(candidate)] = candidate;
      }
    });

    try {
      final discoverPacket = _encodePacket(
        type: discoveryMessageType,
        card: localCard,
      );
      final announcePacket = _encodePacket(
        type: announcementMessageType,
        card: localCard,
      );

      socket.send(
        discoverPacket,
        InternetAddress('255.255.255.255'),
        discoveryPort,
      );
      socket.send(
        announcePacket,
        InternetAddress('255.255.255.255'),
        discoveryPort,
      );

      await completer.future;
    } finally {
      timer.cancel();
      await subscription.cancel();
      socket.close();
    }

    final result = candidates.values.toList()
      ..sort(
        (left, right) => left.displayName.toLowerCase().compareTo(
              right.displayName.toLowerCase(),
            ),
      );
    return result;
  }

  Uri buildManualConnectionUri({
    required String host,
    required int port,
    String? fingerprint,
  }) {
    return Uri(
      scheme: 'gungchat',
      host: host,
      port: port,
      queryParameters: {
        if (fingerprint != null) 'fingerprint': fingerprint,
      },
    );
  }

  List<int> _encodePacket({
    required String type,
    required ContactCard card,
  }) {
    return utf8.encode(
      jsonEncode(
        <String, dynamic>{
          'version': 1,
          'type': type,
          'displayName': card.displayName,
          'fingerprint': card.fingerprint,
          'port': card.port,
          'contactPayload': _contactExchangeService.encodeContactCard(card),
        },
      ),
    );
  }

  _DiscoveryPacket? _decodePacket(List<int> bytes) {
    try {
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (json['version'] != 1) {
        return null;
      }

      return _DiscoveryPacket(
        type: json['type'] as String,
        displayName: json['displayName'] as String,
        fingerprint: json['fingerprint'] as String,
        port: json['port'] as int,
        contactPayload: json['contactPayload'] as String?,
      );
    } on FormatException {
      return null;
    }
  }

  String _candidateKey(DiscoveryCandidate candidate) {
    return '${candidate.fingerprint ?? candidate.displayName}@${candidate.host}:${candidate.port}';
  }
}

@immutable
class _DiscoveryPacket {
  const _DiscoveryPacket({
    required this.type,
    required this.displayName,
    required this.fingerprint,
    required this.port,
    this.contactPayload,
  });

  final String type;
  final String displayName;
  final String fingerprint;
  final int port;
  final String? contactPayload;
}
