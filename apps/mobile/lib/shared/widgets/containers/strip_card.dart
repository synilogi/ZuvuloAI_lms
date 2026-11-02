import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../icons/app_icons.dart';
import 'containers.dart';

/// One item in a list of things to open — a class, a submission, a quiz, a person — as the
/// learner's live cards draw it: a tinted strip naming what it belongs to and where it stands,
/// then its title, its facts and, if it has one, the action that belongs on it. The whole card is
/// one tap target; the strip's colour carries the kind ([ToneColors] from a hue) or the state
/// (from a tone: red while live, amber while waiting).
class StripCard extends StatelessWidget {
  const StripCard({
    required this.title,
    required this.strip,
    required this.stripIcon,
    required this.stripLabel,
    super.key,
    this.badge,
    this.subtitle,
    this.facts = const [],
    this.footer,
    this.onTap,
    this.semanticLabel,
  });

  final String title;

  /// The strip's colours: `context.colors.hue(…)` for a kind, `context.colors.tone(…)` for a state.
  final ToneColors strip;
  final IconData stripIcon;

  /// What the item belongs to (a course, a batch) or what it is.
  final String stripLabel;

  /// Where it stands, at the strip's end.
  final Widget? badge;

  /// A line under the title, quieter than it.
  final String? subtitle;

  /// Its facts, one to a line: a date, a person, a count.
  final List<Widget> facts;

  /// Anything under the facts: chips, a progress bar, the card's own action.
  final Widget? footer;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final c = context.colors;
    // At large text sizes the label and the badge no longer share a line on a phone: the badge
    // drops under the label rather than pushing past the strip's edge.
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final label = Text(
      stripLabel,
      style: type.caption.copyWith(color: strip.ink, fontWeight: FontWeight.w700),
      maxLines: largeText ? 2 : 1,
      overflow: TextOverflow.ellipsis,
    );
    return AppCard(
      onTap: onTap,
      semanticLabel: semanticLabel,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: strip.soft,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.lg)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.s4, Space.s2, Space.s3, Space.s2),
              child: Row(
                crossAxisAlignment: largeText
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  AppIcon(stripIcon, size: IconSizes.md, color: strip.solid),
                  const SizedBox(width: Space.s2),
                  Expanded(
                    child: largeText && badge != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label,
                              const SizedBox(height: Space.s1),
                              badge!,
                            ],
                          )
                        : label,
                  ),
                  if (!largeText && badge != null) ...[const SizedBox(width: Space.s2), badge!],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(title, style: type.titleS, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: Space.s1),
                        Text(
                          subtitle!,
                          style: type.bodyS.copyWith(color: c.muted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      for (var i = 0; i < facts.length; i++) ...[
                        SizedBox(height: i == 0 ? Space.s2 : Space.s1),
                        facts[i],
                      ],
                      if (footer != null) ...[const SizedBox(height: Space.s3), footer!],
                    ],
                  ),
                ),
                if (onTap != null && footer == null) ...[
                  const SizedBox(width: Space.s2),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: AppIcon(AppIcons.chevronRight, size: IconSizes.sm, color: c.faint),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
