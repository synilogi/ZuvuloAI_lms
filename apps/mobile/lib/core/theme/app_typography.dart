import 'package:flutter/material.dart';

import 'tokens.dart';

/// The type scale (§22.3, mobile-sized); read with `context.type`. Sizes are logical pixels before the
/// user's text scale is applied.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.displayL,
    required this.displayM,
    required this.titleL,
    required this.titleM,
    required this.titleS,
    required this.bodyL,
    required this.bodyM,
    required this.bodyS,
    required this.label,
    required this.caption,
    required this.micro,
    required this.numeral,
    required this.editorial,
  });

  factory AppTypography.withColor(Color color) {
    // One sans family for the whole interface, as native apps do; the serif is kept for
    // documents (a certificate) through [editorial].
    TextStyle heading(double size, double line, {FontWeight weight = FontWeight.w700}) => TextStyle(
      fontFamily: FontFamilies.body,
      fontSize: size,
      height: line / size,
      fontWeight: weight,
      letterSpacing: -0.012 * size,
      color: color,
    );
    TextStyle body(double size, double line, FontWeight weight) => TextStyle(
      fontFamily: FontFamilies.body,
      fontSize: size,
      height: line / size,
      fontWeight: weight,
      color: color,
    );
    return AppTypography(
      displayL: heading(26, 32),
      displayM: heading(22, 28),
      titleL: heading(18, 24),
      titleM: heading(16, 22),
      titleS: body(15, 20, FontWeight.w600),
      bodyL: body(16, 24, FontWeight.w400),
      bodyM: body(14, 20, FontWeight.w400),
      bodyS: body(13, 18, FontWeight.w500),
      label: body(14, 20, FontWeight.w600),
      caption: body(12, 16, FontWeight.w500),
      micro: body(11, 14, FontWeight.w600),
      numeral: heading(
        24,
        30,
      ).copyWith(fontFeatures: const [FontFeature.tabularFigures()], letterSpacing: -0.3),
      editorial: TextStyle(
        fontFamily: FontFamilies.display,
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.22,
        color: color,
      ),
    );
  }

  final TextStyle displayL;
  final TextStyle displayM;
  final TextStyle titleL;
  final TextStyle titleM;
  final TextStyle titleS;
  final TextStyle bodyL;
  final TextStyle bodyM;
  final TextStyle bodyS;
  final TextStyle label;
  final TextStyle caption;

  /// The smallest text: badge labels, navigation labels, chart ticks.
  final TextStyle micro;

  /// Tabular figures for KPIs, scores and progress; resize with `copyWith(fontSize:)`.
  final TextStyle numeral;

  /// The serif, for documents only (a certificate's names) — never interface chrome.
  final TextStyle editorial;

  @override
  AppTypography copyWith() => this;

  @override
  AppTypography lerp(covariant AppTypography? other, double t) => t < 0.5 ? this : (other ?? this);
}
