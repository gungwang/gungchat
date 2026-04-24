import 'package:flutter_test/flutter_test.dart';
import 'package:gungchat/core/text/spoiler_renderer.dart';

void main() {
  test('SpoilerRenderer parses spoiler and visible segments', () {
    final segments = SpoilerRenderer.parse('alpha ||secret|| omega');

    expect(segments, hasLength(3));
    expect(segments[0].text, 'alpha ');
    expect(segments[0].isSpoiler, isFalse);
    expect(segments[1].text, 'secret');
    expect(segments[1].isSpoiler, isTrue);
    expect(segments[2].text, ' omega');
    expect(segments[2].isSpoiler, isFalse);
  });

  test('SpoilerRenderer preview and visible text redact spoilers differently', () {
    const input = 'alpha ||secret|| https://example.com';

    expect(SpoilerRenderer.visibleText(input), 'alpha  https://example.com');
    expect(SpoilerRenderer.previewText(input), 'alpha Spoiler https://example.com');
  });
}