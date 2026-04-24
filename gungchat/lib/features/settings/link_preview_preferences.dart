import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LinkPreviewPreferencesStorage {
  static const _linkPreviewsEnabledKey = 'settings.linkPreviewsEnabled';

  const LinkPreviewPreferencesStorage();

  Future<bool> loadLinkPreviewsEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_linkPreviewsEnabledKey) ?? false;
  }

  Future<void> saveLinkPreviewsEnabled(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_linkPreviewsEnabledKey, value);
  }
}

class LinkPreviewPreferenceController extends StateNotifier<bool> {
  LinkPreviewPreferenceController({
    required LinkPreviewPreferencesStorage storage,
  })  : _storage = storage,
        super(false) {
    unawaited(_load());
  }

  final LinkPreviewPreferencesStorage _storage;

  Future<void> setEnabled(bool value) async {
    final previousValue = state;
    state = value;

    try {
      await _storage.saveLinkPreviewsEnabled(value);
    } catch (_) {
      state = previousValue;
      rethrow;
    }
  }

  Future<void> _load() async {
    state = await _storage.loadLinkPreviewsEnabled();
  }
}