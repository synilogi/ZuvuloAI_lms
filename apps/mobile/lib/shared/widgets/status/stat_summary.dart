import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../icons/app_icons.dart';

/// One figure in a [StatSummaryCard]: the server's number, what it counts, and where it leads.
@immutable
class StatFigure {
  const StatFigure({
    required this.value,
    required this.label,
    required this.icon,
    required this.hue,
    this.onTap,
  });

  /// Already formatted (`formatFigure`, a percentage).
  final String value;
  final String label;
  final IconData icon;
  final Hue hue;

  /// Opens what the figure counts; null when there is no page behind it.
  final VoidCallback? onTap;
}

/// The few figures a page leads with, side by side on one plain card — each an icon in its hue,
/// the number, and a plain-language label, and each a way into what it counts. Stacked one to a
/// line at large text sizes, where three across would crowd the numbers.
class StatSummaryCard extends StatelessWidget {
  const StatSummaryCard({required this.figures, super.key});

  final List<StatFigure> figures;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final cells = [for (final figure in figures) _FigureCell(figure: figure, stacked: stacked)];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: dark ? Border.all(color: c.border) : null,
        boxShadow: dark ? null : context.shadows.e1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.s2),
        child: stacked
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells)
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < cells.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: Space.s3),
                          child: VerticalDivider(width: 1, thickness: 1, color: c.border),
                        ),
                      Expanded(child: cells[i]),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _FigureCell extends StatelessWidget {
  const _FigureCell({required this.figure, required this.stacked});

  final StatFigure figure;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final h = c.hue(figure.hue);
    final mark = Container(
      width: Sizes.iconTile - Space.s1,
      height: Sizes.iconTile - Space.s1,
      decoration: BoxDecoration(color: h.soft, borderRadius: BorderRadius.circular(Radii.md)),
      alignment: Alignment.center,
      child: AppIcon(figure.icon, size: IconSizes.md, color: h.solid),
    );
    final number = Text(figure.value, style: context.type.numeral.copyWith(color: c.text));
    final label = Text(
      figure.label,
      style: context.type.caption.copyWith(color: c.muted),
      maxLines: stacked ? 3 : 2,
      overflow: TextOverflow.ellipsis,
    );
    final body = stacked
        ? Row(
            children: [
              mark,
              const SizedBox(width: Space.s3),
              number,
              const SizedBox(width: Space.s3),
              Expanded(child: label),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              mark,
              const SizedBox(height: Space.s2),
              number,
              label,
            ],
          );
    return Semantics(
      button: figure.onTap != null,
      label: '${figure.value} ${figure.label}',
      excludeSemantics: true,
      child: InkWell(
        onTap: figure.onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(padding: const EdgeInsets.all(Space.s2), child: body),
      ),
    );
  }
}
