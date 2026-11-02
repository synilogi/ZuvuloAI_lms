import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/theme/theme.dart';
import 'package:syniastrolms_mobile/core/theme/tokens.dart';

/// modules.md §22.2, as revised by the mobile redesign (light neutrals cooled, the page white at
/// 90 % over a lavender ground). Dark `info`/`warn`/`danger` keep their light values.
const _spec = <String, (int, int)>{
  'bg': (0xE6FFFFFF, 0xFF0E0C19),
  'surface': (0xFFFFFFFF, 0xFF181624),
  'surface2': (0xFFF5F3FA, 0xFF232131),
  'surface3': (0xFFEAE7F2, 0xFF302E3F),
  'text': (0xFF1B1828, 0xFFEDE7DE),
  'muted': (0xFF5A5869, 0xFFABA498),
  'border': (0xFFE6E2EE, 0xFF343143),
  'accent': (0xFF5E3FAF, 0xFFAA98FA),
  'accentHover': (0xFF4E2D99, 0xFFBBABFF),
  'accentPress': (0xFF3E1F7F, 0xFF9885E6),
  'accentSoft': (0xFFEFEBFF, 0xFF2E2849),
  'accentInk': (0xFF4B3090, 0xFFD0C8FF),
  'onAccent': (0xFFFFFFFF, 0xFF0D0A17),
  'info': (0xFF0081AF, 0xFF0081AF),
  'infoSoft': (0xFFE3F3FC, 0xFF0E3242),
  'infoInk': (0xFF005073, 0xFF94D5F6),
  'warn': (0xFFDCA416, 0xFFDCA416),
  'warnSoft': (0xFFFFF2D6, 0xFF423007),
  'warnInk': (0xFF804C00, 0xFFEFD18F),
  'danger': (0xFFCD3349, 0xFFCD3349),
  'dangerSoft': (0xFFFFECEC, 0xFF4B1D20),
  'dangerInk': (0xFF961733, 0xFFFFB6B8),
};

Map<String, Color> _tokens(Palette p) => {
  'bg': p.bg,
  'surface': p.surface,
  'surface2': p.surface2,
  'surface3': p.surface3,
  'text': p.text,
  'muted': p.muted,
  'border': p.border,
  'accent': p.accent,
  'accentHover': p.accentHover,
  'accentPress': p.accentPress,
  'accentSoft': p.accentSoft,
  'accentInk': p.accentInk,
  'onAccent': p.onAccent,
  'info': p.info,
  'infoSoft': p.infoSoft,
  'infoInk': p.infoInk,
  'warn': p.warn,
  'warnSoft': p.warnSoft,
  'warnInk': p.warnInk,
  'danger': p.danger,
  'dangerSoft': p.dangerSoft,
  'dangerInk': p.dangerInk,
};

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG 2.x contrast ratio.
double contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Text pairs the components use (≥ 4.5:1) and UI pairs (≥ 3:1).
/// The page as it renders: [Palette.bg] over [Palette.ground].
Color _page(Palette p) => Color.alphaBlend(p.bg, p.ground);

List<(String, Color, Color)> _textPairs(Palette p) => [
  ('text/bg', p.text, _page(p)),
  ('text/surface', p.text, p.surface),
  ('text/surface2', p.text, p.surface2),
  ('text/surface3', p.text, p.surface3),
  ('muted/bg', p.muted, _page(p)),
  ('muted/surface', p.muted, p.surface),
  ('muted/surface2', p.muted, p.surface2),
  ('muted/surface3 (disabled buttons)', p.muted, p.surface3),
  ('onAccent/accent', p.onAccent, p.accent),
  ('onAccent/accentPress', p.onAccent, p.accentPress),
  ('accentInk/accentSoft', p.accentInk, p.accentSoft),
  ('accentInk/surface', p.accentInk, p.surface),
  ('accentInk/bg', p.accentInk, _page(p)),
  ('infoInk/infoSoft', p.infoInk, p.infoSoft),
  ('warnInk/warnSoft', p.warnInk, p.warnSoft),
  ('dangerInk/dangerSoft', p.dangerInk, p.dangerSoft),
  ('dangerInk/surface', p.dangerInk, p.surface),
  ('surface/text (snackbar)', p.surface, p.text),
];

List<(String, Color, Color)> _uiPairs(Palette p) => [
  ('accent/surface', p.accent, p.surface),
  ('accent/bg', p.accent, _page(p)),
  ('faint/surface (neutral icons)', p.faint, p.surface),
  ('muted/surface (unchecked controls)', p.muted, p.surface),
];

void main() {
  test('token table matches modules.md §22.2 exactly', () {
    for (final (brightness, palette) in [('light', Tokens.light), ('dark', Tokens.dark)]) {
      final actual = _tokens(palette);
      for (final entry in _spec.entries) {
        final expected = brightness == 'light' ? entry.value.$1 : entry.value.$2;
        expect(actual[entry.key]!.toARGB32(), expected, reason: '$brightness ${entry.key}');
      }
    }
  });

  test('the light page is white at 90 % over an opaque ground; dark is opaque', () {
    expect(Tokens.light.bg.a, closeTo(0.9, 0.005));
    expect(Tokens.light.bg.withValues(alpha: 1).toARGB32(), 0xFFFFFFFF);
    for (final palette in [Tokens.light, Tokens.dark]) {
      expect(palette.ground.a, 1, reason: 'the ground is what shows through the page');
    }
    expect(Tokens.dark.bg.a, 1);
  });

  test('success is the accent family (web convention)', () {
    const colors = AppColors(Tokens.light, brightness: Brightness.light);
    expect(colors.success, colors.accent);
  });

  for (final (name, palette) in [('light', Tokens.light), ('dark', Tokens.dark)]) {
    test('$name: every text/background pair is ≥ 4.5:1', () {
      final failures = [
        for (final (label, fg, bg) in _textPairs(palette))
          if (contrast(fg, bg) < 4.5) '$label ${contrast(fg, bg).toStringAsFixed(2)}',
      ];
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('$name: every UI/background pair is ≥ 3:1', () {
      final failures = [
        for (final (label, fg, bg) in _uiPairs(palette))
          if (contrast(fg, bg) < 3) '$label ${contrast(fg, bg).toStringAsFixed(2)}',
      ];
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('$name: every tone ink is readable on its soft background', () {
      final colors = AppColors(palette, brightness: Brightness.light);
      for (final tone in Tone.values) {
        final t = colors.tone(tone);
        expect(contrast(t.ink, t.soft), greaterThanOrEqualTo(4.5), reason: tone.name);
      }
    });
  }

  test('contrast formula matches WCAG reference values', () {
    expect(contrast(const Color(0xFF000000), const Color(0xFFFFFFFF)), closeTo(21, 0.01));
    expect(contrast(const Color(0xFF777777), const Color(0xFFFFFFFF)), closeTo(4.48, 0.01));
  });
}
