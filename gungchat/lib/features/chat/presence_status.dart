enum PeerPresenceStatus {
  online,
  away,
  hidden,
}

extension PeerPresenceStatusLabel on PeerPresenceStatus {
  String get label {
    switch (this) {
      case PeerPresenceStatus.online:
        return 'Online';
      case PeerPresenceStatus.away:
        return 'Away';
      case PeerPresenceStatus.hidden:
        return 'Hidden';
    }
  }
}