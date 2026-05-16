import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocaleMode {
  system,
  english,
  chineseSimplified,
  chineseTraditional,
  spanish,
  french;

  Locale? get locale {
    return switch (this) {
      AppLocaleMode.system => null,
      AppLocaleMode.english => const Locale('en'),
      AppLocaleMode.chineseSimplified => const Locale('zh'),
      AppLocaleMode.chineseTraditional => const Locale('zh', 'TW'),
      AppLocaleMode.spanish => const Locale('es'),
      AppLocaleMode.french => const Locale('fr'),
    };
  }
}

class LocalePreferencesStorage {
  static const _localeModeKey = 'settings.localeMode';

  const LocalePreferencesStorage();

  Future<AppLocaleMode> loadLocaleMode() async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(_localeModeKey);
    if (rawValue == null || rawValue.isEmpty) {
      return AppLocaleMode.system;
    }

    try {
      return AppLocaleMode.values.byName(rawValue);
    } catch (_) {
      return AppLocaleMode.system;
    }
  }

  Future<void> saveLocaleMode(AppLocaleMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localeModeKey, mode.name);
  }
}

class LocalePreferencesController extends StateNotifier<AppLocaleMode> {
  LocalePreferencesController({required LocalePreferencesStorage storage})
      : _storage = storage,
        super(AppLocaleMode.system) {
    unawaited(_load());
  }

  final LocalePreferencesStorage _storage;
  int _version = 0;

  Future<void> setLocale(AppLocaleMode mode) async {
    await _update(mode);
  }

  Future<void> _update(AppLocaleMode nextMode) async {
    final previousMode = state;
    final version = ++_version;
    state = nextMode;

    try {
      await _storage.saveLocaleMode(nextMode);
    } catch (_) {
      if (_version == version) {
        state = previousMode;
      }
      rethrow;
    }
  }

  Future<void> _load() async {
    final version = _version;
    final loadedMode = await _storage.loadLocaleMode();
    if (_version != version) {
      return;
    }
    state = loadedMode;
  }
}