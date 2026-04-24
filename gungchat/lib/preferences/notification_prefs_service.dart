import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationPreferenceKey {
  messages,
  calls,
  presence,
  connectionRequests,
  reactions,
  sound,
  vibrate,
}

extension NotificationPreferenceKeyX on NotificationPreferenceKey {
  String get storageKey {
    return switch (this) {
      NotificationPreferenceKey.messages => 'notify_messages',
      NotificationPreferenceKey.calls => 'notify_calls',
      NotificationPreferenceKey.presence => 'notify_presence',
      NotificationPreferenceKey.connectionRequests => 'notify_connection_requests',
      NotificationPreferenceKey.reactions => 'notify_reactions',
      NotificationPreferenceKey.sound => 'notify_sound',
      NotificationPreferenceKey.vibrate => 'notify_vibrate',
    };
  }

  String get label {
    return switch (this) {
      NotificationPreferenceKey.messages => 'Messages',
      NotificationPreferenceKey.calls => 'Calls',
      NotificationPreferenceKey.presence => 'Presence changes',
      NotificationPreferenceKey.connectionRequests => 'Connection requests',
      NotificationPreferenceKey.reactions => 'Reactions',
      NotificationPreferenceKey.sound => 'Sound',
      NotificationPreferenceKey.vibrate => 'Vibrate',
    };
  }
}

class NotificationPreferencesStorage {
  const NotificationPreferencesStorage();

  static const Map<NotificationPreferenceKey, bool> defaults = {
    NotificationPreferenceKey.messages: true,
    NotificationPreferenceKey.calls: true,
    NotificationPreferenceKey.presence: false,
    NotificationPreferenceKey.connectionRequests: true,
    NotificationPreferenceKey.reactions: false,
    NotificationPreferenceKey.sound: true,
    NotificationPreferenceKey.vibrate: true,
  };

  Future<Map<NotificationPreferenceKey, bool>> loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    return Map<NotificationPreferenceKey, bool>.fromEntries(
      defaults.entries.map(
        (entry) => MapEntry(
          entry.key,
          preferences.getBool(entry.key.storageKey) ?? entry.value,
        ),
      ),
    );
  }

  Future<void> savePreference(
    NotificationPreferenceKey key,
    bool value,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key.storageKey, value);
  }
}

class NotificationPreferencesController
    extends StateNotifier<Map<NotificationPreferenceKey, bool>> {
  NotificationPreferencesController({required NotificationPreferencesStorage storage})
      : _storage = storage,
        super(NotificationPreferencesStorage.defaults) {
    unawaited(_load());
  }

  final NotificationPreferencesStorage _storage;
  int _version = 0;

  Future<void> setPreference(
    NotificationPreferenceKey key,
    bool value,
  ) async {
    final previousState = state;
    final version = ++_version;
    state = Map<NotificationPreferenceKey, bool>.unmodifiable({
      ...state,
      key: value,
    });

    try {
      await _storage.savePreference(key, value);
    } catch (_) {
      if (_version == version) {
        state = previousState;
      }
      rethrow;
    }
  }

  Future<void> _load() async {
    final version = _version;
    final loadedState = await _storage.loadPreferences();
    if (_version != version) {
      return;
    }
    state = Map<NotificationPreferenceKey, bool>.unmodifiable(loadedState);
  }
}