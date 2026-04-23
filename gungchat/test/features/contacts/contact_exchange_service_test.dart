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
}
