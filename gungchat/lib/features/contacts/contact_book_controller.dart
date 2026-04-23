import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/contact.dart';

class ContactBookController extends StateNotifier<List<Contact>> {
  ContactBookController() : super(const []);

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
  }
}
