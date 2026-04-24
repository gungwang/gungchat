import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/core/networking/data_channel_text_framer.dart';

void main() {
  test('frames and reassembles long transport messages', () {
    final framer = DataChannelTextFramer(
      maxFramePayloadLength: 8,
      nextMessageId: () => 'chunk-1',
    );
    const message = 'abcdefghijklmnopqrstuvwxyz';

    final frames = framer.frame(message).toList(growable: false);

    expect(frames.length, greaterThan(1));

    String? reassembled;
    for (final frame in frames) {
      reassembled = framer.consumeFrame(frame) ?? reassembled;
    }

    expect(reassembled, message);
  });

  test('passes through short transport messages unchanged', () {
    final framer = DataChannelTextFramer(maxFramePayloadLength: 64);

    const message = '{"kind":"message"}';

    expect(framer.frame(message), <String>[message]);
    expect(framer.consumeFrame(message), message);
  });
}