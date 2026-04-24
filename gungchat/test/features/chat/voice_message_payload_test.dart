import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/features/chat/voice_message_payload.dart';

void main() {
  test('round-trips voice payload transport encoding', () {
    final payload = VoiceMessagePayload(
      bytes: Uint8List.fromList(const <int>[1, 2, 3, 4]),
      durationMs: 4200,
      mimeType: 'audio/ogg',
    );

    final decoded = VoiceMessagePayload.tryDecodeTransportString(
      payload.encodeTransportString(),
    );

    expect(decoded, isNotNull);
    expect(decoded!.durationMs, 4200);
    expect(decoded.mimeType, 'audio/ogg');
    expect(decoded.bytes, Uint8List.fromList(const <int>[1, 2, 3, 4]));
  });

  test('ignores non-voice payload strings', () {
    expect(
      VoiceMessagePayload.tryDecodeTransportString('plain secure message'),
      isNull,
    );
  });
}