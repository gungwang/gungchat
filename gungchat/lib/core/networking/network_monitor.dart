import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

@immutable
class NetworkSnapshot {
  const NetworkSnapshot({required this.results});

  final List<ConnectivityResult> results;

  bool get isOnline => results.any((result) => result != ConnectivityResult.none);

  bool get prefersLan => results.any(
        (result) =>
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );

  String get summary {
    if (!isOnline) {
      return 'Offline';
    }
    if (prefersLan) {
      return 'LAN preferred';
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return 'Mobile data';
    }
    return 'Connected';
  }
}

class NetworkMonitor {
  NetworkMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<NetworkSnapshot> current() async {
    final results = await _connectivity.checkConnectivity();
    return _toSnapshot(results);
  }

  Stream<NetworkSnapshot> watch() {
    return _connectivity.onConnectivityChanged
        .map(_toSnapshot)
        .distinct((previous, next) => listEquals(previous.results, next.results));
  }

  NetworkSnapshot _toSnapshot(List<ConnectivityResult> results) {
    final uniqueResults = results.toSet().toList(growable: false);
    return NetworkSnapshot(results: uniqueResults);
  }
}
