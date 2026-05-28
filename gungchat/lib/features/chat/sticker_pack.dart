import '../../l10n/app_localizations.dart';

/// Bundled local sticker pack.
///
/// Stickers are sent over the existing encrypted text channel as a marker
/// string of the form `gc-sticker:<id>`. Receivers look up the id in the
/// built-in catalog and render the bundled SVG asset; no network fetch and
/// no protocol changes are required.
class StickerPackItem {
  const StickerPackItem({
    required this.id,
    required this.fallbackLabel,
    required this.assetPath,
  });

  final String id;
  final String fallbackLabel;
  final String assetPath;

  String label(AppLocalizations l10n) {
    switch (id) {
      case 'smile':
        return l10n.stickerLabelSmile;
      case 'heart':
        return l10n.stickerLabelHeart;
      case 'thumbs':
        return l10n.stickerLabelThumbs;
      case 'party':
        return l10n.stickerLabelParty;
      case 'fire':
        return l10n.stickerLabelFire;
      case 'sad':
        return l10n.stickerLabelSad;
      case 'ok':
        return l10n.stickerLabelOk;
      case 'clap':
        return l10n.stickerLabelClap;
    }
    return fallbackLabel;
  }
}

class StickerPack {
  StickerPack._();

  static const String marker = 'gc-sticker:';

  static const List<StickerPackItem> builtin = <StickerPackItem>[
    StickerPackItem(
      id: 'smile',
      fallbackLabel: 'Smile',
      assetPath: 'assets/stickers/smile.svg',
    ),
    StickerPackItem(
      id: 'heart',
      fallbackLabel: 'Heart',
      assetPath: 'assets/stickers/heart.svg',
    ),
    StickerPackItem(
      id: 'thumbs',
      fallbackLabel: 'Thumbs up',
      assetPath: 'assets/stickers/thumbs.svg',
    ),
    StickerPackItem(
      id: 'party',
      fallbackLabel: 'Party',
      assetPath: 'assets/stickers/party.svg',
    ),
    StickerPackItem(
      id: 'fire',
      fallbackLabel: 'Fire',
      assetPath: 'assets/stickers/fire.svg',
    ),
    StickerPackItem(
      id: 'sad',
      fallbackLabel: 'Sad',
      assetPath: 'assets/stickers/sad.svg',
    ),
    StickerPackItem(
      id: 'ok',
      fallbackLabel: 'OK',
      assetPath: 'assets/stickers/ok.svg',
    ),
    StickerPackItem(
      id: 'clap',
      fallbackLabel: 'Clap',
      assetPath: 'assets/stickers/clap.svg',
    ),
  ];

  static String encode(String stickerId) => '$marker$stickerId';

  /// Returns the [StickerPackItem] if [body] is exactly a sticker marker for
  /// a known sticker, otherwise null.
  static StickerPackItem? tryDecode(String body) {
    final trimmed = body.trim();
    if (!trimmed.startsWith(marker)) return null;
    final id = trimmed.substring(marker.length);
    for (final item in builtin) {
      if (item.id == id) return item;
    }
    return null;
  }
}
