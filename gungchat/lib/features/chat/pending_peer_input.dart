import 'package:flutter/foundation.dart';

enum PeerInputSource {
  deepLink,
  clipboard,
}

@immutable
class PendingPeerInput {
  const PendingPeerInput({
    required this.rawValue,
    required this.source,
    required this.receivedAt,
  });

  final String rawValue;
  final PeerInputSource source;
  final DateTime receivedAt;

  String get sourceLabel {
    switch (source) {
      case PeerInputSource.deepLink:
        return 'deep link';
      case PeerInputSource.clipboard:
        return 'clipboard';
    }
  }
}