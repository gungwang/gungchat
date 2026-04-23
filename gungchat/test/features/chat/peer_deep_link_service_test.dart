import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/features/chat/peer_deep_link_service.dart';

void main() {
  group('PeerDeepLinkService', () {
    const service = PeerDeepLinkService();

    test('round-trips invite text through gungchat deep links', () {
      const rawInput = '''
GungChat connection invite
Contact: Alice
Expected fingerprint: aa:bb:cc:dd

OFFER:
offer-payload
''';

      final uri = service.buildInputUri(rawInput);
      final resolved = service.resolve(uri);

      expect(uri.scheme, 'gungchat');
      expect(uri.host, 'handoff');
      expect(resolved, isNotNull);
      expect(resolved!.rawInput, rawInput.trim());
    });

    test('ignores non-gungchat schemes', () {
      final resolved = service.resolve(Uri.parse('https://example.com'));
      expect(resolved, isNull);
    });
  });
}