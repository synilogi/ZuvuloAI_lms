import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../icons/app_icons.dart';

/// The square on the left of a test or assignment card: the kind's icon on its hue, the way a
/// store shows a test's cover.
class PracticeThumb extends StatelessWidget {
  const PracticeThumb({required this.icon, required this.colors, super.key});

  final IconData icon;

  /// The hue (or, for something late, the danger tone) the square is drawn in.
  final ToneColors colors;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: AvatarSizes.lg + Space.s2,
        height: AvatarSizes.lg + Space.s2,
        decoration: BoxDecoration(
          color: colors.soft,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        alignment: Alignment.center,
        child: AppIcon(icon, size: IconSizes.xl, color: colors.solid),
      ),
    );
  }
}

/// The wide bar at the foot of a test or assignment card that says what tapping the card does
/// ("→ Start the quiz"). The card is the one tap target, so this is drawn, not a second button.
class CardActionBar extends StatelessWidget {
  const CardActionBar({required this.label, super.key, this.icon = AppIcons.forward, this.colors});

  final String label;
  final IconData icon;

  /// Tinted when set; otherwise the quiet surface the PW-style "Attempt" bar sits on.
  final ToneColors? colors;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = colors?.ink ?? c.text;
    return ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(minHeight: Sizes.buttonMd),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: Space.s2),
        decoration: BoxDecoration(
          color: colors?.soft ?? c.surface2,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: IconSizes.lg,
              height: IconSizes.lg,
              decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: AppIcon(icon, size: IconSizes.xs, color: colors?.soft ?? c.surface2),
            ),
            const SizedBox(width: Space.s2),
            Flexible(
              child: Text(
                label,
                style: context.type.bodyS.copyWith(color: ink, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A note in a quiet box at the foot of a card — why something is locked.
class CardNote extends StatelessWidget {
  const CardNote({required this.text, required this.icon, super.key});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(Radii.md)),
      child: Padding(
        padding: const EdgeInsets.all(Space.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(icon, size: IconSizes.sm, color: c.muted),
            const SizedBox(width: Space.s2),
            Expanded(
              child: Text(text, style: context.type.bodyS.copyWith(color: c.muted)),
            ),
          ],
        ),
      ),
    );
  }
}
