import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/secure_storage.dart';

abstract class ContactBlockStore {
  Future<Set<String>> loadBlockedFingerprints();
  Future<void> saveBlockedFingerprints(Set<String> fingerprints);
}

class ContactBlockStorage implements ContactBlockStore {
  ContactBlockStorage(this._secureStorage);

  static const _blockedContactsKey = 'contacts.blocked';

  final AppSecureStorage _secureStorage;

  @override
  Future<Set<String>> loadBlockedFingerprints() async {
    final rawValue = await _secureStorage.read(_blockedContactsKey);
    if (rawValue == null || rawValue.isEmpty) {
      return <String>{};
    }

    try {
      final decoded = jsonDecode(rawValue) as List<dynamic>;
      return decoded
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  @override
  Future<void> saveBlockedFingerprints(Set<String> fingerprints) async {
    final next = fingerprints.toList(growable: false)..sort();
    await _secureStorage.write(_blockedContactsKey, jsonEncode(next));
  }
}

class ContactBlockController extends StateNotifier<Set<String>> {
  ContactBlockController({required ContactBlockStore storage})
      : _storage = storage,
        super(const <String>{}) {
    unawaited(_load());
  }

  final ContactBlockStore _storage;
  int _version = 0;

  Future<void> blockContact(String fingerprint) async {
    await _update({...state, fingerprint});
  }

  Future<void> unblockContact(String fingerprint) async {
    final next = {...state}..remove(fingerprint);
    await _update(next);
  }

  bool isBlocked(String fingerprint) => state.contains(fingerprint);

  Future<void> _update(Set<String> nextValue) async {
    final previousValue = state;
    final version = ++_version;
    state = Set<String>.unmodifiable(nextValue);

    try {
      await _storage.saveBlockedFingerprints(nextValue);
    } catch (_) {
      if (_version == version) {
        state = previousValue;
      }
      rethrow;
    }
  }

  Future<void> _load() async {
    final version = _version;
    final loadedValue = await _storage.loadBlockedFingerprints();
    if (_version != version) {
      return;
    }
    state = Set<String>.unmodifiable(loadedValue);
  }
}