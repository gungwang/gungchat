import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chat/presence_status.dart';

class PresencePreferencesStorage {
  static const _presenceStatusKey = 'settings.presenceStatus';

  const PresencePreferencesStorage();

  Future<PeerPresenceStatus> loadPresenceStatus() async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(_presenceStatusKey);
    if (rawValue == null || rawValue.isEmpty) {
      return PeerPresenceStatus.online;
    }

    try {
      return PeerPresenceStatus.values.byName(rawValue);
    } catch (_) {
      return PeerPresenceStatus.online;
    }
  }

  Future<void> savePresenceStatus(PeerPresenceStatus value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_presenceStatusKey, value.name);
  }
}

class PresencePreferenceController extends StateNotifier<PeerPresenceStatus> {
  PresencePreferenceController({required PresencePreferencesStorage storage})
      : _storage = storage,
        super(PeerPresenceStatus.online) {
    unawaited(_load());
  }

  final PresencePreferencesStorage _storage;

  Future<void> setStatus(PeerPresenceStatus value) async {
    final previousValue = state;
    state = value;

    try {
      await _storage.savePresenceStatus(value);
    } catch (_) {
      state = previousValue;
      rethrow;
    }
  }

  Future<void> _load() async {
    state = await _storage.loadPresenceStatus();
  }
}