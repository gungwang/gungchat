import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BurnAfterReadDelayPreferencesStorage {
  static const _burnAfterReadDelaySecondsKey =
      'settings.burnAfterReadDelaySeconds';
  static const Duration defaultDelay = Duration(seconds: 30);
  static const List<Duration> supportedDelays = <Duration>[
    Duration.zero,
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 10),
  ];

  const BurnAfterReadDelayPreferencesStorage();

  Future<Duration> loadDelay() async {
    final preferences = await SharedPreferences.getInstance();
    final rawSeconds = preferences.getInt(_burnAfterReadDelaySecondsKey);
    final loadedDelay = rawSeconds == null
        ? defaultDelay
        : Duration(seconds: rawSeconds);
    if (!supportedDelays.contains(loadedDelay)) {
      return defaultDelay;
    }
    return loadedDelay;
  }

  Future<void> saveDelay(Duration value) async {
    if (!supportedDelays.contains(value)) {
      throw ArgumentError.value(value, 'value', 'Unsupported delay option.');
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_burnAfterReadDelaySecondsKey, value.inSeconds);
  }
}

class BurnAfterReadDelayPreferenceController extends StateNotifier<Duration> {
  BurnAfterReadDelayPreferenceController({
    required BurnAfterReadDelayPreferencesStorage storage,
  })  : _storage = storage,
        super(BurnAfterReadDelayPreferencesStorage.defaultDelay) {
    unawaited(_load());
  }

  final BurnAfterReadDelayPreferencesStorage _storage;

  Future<void> setDelay(Duration value) async {
    final previousValue = state;
    state = value;

    try {
      await _storage.saveDelay(value);
    } catch (_) {
      state = previousValue;
      rethrow;
    }
  }

  Future<void> _load() async {
    state = await _storage.loadDelay();
  }
}