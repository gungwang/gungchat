import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/contact.dart';
import 'contact_book_storage.dart';

class ContactBookController extends StateNotifier<List<Contact>> {
  ContactBookController({required ContactBookStorage storage})
      : _storage = storage,
        super(const []) {
    unawaited(_hydrate());
  }

  final ContactBookStorage _storage;

  Future<void> _hydrate() async {
    final contacts = await _storage.loadContacts();
    if (contacts.isEmpty) {
      return;
    }

    final next = [...contacts]..sort(
        (left, right) => left.displayName.toLowerCase().compareTo(
              right.displayName.toLowerCase(),
            ),
      );
    state = List<Contact>.unmodifiable(next);
  }

  void addOrUpdate(Contact contact) {
    final next = [...state];
    final index = next.indexWhere(
      (existing) => existing.fingerprint == contact.fingerprint,
    );

    if (index == -1) {
      next.add(contact);
    } else {
      next[index] = next[index].copyWith(
        displayName: contact.displayName,
        lastKnownAddress: contact.lastKnownAddress,
        lastSeenAt: contact.lastSeenAt,
        isLanDiscovered: contact.isLanDiscovered,
      );
    }

    next.sort(
      (left, right) => left.displayName.toLowerCase().compareTo(
            right.displayName.toLowerCase(),
          ),
    );
    state = List<Contact>.unmodifiable(next);
    unawaited(_storage.saveContacts(state));
  }
}
