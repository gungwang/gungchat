import 'package:flutter/foundation.dart';

class SpoilerRenderer {
  static final RegExp _spoilerPattern = RegExp(r'\|\|(.+?)\|\|', dotAll: true);

  static bool hasSpoilers(String text) => _spoilerPattern.hasMatch(text);

  static List<SpoilerSegment> parse(String text) {
    final segments = <SpoilerSegment>[];
    var lastEnd = 0;

    for (final match in _spoilerPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        segments.add(
          SpoilerSegment(
            text: text.substring(lastEnd, match.start),
            isSpoiler: false,
          ),
        );
      }

      segments.add(
        SpoilerSegment(
          text: match.group(1)!,
          isSpoiler: true,
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      segments.add(
        SpoilerSegment(
          text: text.substring(lastEnd),
          isSpoiler: false,
        ),
      );
    }

    if (segments.isEmpty) {
      segments.add(SpoilerSegment(text: text, isSpoiler: false));
    }

    return segments;
  }

  static String visibleText(String text) {
    return parse(text)
        .where((segment) => !segment.isSpoiler)
        .map((segment) => segment.text)
        .join();
  }

  static String previewText(String text, {String placeholder = 'Spoiler'}) {
    final raw = parse(text)
        .map((segment) => segment.isSpoiler ? placeholder : segment.text)
        .join();
    return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

@immutable
class SpoilerSegment {
  const SpoilerSegment({
    required this.text,
    required this.isSpoiler,
  });

  final String text;
  final bool isSpoiler;
}