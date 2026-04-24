import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/features/chat/custom_status_service.dart';

void main() {
  const service = CustomStatusService();

  test('normalizes and truncates custom status text', () {
    final value = service.normalize(
      '   Working    remotely   while handling a very long custom status that should be clipped before it exceeds the allowed transport length for peers.   ',
    );

    expect(value.length, lessThanOrEqualTo(CustomStatusService.maxLength));
    expect(value, startsWith('Working remotely while handling'));
  });

  test('returns null for empty custom status text', () {
    expect(service.normalizeNullable('   '), isNull);
  });
}