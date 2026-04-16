import 'package:flutter/foundation.dart';

@immutable
class DiscoveryCandidate {
  const DiscoveryCandidate({
    required this.displayName,
    required this.host,
    required this.port,
    this.fingerprint,
  });

  final String displayName;
  final String host;
  final int port;
  final String? fingerprint;
}

class DiscoveryService {
  const DiscoveryService();

  Future<List<DiscoveryCandidate>> discoverLanPeers({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    await Future<void>.delayed(timeout);
    return const [];
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
}
