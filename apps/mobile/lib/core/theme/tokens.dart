import 'package:flutter/animation.dart';

import 'tone.dart';

/// Celestial Ink design tokens (modules.md §22), tuned for a native mobile feel: a near-white
/// page over a soft lavender ground, white cards lifted by shadow rather than outlined, and one
/// sans family. This is the only file allowed to hold colour literals.

/// One theme's colour values.
class Palette {
  const Palette({
    required this.ground,
    required this.groundGlow,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.text,
    required this.muted,
    required this.faint,
    required this.border,
    required this.accent,
    required this.accentHover,
    required this.accentPress,
    required this.accentSoft,
    required this.accentInk,
    required this.onAccent,
    required this.info,
    required this.infoSoft,
    required this.infoInk,
    required this.warn,
    required this.warnSoft,
    required this.warnInk,
    required this.danger,
    required this.dangerSoft,
    required this.dangerInk,
    required this.shadow,
    required this.scrim,
    required this.mediaGround,
    required this.mediaInk,
  });

  /// The opaque canvas painted once beneath every page (`AppBackdrop`). [bg] is translucent in
  /// light mode, so this is what shows through it — never paint it on a single screen.
  final Color ground;

  /// The soft tint the ground fades from at the top of the screen.
  final Color groundGlow;

  /// The page background every scaffold uses — white at 90 % in light mode.
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color text;
  final Color muted;

  /// Decorative ink (neutral icons, disabled glyphs, meter ticks) — never body text.
  final Color faint;
  final Color border;
  final Color accent;
  final Color accentHover;
  final Color accentPress;
  final Color accentSoft;
  final Color accentInk;
  final Color onAccent;
  final Color info;
  final Color infoSoft;
  final Color infoInk;

  /// Antique gold: reserved for what is earned (ranks, certificates, "soon").
  final Color warn;
  final Color warnSoft;
  final Color warnInk;
  final Color danger;
  final Color dangerSoft;
  final Color dangerInk;

  /// Base colour of the ink-tinted shadows (opacity is applied per elevation).
  final Color shadow;
  final Color scrim;

  /// Video always sits on a deep indigo-black ground in either theme.
  final Color mediaGround;
  final Color mediaInk;
}

abstract final class Tokens {
  static const light = Palette(
    ground: Color(0xFFF4F1FB),
    groundGlow: Color(0xFFE9E3FA),
    bg: Color(0xE6FFFFFF), // Colors.white.withValues(alpha: 0.9)
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF5F3FA),
    surface3: Color(0xFFEAE7F2),
    text: Color(0xFF1B1828),
    muted: Color(0xFF5A5869),
    faint: Color(0xFF858395),
    border: Color(0xFFE6E2EE),
    accent: Color(0xFF5E3FAF),
    accentHover: Color(0xFF4E2D99),
    accentPress: Color(0xFF3E1F7F),
    accentSoft: Color(0xFFEFEBFF),
    accentInk: Color(0xFF4B3090),
    onAccent: Color(0xFFFFFFFF),
    info: Color(0xFF0081AF),
    infoSoft: Color(0xFFE3F3FC),
    infoInk: Color(0xFF005073),
    warn: Color(0xFFDCA416),
    warnSoft: Color(0xFFFFF2D6),
    warnInk: Color(0xFF804C00),
    danger: Color(0xFFCD3349),
    dangerSoft: Color(0xFFFFECEC),
    dangerInk: Color(0xFF961733),
    shadow: Color(0xFF2A2152),
    scrim: Color(0x850A0810),
    mediaGround: Color(0xFF0F0C17),
    mediaInk: Color(0xFFFFFFFF),
  );

  /// Dark mode: `info`, `warn` and `danger` keep their light values (the web does not override them).
  static const dark = Palette(
    ground: Color(0xFF0E0C19),
    groundGlow: Color(0xFF1A1530),
    bg: Color(0xFF0E0C19),
    surface: Color(0xFF181624),
    surface2: Color(0xFF232131),
    surface3: Color(0xFF302E3F),
    text: Color(0xFFEDE7DE),
    muted: Color(0xFFABA498),
    faint: Color(0xFF787165),
    border: Color(0xFF343143),
    accent: Color(0xFFAA98FA),
    accentHover: Color(0xFFBBABFF),
    accentPress: Color(0xFF9885E6),
    accentSoft: Color(0xFF2E2849),
    accentInk: Color(0xFFD0C8FF),
    onAccent: Color(0xFF0D0A17),
    info: Color(0xFF0081AF),
    infoSoft: Color(0xFF0E3242),
    infoInk: Color(0xFF94D5F6),
    warn: Color(0xFFDCA416),
    warnSoft: Color(0xFF423007),
    warnInk: Color(0xFFEFD18F),
    danger: Color(0xFFCD3349),
    dangerSoft: Color(0xFF4B1D20),
    dangerInk: Color(0xFFFFB6B8),
    shadow: Color(0xFF000000),
    scrim: Color(0x99000000),
    mediaGround: Color(0xFF0F0C17),
    mediaInk: Color(0xFFFFFFFF),
  );
}

/// One category hue: [solid] for icons and marks, [soft] for tinted tiles and bands, [ink] for text
/// on [soft] (≥ 4.5:1) and on the page.
class HueSwatch {
  const HueSwatch(this.solid, this.soft, this.ink);

  final Color solid;
  final Color soft;
  final Color ink;
}

/// Category hues: colour that tells sections, shortcuts and kinds of content apart (Home's quick
/// actions, a to-do's kind, a lesson's type). They never carry status — that is the tones' job —
/// so a hue is always paired with a label or an icon.
abstract final class Hues {
  static const light = <Hue, HueSwatch>{
    Hue.violet: HueSwatch(Color(0xFF5E3FAF), Color(0xFFEFEBFF), Color(0xFF4B3090)),
    Hue.blue: HueSwatch(Color(0xFF2F7CF6), Color(0xFFE6F0FF), Color(0xFF1A4FA8)),
    Hue.green: HueSwatch(Color(0xFF1E9E63), Color(0xFFE3F6EC), Color(0xFF0F6B41)),
    Hue.orange: HueSwatch(Color(0xFFF26B1D), Color(0xFFFFEDE2), Color(0xFFB2470A)),
    Hue.pink: HueSwatch(Color(0xFFE0457B), Color(0xFFFDE8F0), Color(0xFFA02355)),
    Hue.gold: HueSwatch(Color(0xFFDCA416), Color(0xFFFFF2D6), Color(0xFF804C00)),
  };

  static const dark = <Hue, HueSwatch>{
    Hue.violet: HueSwatch(Color(0xFFAA98FA), Color(0xFF2E2849), Color(0xFFD0C8FF)),
    Hue.blue: HueSwatch(Color(0xFF6FA8FF), Color(0xFF132A4A), Color(0xFFB5D3FF)),
    Hue.green: HueSwatch(Color(0xFF4CC98C), Color(0xFF10352A), Color(0xFFA6E9C6)),
    Hue.orange: HueSwatch(Color(0xFFFF9A5C), Color(0xFF46250F), Color(0xFFFFC9A6)),
    Hue.pink: HueSwatch(Color(0xFFF27BA6), Color(0xFF4A1A2C), Color(0xFFFFC0D6)),
    Hue.gold: HueSwatch(Color(0xFFDCA416), Color(0xFF423007), Color(0xFFEFD18F)),
  };
}

/// 4-pt spacing scale (§22.4).
abstract final class Space {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;
  static const double s7 = 48;
  static const double s8 = 64;

  static const double gutterCompact = 16;
  static const double gutterMedium = 24;
  static const double sectionGap = 24;
  static const double cardPadding = 16;

  /// Gap between a section's header and its content.
  static const double headerGap = 4;

  /// Minimum touch target (§19).
  static const double minTap = 48;

  /// Reading measure for lesson text, in logical pixels (~68 characters at bodyL).
  static const double readingMeasure = 640;

  /// Maximum width of a form on tablets (§20).
  static const double formMaxWidth = 720;

  /// Maximum width of the sign-in and registration column on tablets.
  static const double authMaxWidth = 480;
}

/// Radius scale (§22.4), the web's `--r-*`.
abstract final class Radii {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 999;
}

/// Fixed component dimensions, so no screen invents its own. Heights are visual; every control
/// keeps a [Space.minTap] touch target around it.
abstract final class Sizes {
  /// [CommonAppBar] toolbar height (Material's own) and its title/action metrics.
  static const double appBar = 56;
  static const double appBarProfile = 64;

  /// Bottom navigation bar height on phones.
  static const double navBar = 64;

  static const double buttonSm = 36;
  static const double buttonMd = 44;
  static const double buttonLg = 50;

  /// Text fields, search fields and selects.
  static const double field = 48;
  static const double searchField = 48;

  /// List rows: one line, and with a subtitle.
  static const double listRow = 52;

  /// A leading icon tile on a list row or a menu entry.
  static const double iconTile = 36;
}

/// Icon sizes (Phosphor, duotone by default).
abstract final class IconSizes {
  static const double xs = 14;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 22;
  static const double xl = 28;

  /// Empty, error and success illustrations.
  static const double hero = 40;
}

/// Avatar diameters.
abstract final class AvatarSizes {
  static const double sm = 32;
  static const double md = 40;
  static const double lg = 56;
  static const double xl = 80;
}

/// Motion (§22.4). Everything is disabled under reduced motion.
abstract final class Motion {
  static const micro = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 200);
  static const page = Duration(milliseconds: 320);
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
}

/// Font families bundled under `assets/fonts/` (§22.3).
abstract final class FontFamilies {
  static const display = 'Fraunces';
  static const body = 'PlusJakartaSans';
}
