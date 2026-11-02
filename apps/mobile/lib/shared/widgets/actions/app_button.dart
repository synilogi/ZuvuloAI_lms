import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../icons/app_icons.dart';

/// [destructiveOutline] is for a consequential but recoverable action that should not shout
/// (signing out); [destructive] for the confirm button of something that cannot be undone;
/// [inverse] for the action on an accent-filled card.
enum AppButtonVariant { primary, secondary, tertiary, destructive, destructiveOutline, inverse }

/// Heights come from [Sizes]: `sm` inline (a card's own action), `md` the default, `lg` a
/// screen's primary action. Each keeps a 48 dp touch target.
enum AppButtonSize { sm, md, lg }

/// The one button. While [busy] it shows a spinner, keeps its label for screen readers and
/// ignores taps, so a mutation cannot be submitted twice (§17).
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.busy = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool busy;

  /// Fill the available width (sticky bars, forms on phones).
  final bool expand;

  /// The width this button needs to show its label on one line — used by layouts that choose
  /// between side by side and stacked (`StickyActionBar`).
  double naturalWidth(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: _textStyle(context)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final glyph = busy || icon != null ? IconSizes.md + Space.s2 : 0;
    final pad = size == AppButtonSize.sm ? Space.s4 : Space.s5;
    final width = painter.width + glyph + pad * 2 + Space.s1;
    painter.dispose();
    return width;
  }

  TextStyle _textStyle(BuildContext context) => switch (size) {
    AppButtonSize.sm => context.type.bodyS.copyWith(fontWeight: FontWeight.w600),
    AppButtonSize.md => context.type.label,
    AppButtonSize.lg => context.type.label.copyWith(fontSize: context.type.titleS.fontSize),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null && !busy;
    final disabled = onPressed == null && !busy;
    final (Color bg, Color fg, Color? border) = switch (variant) {
      _ when disabled && variant == AppButtonVariant.tertiary => (
        Colors.transparent,
        c.muted,
        null,
      ),
      _ when disabled => (c.surface3, c.muted, null),
      AppButtonVariant.primary => (c.accent, c.onAccent, null),
      AppButtonVariant.secondary => (c.surface, c.accentInk, c.borderStrong),
      AppButtonVariant.tertiary => (Colors.transparent, c.accentInk, null),
      AppButtonVariant.destructive => (c.danger, c.onAccent, null),
      AppButtonVariant.inverse => (c.onAccent, c.accentInk, null),
      AppButtonVariant.destructiveOutline => (
        c.surface,
        c.dangerInk,
        c.danger.withValues(alpha: 0.5),
      ),
    };
    final height = switch (size) {
      AppButtonSize.sm => Sizes.buttonSm,
      AppButtonSize.md => Sizes.buttonMd,
      AppButtonSize.lg => Sizes.buttonLg,
    };
    final spinnerSize = size == AppButtonSize.sm ? IconSizes.sm : IconSizes.md - 2;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox.square(
            dimension: spinnerSize,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (icon != null)
          AppIcon(icon!, size: size == AppButtonSize.sm ? IconSizes.sm : IconSizes.md, color: fg),
        if (busy || icon != null) const SizedBox(width: Space.s2),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: _textStyle(context).copyWith(color: fg),
          ),
        ),
      ],
    );

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(Space.minTap, height)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: size == AppButtonSize.sm ? Space.s4 : Space.s5,
          vertical: Space.s1,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: border == null ? BorderSide.none : BorderSide(color: border),
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (variant == AppButtonVariant.primary && states.contains(WidgetState.pressed)) {
          return c.accentPress;
        }
        return bg;
      }),
      overlayColor: WidgetStatePropertyAll(fg.withValues(alpha: 0.08)),
      foregroundColor: WidgetStatePropertyAll(fg),
      elevation: const WidgetStatePropertyAll(0),
      tapTargetSize: MaterialTapTargetSize.padded,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: expand ? double.infinity : null,
        child: TextButton(
          onPressed: enabled ? onPressed : (busy ? () {} : null),
          style: style,
          child: content,
        ),
      ),
    );
  }
}
