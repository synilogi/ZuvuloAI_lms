import 'package:flutter/material.dart';

import 'tokens.dart';
import 'tone.dart';

/// Colour tokens as a [ThemeExtension]; read with `context.colors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors(this.palette, {required this.brightness});

  final Palette palette;
  final Brightness brightness;

  Color get ground => palette.ground;
  Color get groundGlow => palette.groundGlow;

  /// The page background (translucent in light mode — see [Palette.ground]).
  Color get bg => palette.bg;

  /// [bg] as it actually appears over the ground: for contrast checks and for anything that must
  /// match the page while being opaque itself (the system navigation bar).
  Color get bgOpaque => Color.alphaBlend(palette.bg, palette.ground);

  /// [CommonAppBar] at rest sits on the page with no fill of its own, so it is the page.
  Color get appBar => Colors.transparent;

  /// [CommonAppBar] once content has scrolled beneath it.
  Color get appBarScrolled => palette.surface;
  Color get surface => palette.surface;
  Color get surface2 => palette.surface2;
  Color get surface3 => palette.surface3;
  Color get text => palette.text;
  Color get muted => palette.muted;
  Color get faint => palette.faint;
  Color get border => palette.border;
  Color get accent => palette.accent;
  Color get accentHover => palette.accentHover;
  Color get accentPress => palette.accentPress;
  Color get accentSoft => palette.accentSoft;
  Color get accentInk => palette.accentInk;
  Color get onAccent => palette.onAccent;
  Color get info => palette.info;
  Color get infoSoft => palette.infoSoft;
  Color get infoInk => palette.infoInk;
  Color get warn => palette.warn;
  Color get warnSoft => palette.warnSoft;
  Color get warnInk => palette.warnInk;
  Color get danger => palette.danger;
  Color get dangerSoft => palette.dangerSoft;
  Color get dangerInk => palette.dangerInk;
  Color get scrim => palette.scrim;
  Color get mediaGround => palette.mediaGround;
  Color get mediaInk => palette.mediaInk;

  /// Completed states use the accent family (web convention).
  Color get success => palette.accent;

  /// A same-ramp meter track (the web's `--track`).
  Color get track => Color.alphaBlend(
    palette.accent.withValues(alpha: brightness == Brightness.dark ? 0.16 : 0.13),
    palette.surface2,
  );

  /// A filled field's resting indicator: the field's edge, ≥ 3:1 against its fill.
  Color get faintEdge => palette.faint;

  /// Strong hairline (the web's `--border-strong`).
  Color get borderStrong => Color.alphaBlend(palette.text.withValues(alpha: 0.18), palette.surface);

  ToneColors tone(Tone tone) => switch (tone) {
    Tone.accent => ToneColors(palette.accent, palette.accentSoft, palette.accentInk),
    Tone.info => ToneColors(palette.info, palette.infoSoft, palette.infoInk),
    Tone.warn => ToneColors(palette.warn, palette.warnSoft, palette.warnInk),
    Tone.danger => ToneColors(palette.danger, palette.dangerSoft, palette.dangerInk),
    Tone.neutral => ToneColors(palette.faint, palette.surface2, palette.muted),
  };

  /// A category hue in this theme (see [Hue]); the same three roles as a tone.
  ToneColors hue(Hue hue) {
    final swatch = (brightness == Brightness.dark ? Hues.dark : Hues.light)[hue]!;
    return ToneColors(swatch.solid, swatch.soft, swatch.ink);
  }

  @override
  AppColors copyWith({Palette? palette, Brightness? brightness}) =>
      AppColors(palette ?? this.palette, brightness: brightness ?? this.brightness);

  @override
  AppColors lerp(covariant AppColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

/// A tone's three values: [solid] (fills, meters, icons on surfaces), [soft] (tinted
/// backgrounds) and [ink] (text and icons on [soft]).
@immutable
class ToneColors {
  const ToneColors(this.solid, this.soft, this.ink);

  final Color solid;
  final Color soft;
  final Color ink;
}
