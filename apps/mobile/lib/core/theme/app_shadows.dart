import 'package:flutter/material.dart';

import 'tokens.dart';

/// Ink-tinted soft shadows (§22.4): `e1` cards (which carry no outline in light mode), `e2` sheets and menus, `e3` dialogs. Dark mode
/// separates layers with surface steps instead, so its shadows are near-invisible.
@immutable
class AppShadows extends ThemeExtension<AppShadows> {
  const AppShadows({required this.e1, required this.e2, required this.e3, required this.up});

  factory AppShadows.from(Palette palette, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    BoxShadow s(double y, double blur, double alpha) => BoxShadow(
      color: palette.shadow.withValues(alpha: dark ? alpha * 0.4 : alpha),
      offset: Offset(0, y),
      blurRadius: blur,
    );
    return AppShadows(
      e1: [s(4, 16, 0.06), s(1, 2, 0.04)],
      e2: [s(8, 24, 0.10), s(1, 3, 0.05)],
      e3: [s(24, 56, 0.16), s(2, 10, 0.06)],
      up: [s(-2, 16, 0.07)],
    );
  }

  final List<BoxShadow> e1;
  final List<BoxShadow> e2;
  final List<BoxShadow> e3;

  /// Cast upward by bars docked to the bottom edge (navigation, sticky actions).
  final List<BoxShadow> up;

  @override
  AppShadows copyWith() => this;

  @override
  AppShadows lerp(covariant AppShadows? other, double t) => t < 0.5 ? this : (other ?? this);
}
