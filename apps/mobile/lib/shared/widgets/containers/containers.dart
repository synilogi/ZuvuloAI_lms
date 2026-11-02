import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../icons/app_icons.dart';

/// A surface card: radius `lg`, lifted by the soft `e1` shadow in light mode and outlined in dark
/// mode (where shadows do not read). With [onTap] it is one tappable unit for screen readers.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.onTap,
    this.padding = const EdgeInsets.all(Space.cardPadding),
    this.semanticLabel,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(Radii.lg);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: radius,
        border: dark ? Border.all(color: c.border) : null,
        boxShadow: dark ? null : context.shadows.e1,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    if (onTap == null && semanticLabel == null) return card;
    return Semantics(button: onTap != null, label: semanticLabel, container: true, child: card);
  }
}

/// A section title with an optional trailing action ("See all").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// A small mark before the title, in [iconColor] — a page with many sections tells them apart.
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.headerGap),
      child: ConstrainedBox(
        // Room for the action's touch target, so a header reads the same with or without one.
        constraints: const BoxConstraints(minHeight: Space.minTap - Space.s2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              AppIcon(icon!, size: IconSizes.lg, color: iconColor ?? context.colors.accent),
              const SizedBox(width: Space.s2),
            ],
            Expanded(
              child: Semantics(header: true, child: Text(title, style: context.type.titleM)),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  minimumSize: const Size(Space.minTap, Space.minTap - Space.s2),
                  padding: const EdgeInsets.symmetric(horizontal: Space.s2),
                  tapTargetSize: MaterialTapTargetSize.padded,
                  foregroundColor: context.colors.accentInk,
                  textStyle: context.type.bodyS.copyWith(fontWeight: FontWeight.w600),
                ),
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}

/// A list row: leading visual, title, optional subtitle and meta line, trailing widget.
class AppListTile extends StatelessWidget {
  const AppListTile({
    required this.title,
    super.key,
    this.subtitle,
    this.meta,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = false,
  });

  final String title;
  final String? subtitle;

  /// A third, quieter line (timestamps, counts).
  final String? meta;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.listRow),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3 - 2),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: Space.s3)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: context.type.titleS),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle!,
                            style: context.type.bodyS.copyWith(color: c.muted),
                          ),
                        ),
                      if (meta != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(meta!, style: context.type.caption.copyWith(color: c.muted)),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: Space.s3), trailing!],
                if (showChevron) ...[
                  const SizedBox(width: Space.s2),
                  AppIcon(AppIcons.chevronRight, size: IconSizes.sm, color: c.faint),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rows grouped on one card with hairlines between them (settings, profile, detail pages).
class GroupedList extends StatelessWidget {
  const GroupedList({required this.children, super.key, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s1, 0, Space.s1, Space.s2),
            child: Semantics(
              header: true,
              child: Text(title!, style: context.type.label.copyWith(color: context.colors.muted)),
            ),
          ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const AppDivider(indent: Space.s4),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Label/value pairs as a phone settings list shows them: the label on the left, the value on the
/// right; stacked, label first, when the card is narrow or the text is large (§20).
class KeyValueTable extends StatelessWidget {
  const KeyValueTable({required this.rows, super.key});

  final List<(String label, String value)> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const AppDivider(),
          MergeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.s3 - 2),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final label = Text(
                    rows[i].$1,
                    style: context.type.bodyS.copyWith(color: c.muted),
                  );
                  final stacked =
                      constraints.maxWidth < 240 || MediaQuery.textScalerOf(context).scale(1) > 1.3;
                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label,
                        const SizedBox(height: 2),
                        Text(rows[i].$2, style: context.type.titleS),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: label),
                      const SizedBox(width: Space.s3),
                      Expanded(
                        flex: 3,
                        child: Text(
                          rows[i].$2,
                          textAlign: TextAlign.end,
                          style: context.type.bodyM.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A hairline divider in the border colour.
class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, indent: indent, color: context.colors.border);
}

/// A shortcut on a dashboard: a large tinted icon over a short label, with no card around it —
/// a row of them reads as a set of app shortcuts. One tap target.
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
    this.tone = Tone.accent,
    this.hue,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Tone tone;

  /// Draws the tile in a category hue, as the learner's Home shortcuts are, instead of [tone].
  final Hue? hue;

  @override
  Widget build(BuildContext context) {
    final hue = this.hue;
    final tile = hue == null
        ? IconTile(icon: icon, tone: tone, size: AvatarSizes.lg - Space.s1)
        : _HueShortcutTile(icon: icon, hue: hue);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.s1, vertical: Space.s2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              tile,
              const SizedBox(height: Space.s2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: context.type.caption.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A shortcut's mark in a category hue: the soft tint, a hairline of the hue, and the icon.
class _HueShortcutTile extends StatelessWidget {
  const _HueShortcutTile({required this.icon, required this.hue});

  final IconData icon;
  final Hue hue;

  @override
  Widget build(BuildContext context) {
    final h = context.colors.hue(hue);
    return Container(
      width: AvatarSizes.lg,
      height: AvatarSizes.lg,
      decoration: BoxDecoration(
        color: h.soft,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: h.solid.withValues(alpha: 0.18)),
      ),
      alignment: Alignment.center,
      child: AppIcon(icon, size: IconSizes.xl, color: h.solid),
    );
  }
}

/// An icon on a tinted rounded square — the leading mark of a menu row, a shortcut or a
/// stat, in one of the five tones.
class IconTile extends StatelessWidget {
  const IconTile({
    required this.icon,
    super.key,
    this.tone = Tone.accent,
    this.size = Sizes.iconTile,
  });

  final IconData icon;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.colors.tone(tone);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: t.soft, borderRadius: BorderRadius.circular(Radii.md)),
      alignment: Alignment.center,
      child: AppIcon(icon, size: size * 0.55, color: t.ink),
    );
  }
}

/// An icon on a tile of one of the category hues — a menu row's mark that tells the rows apart
/// by kind (courses violet, certificates gold) rather than by status, which is [IconTile]'s job.
class HueTile extends StatelessWidget {
  const HueTile({required this.icon, required this.hue, super.key, this.size = Sizes.iconTile});

  final IconData icon;
  final Hue hue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final h = context.colors.hue(hue);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: h.soft, borderRadius: BorderRadius.circular(Radii.md)),
      alignment: Alignment.center,
      child: AppIcon(icon, size: size * 0.55, color: h.solid),
    );
  }
}

/// Figures two to a line and equal in height — one per line only on the narrowest phones or at
/// large text sizes, where two would crowd the numbers (§20).
class TileGrid extends StatelessWidget {
  const TileGrid({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        // Two figures fit side by side on a 360 dp phone (328 dp of content).
        final columns = constraints.maxWidth < 300 || scale > 1.3 ? 1 : 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i += columns) ...[
              if (i > 0) const SizedBox(height: Space.s3),
              if (columns == 1)
                children[i]
              else
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: children[i]),
                      const SizedBox(width: Space.s3),
                      Expanded(
                        child: i + 1 < children.length ? children[i + 1] : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

/// One fact in a [FactStrip].
class Fact {
  const Fact({
    required this.icon,
    required this.value,
    required this.label,
    this.tone = Tone.accent,
  });

  final IconData icon;
  final String value;
  final String label;
  final Tone tone;
}

/// A course's key facts side by side on one card — an icon, the value, and what it is — as a
/// detail page heads its content. Two to a row when the phone is narrow or the text is large.
class FactStrip extends StatelessWidget {
  const FactStrip({required this.facts, super.key});

  final List<Fact> facts;

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) return const SizedBox.shrink();
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: Space.s3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final perRow = constraints.maxWidth / facts.length < 76 || scale > 1.3 ? 2 : facts.length;
          final width = constraints.maxWidth / perRow;
          return Wrap(
            runSpacing: Space.s3,
            children: [
              for (final fact in facts)
                SizedBox(
                  width: width,
                  child: MergeSemantics(
                    child: Column(
                      children: [
                        IconTile(icon: fact.icon, tone: fact.tone, size: Sizes.iconTile - 4),
                        const SizedBox(height: Space.s2),
                        Text(
                          fact.value,
                          textAlign: TextAlign.center,
                          style: context.type.titleS,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          fact.label,
                          textAlign: TextAlign.center,
                          style: context.type.caption.copyWith(color: context.colors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Small neutral chips for secondary facts (a format, a language, a certificate's name).
class InfoChips extends StatelessWidget {
  const InfoChips({required this.items, super.key});

  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: Space.s2,
      runSpacing: Space.s2,
      children: [
        for (final (icon, label) in items)
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: Space.s1 + 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(icon, size: IconSizes.sm, color: c.accentInk),
                  const SizedBox(width: Space.s1 + 2),
                  Flexible(
                    child: Text(label, style: context.type.caption.copyWith(color: c.text)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// One fact in a card's meta line: a small icon and its value ("7 lessons", "2h 22m"). [color]
/// marks a fact that needs attention (a deadline that has passed).
class MetaItem extends StatelessWidget {
  const MetaItem({required this.icon, required this.label, super.key, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: IconSizes.xs, color: color ?? c.faint),
        const SizedBox(width: Space.s1),
        Flexible(
          child: Text(label, style: context.type.caption.copyWith(color: color ?? c.muted)),
        ),
      ],
    );
  }
}

/// The head of a detail page (an assignment, a class, a notification, a submission): what it
/// belongs to, its status, its title as the page's heading, and its key facts — on one card.
class DetailHeader extends StatelessWidget {
  const DetailHeader({
    required this.title,
    super.key,
    this.eyebrow,
    this.icon,
    this.tone = Tone.accent,
    this.badge,
    this.facts = const [],
    this.footer = const [],
  });

  final String title;

  /// What it belongs to ("Class 10 Mathematics · Quadratic equations").
  final String? eyebrow;
  final IconData? icon;
  final Tone tone;
  final Widget? badge;

  /// Icon-led facts, each one a [MetaItem].
  final List<MetaItem> facts;

  /// Anything else the header must say (a late warning, a note), beneath the facts.
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null || eyebrow != null || badge != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  IconTile(icon: icon!, tone: tone),
                  const SizedBox(width: Space.s3),
                ],
                Expanded(
                  child: eyebrow == null
                      ? const SizedBox.shrink()
                      : Text(
                          eyebrow!,
                          style: context.type.caption.copyWith(color: c.muted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (badge != null) ...[const SizedBox(width: Space.s2), badge!],
              ],
            ),
            const SizedBox(height: Space.s3),
          ],
          Semantics(header: true, child: Text(title, style: context.type.titleL)),
          if (facts.isNotEmpty) ...[
            const SizedBox(height: Space.s2),
            Wrap(spacing: Space.s4, runSpacing: Space.s1 + 2, children: facts),
          ],
          if (footer.isNotEmpty) ...[const SizedBox(height: Space.s2), ...footer],
        ],
      ),
    );
  }
}

/// One item in a list of things to do or open (an assignment, an assessment, a class, a
/// certificate): a tinted icon, what it belongs to, its status, its title and its facts. The whole
/// card is one tap target.
class ItemCard extends StatelessWidget {
  const ItemCard({
    required this.title,
    required this.icon,
    super.key,
    this.tone = Tone.accent,
    this.eyebrow,
    this.badge,
    this.facts = const [],
    this.footer = const [],
    this.onTap,
    this.semanticLabel,
  });

  final String title;
  final IconData icon;
  final Tone tone;
  final String? eyebrow;
  final Widget? badge;
  final List<MetaItem> facts;
  final List<Widget> footer;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      semanticLabel: semanticLabel,
      padding: const EdgeInsets.all(Space.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, tone: tone, size: Sizes.iconTile + Space.s1),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null || badge != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          eyebrow ?? '',
                          style: context.type.caption.copyWith(color: c.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[const SizedBox(width: Space.s2), badge!],
                    ],
                  ),
                if (eyebrow != null || badge != null) const SizedBox(height: Space.s1),
                Text(title, style: context.type.titleS),
                if (facts.isNotEmpty) ...[
                  const SizedBox(height: Space.s2),
                  Wrap(spacing: Space.s3, runSpacing: Space.s1, children: facts),
                ],
                if (footer.isNotEmpty) ...[const SizedBox(height: Space.s2), ...footer],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: Space.s1),
            Padding(
              padding: const EdgeInsets.only(top: Space.s3),
              child: AppIcon(AppIcons.chevronRight, size: IconSizes.sm, color: c.faint),
            ),
          ],
        ],
      ),
    );
  }
}
