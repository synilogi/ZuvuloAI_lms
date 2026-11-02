import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../containers/containers.dart';
import '../icons/app_icons.dart';

/// A headline number with its previous-period change in words and an arrow (§22.7). [delta] is
/// the server's percentage change; the tile only formats it.
class KpiTile extends StatelessWidget {
  const KpiTile({
    required this.label,
    required this.value,
    super.key,
    this.delta,
    this.deltaUnit = '%',
    this.comparisonLabel,
    this.higherIsBetter = true,
    this.onTap,
    this.footer,
    this.icon,
    this.tone = Tone.accent,
  });

  /// What the figure counts, as a tinted icon beside the label.
  final IconData? icon;
  final Tone tone;

  final String label;

  /// Pre-formatted value ("1,284", "₹3,999.00", "72%").
  final String value;

  /// Change vs the previous period (12.5 = +12.5); null hides the change line.
  final double? delta;

  /// What [delta] is measured in. A count moves in percent, a rate in percentage points, so a
  /// completion rate reads "+3 pts" rather than "+3%" (`kpiChange`, §18).
  final String deltaUnit;

  /// The comparison, e.g. "vs previous 90 days".
  final String? comparisonLabel;

  /// Whether an increase is good news (colours the change accordingly).
  final bool higherIsBetter;
  final VoidCallback? onTap;

  /// A small trend drawn inside the tile, beneath the figure (a sparkline).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    String? deltaText;
    String? deltaSemantics;
    Color deltaColor = c.muted;
    IconData? deltaIcon;
    if (delta != null) {
      final magnitude = '${NumberFormat('#,##0.#', locale).format(delta!.abs())}$deltaUnit';
      final comparison = comparisonLabel ?? '';
      if (delta! > 0) {
        deltaText = '+$magnitude';
        deltaSemantics = l10n.kpiDeltaUp(magnitude, comparison);
        deltaIcon = AppIcons.trendUp;
        deltaColor = higherIsBetter ? c.accentInk : c.dangerInk;
      } else if (delta! < 0) {
        deltaText = '−$magnitude';
        deltaSemantics = l10n.kpiDeltaDown(magnitude, comparison);
        deltaIcon = AppIcons.trendDown;
        deltaColor = higherIsBetter ? c.dangerInk : c.accentInk;
      } else {
        deltaText = '0$deltaUnit';
        deltaSemantics = l10n.kpiDeltaFlat(comparison);
        deltaIcon = AppIcons.trendFlat;
      }
    }

    return Semantics(
      container: true,
      button: onTap != null,
      label: [label, value, ?deltaSemantics].join(', '),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.lg),
          boxShadow: Theme.of(context).brightness == Brightness.dark ? null : context.shadows.e1,
        ),
        child: Material(
          color: c.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg),
            side: Theme.of(context).brightness == Brightness.dark
                ? BorderSide(color: c.border)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.lg),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(Space.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Heading(label: label, icon: icon, tone: tone),
                  const SizedBox(height: Space.s2),
                  Text(value, style: context.type.numeral),
                  if (deltaText != null) ...[
                    const SizedBox(height: Space.s2),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: deltaColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon(deltaIcon!, size: IconSizes.xs, color: deltaColor),
                            const SizedBox(width: Space.s1),
                            Text(
                              deltaText,
                              style: context.type.caption.copyWith(
                                color: deltaColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Space.s1),
                    // Its own line, so tiles side by side keep the same rhythm.
                    if (comparisonLabel != null)
                      Text(
                        comparisonLabel!,
                        style: context.type.caption.copyWith(color: c.muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                  if (footer != null) ...[const SizedBox(height: Space.s3), footer!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The tile's icon above its label: the same in every tile of a row and at every text size, and
/// the label always has the tile's full width, so no word is broken in two.
class _Heading extends StatelessWidget {
  const _Heading({required this.label, required this.icon, required this.tone});

  final String label;
  final IconData? icon;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: context.type.caption.copyWith(color: context.colors.muted),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    if (icon == null) return text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(icon: icon!, tone: tone, size: Sizes.iconTile - 4),
        const SizedBox(height: Space.s2),
        text,
      ],
    );
  }
}
