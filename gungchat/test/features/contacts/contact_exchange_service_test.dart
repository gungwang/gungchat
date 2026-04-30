import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/features/contacts/contact_exchange_service.dart';

void main() {
  test('encodes and decodes a contact card payload', () {
    const service = ContactExchangeService();
    final card = ContactCard(
      displayName: 'Alice',
      fingerprint: 'aa:bb:cc:dd',
      addresses: const ['192.168.1.22'],
      port: 45454,
      createdAt: DateTime(2026, 4, 23, 10, 0),
    );

    final payload = service.encodeContactCard(card);
    final decoded = service.decodeContactCard(payload);

    expect(decoded.displayName, 'Alice');
    expect(decoded.fingerprint, 'aa:bb:cc:dd');
    expect(decoded.addresses, const ['192.168.1.22']);
    expect(decoded.port, 45454);
    expect(decoded.createdAt, DateTime(2026, 4, 23, 10, 0));
  });

  test('prefers the most LAN-friendly address when importing a contact', () {
    const service = ContactExchangeService();
    final contact = service.contactFromCard(
      const ContactCard(
        displayName: 'Alice',
        fingerprint: 'aa:bb:cc:dd',
        addresses: <String>['172.22.112.1', '10.0.0.5', '192.168.1.22'],
        port: 45454,
      ),
    );

    expect(contact.lastKnownAddress, '192.168.1.22:45454');
  });
}
