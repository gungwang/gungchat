import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/l10n.dart';
import '../sticker_pack.dart';

/// Bottom sheet that lets the user pick one bundled sticker.
///
/// Returns the selected [StickerPackItem.id] via [Navigator.pop], or null if
/// the sheet is dismissed.
class StickerPickerSheet extends StatelessWidget {
  const StickerPickerSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => const StickerPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.stickerPickerTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                for (final sticker in StickerPack.builtin)
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).pop(sticker.id),
                    child: Tooltip(
                      message: sticker.label(l10n),
                      child: SvgPicture.asset(sticker.assetPath),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
