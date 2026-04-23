import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/features/contacts/contact_book_storage.dart';
import 'package:gungchat/models/contact.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('saves and restores contacts across storage reads', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    const storage = ContactBookStorage();
    final contacts = <Contact>[
      Contact(
        id: 'alice',
        displayName: 'Alice',
        fingerprint: 'aa:bb:cc:dd',
        lastKnownAddress: '192.168.1.10:45454',
        lastSeenAt: DateTime(2026, 4, 23, 12, 0),
        trustLevel: ContactTrustLevel.verified,
        isLanDiscovered: true,
        note: 'LAN peer',
      ),
    ];

    await storage.saveContacts(contacts);
    final restored = await storage.loadContacts();

    expect(restored, hasLength(1));
    expect(restored.first.displayName, 'Alice');
    expect(restored.first.fingerprint, 'aa:bb:cc:dd');
    expect(restored.first.lastKnownAddress, '192.168.1.10:45454');
    expect(restored.first.lastSeenAt, DateTime(2026, 4, 23, 12, 0));
    expect(restored.first.trustLevel, ContactTrustLevel.verified);
    expect(restored.first.isLanDiscovered, isTrue);
    expect(restored.first.note, 'LAN peer');
  });
}
