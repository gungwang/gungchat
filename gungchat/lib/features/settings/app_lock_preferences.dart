import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class AppLockSettings {
  const AppLockSettings({
    this.enabled = false,
    this.timeoutSeconds = 60,
  });

  final bool enabled;
  final int timeoutSeconds;

  AppLockSettings copyWith({
    bool? enabled,
    int? timeoutSeconds,
  }) {
    return AppLockSettings(
      enabled: enabled ?? this.enabled,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    );
  }
}

class AppLockPreferencesStorage {
  static const _enabledKey = 'settings.appLockEnabled';
  static const _timeoutKey = 'settings.appLockTimeoutSeconds';

  const AppLockPreferencesStorage();

  Future<AppLockSettings> loadSettings() async {
    final preferences = await SharedPreferences.getInstance();
    return AppLockSettings(
      enabled: preferences.getBool(_enabledKey) ?? false,
      timeoutSeconds: preferences.getInt(_timeoutKey) ?? 60,
    );
  }

  Future<void> saveSettings(AppLockSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, settings.enabled);
    await preferences.setInt(_timeoutKey, settings.timeoutSeconds);
  }
}

class AppLockSettingsController extends StateNotifier<AppLockSettings> {
  AppLockSettingsController({required AppLockPreferencesStorage storage})
      : _storage = storage,
        super(const AppLockSettings()) {
    unawaited(_load());
  }

  final AppLockPreferencesStorage _storage;
  int _version = 0;

  Future<void> setEnabled(bool value) async {
    await _update(state.copyWith(enabled: value));
  }

  Future<void> setTimeoutSeconds(int value) async {
    await _update(state.copyWith(timeoutSeconds: value));
  }

  Future<void> _update(AppLockSettings nextValue) async {
    final previousValue = state;
    final version = ++_version;
    state = nextValue;

    try {
      await _storage.saveSettings(nextValue);
    } catch (_) {
      if (_version == version) {
        state = previousValue;
      }
      rethrow;
    }
  }

  Future<void> _load() async {
    final version = _version;
    final loadedValue = await _storage.loadSettings();
    if (_version != version) {
      return;
    }
    state = loadedValue;
  }
}