import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  light,
  dark,
  auto;

  ThemeMode get flutterThemeMode {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.auto:
        return ThemeMode.system;
    }
  }
}

class ThemePreferencesStorage {
  static const _themeModeKey = 'settings.themeMode';

  const ThemePreferencesStorage();

  Future<AppThemeMode> loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(_themeModeKey);
    if (rawValue == null || rawValue.isEmpty) {
      return AppThemeMode.auto;
    }

    return AppThemeMode.values.byName(rawValue);
  }

  Future<void> saveThemeMode(AppThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, mode.name);
  }
}

class ThemePreferencesController extends StateNotifier<AppThemeMode> {
  ThemePreferencesController({required ThemePreferencesStorage storage})
      : _storage = storage,
        super(AppThemeMode.auto) {
    unawaited(_load());
  }

  final ThemePreferencesStorage _storage;
  int _version = 0;

  Future<void> setTheme(AppThemeMode mode) async {
    await _update(mode);
  }

  Future<void> cycleTheme() async {
    final nextMode = AppThemeMode.values[(state.index + 1) % AppThemeMode.values.length];
    await _update(nextMode);
  }

  Future<void> _update(AppThemeMode nextMode) async {
    final previousMode = state;
    final version = ++_version;
    state = nextMode;

    try {
      await _storage.saveThemeMode(nextMode);
    } catch (_) {
      if (_version == version) {
        state = previousMode;
      }
      rethrow;
    }
  }

  Future<void> _load() async {
    final version = _version;
    final loadedMode = await _storage.loadThemeMode();
    if (_version != version) {
      return;
    }
    state = loadedMode;
  }
}