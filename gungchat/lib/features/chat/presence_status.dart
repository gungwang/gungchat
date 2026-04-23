import 'package:flutter/widgets.dart';

enum PeerPresenceStatus {
  online,
  away,
  hidden,
}

PeerPresenceStatus resolveEffectivePresenceStatus({
  required PeerPresenceStatus preferredStatus,
  required AppLifecycleState lifecycleState,
}) {
  if (preferredStatus != PeerPresenceStatus.online) {
    return preferredStatus;
  }

  switch (lifecycleState) {
    case AppLifecycleState.resumed:
      return PeerPresenceStatus.online;
    case AppLifecycleState.inactive:
    case AppLifecycleState.hidden:
    case AppLifecycleState.paused:
    case AppLifecycleState.detached:
      return PeerPresenceStatus.away;
  }
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