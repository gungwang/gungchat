import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chat/custom_status_service.dart';

class CustomStatusPreferencesStorage {
  static const _customStatusTextKey = 'settings.customStatusText';

  const CustomStatusPreferencesStorage();

  Future<String> loadCustomStatusText() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_customStatusTextKey) ?? '';
  }

  Future<void> saveCustomStatusText(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_customStatusTextKey, value);
  }
}

class CustomStatusPreferenceController extends StateNotifier<String> {
  CustomStatusPreferenceController({
    required CustomStatusPreferencesStorage storage,
    required CustomStatusService statusService,
  })  : _storage = storage,
        _statusService = statusService,
        super('') {
    unawaited(_load());
  }

  final CustomStatusPreferencesStorage _storage;
  final CustomStatusService _statusService;
  int _version = 0;

  Future<void> setText(String value) async {
    final normalized = _statusService.normalize(value);
    await _update(normalized);
  }

  Future<void> _update(String nextValue) async {
    final previousValue = state;
    final version = ++_version;
    state = nextValue;

    try {
      await _storage.saveCustomStatusText(nextValue);
    } catch (_) {
      if (_version == version) {
        state = previousValue;
      }
      rethrow;
    }
  }

  Future<void> _load() async {
    final version = _version;
    final loadedValue = _statusService.normalize(
      await _storage.loadCustomStatusText(),
    );
    if (_version != version) {
      return;
    }
    state = loadedValue;
  }
}