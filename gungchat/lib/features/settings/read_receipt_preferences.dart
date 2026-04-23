import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadReceiptPreferencesStorage {
  static const _readReceiptsEnabledKey = 'settings.readReceiptsEnabled';

  const ReadReceiptPreferencesStorage();

  Future<bool> loadReadReceiptsEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_readReceiptsEnabledKey) ?? false;
  }

  Future<void> saveReadReceiptsEnabled(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_readReceiptsEnabledKey, value);
  }
}

class ReadReceiptsPreferenceController extends StateNotifier<bool> {
  ReadReceiptsPreferenceController({
    required ReadReceiptPreferencesStorage storage,
  })  : _storage = storage,
        super(false) {
    unawaited(_load());
  }

  final ReadReceiptPreferencesStorage _storage;

  Future<void> setEnabled(bool value) async {
    final previousValue = state;
    state = value;

    try {
      await _storage.saveReadReceiptsEnabled(value);
    } catch (_) {
      state = previousValue;
      rethrow;
    }
  }

  Future<void> _load() async {
    state = await _storage.loadReadReceiptsEnabled();
  }
}