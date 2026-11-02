import 'package:flutter/material.dart';

/// The official ZuviloAI brand artwork bundled with the app. Every screen that shows the brand
/// draws it from here; the files are cut from `brand/zuviloai-logo.png` by `brand/make_assets.py`
/// at the repository root, which also feeds the launcher icons (`tool/make_launcher_icons.py`).
abstract final class BrandAssets {
  /// The symbol alone — the face, the circuit strands and the star — on a transparent square.
  static const mark = 'assets/brand/logo_mark.png';

  /// The same symbol set in white for a dark surface; the star stays orange.
  static const markDark = 'assets/brand/logo_mark_dark.png';

  /// The whole logo: symbol over the wordmark.
  static const full = 'assets/brand/logo_full.png';

  /// The same, with the symbol and "Zuvilo" set in white for a dark surface; "Ai" stays orange.
  static const fullDark = 'assets/brand/logo_full_dark.png';
}

/// The ZuviloAI symbol, for places too small for the wordmark. Decorative: the screen around it
/// already says where the person is.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      dark ? BrandAssets.markDark : BrandAssets.mark,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
  }
}

/// The whole ZuviloAI logo at [width], its height following — never stretched. It picks the
/// artwork set for the theme's brightness, so the wordmark reads on light and on dark.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 200});

  final double width;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      dark ? BrandAssets.fullDark : BrandAssets.full,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
  }
}
