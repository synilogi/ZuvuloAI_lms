import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../icons/app_icons.dart';
import '../status/progress.dart';

/// A rank badge: gold (earned) progress ring toward the next rank with the rank name beneath —
/// or, when the academy publishes no progress figure, a plain rank medallion rather than a "0%".
class RankRing extends StatelessWidget {
  const RankRing({required this.rankName, required this.progressToNext, super.key, this.size = 88});

  final String rankName;

  /// 0–1 progress toward the next rank, as the server reports it; null when it reports none.
  final double? progressToNext;
  final double size;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (progressToNext case final progress?)
            ProgressRing(value: progress, size: size, tone: Tone.warn)
          else
            ExcludeSemantics(
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: context.colors.warnSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.warn.withValues(alpha: 0.5), width: 2),
                ),
                alignment: Alignment.center,
                child: AppIcon(AppIcons.rank, size: size * 0.42, color: context.colors.warnInk),
              ),
            ),
          const SizedBox(height: Space.s2),
          Semantics(
            label: context.l10n.rankLabel(rankName),
            excludeSemantics: true,
            child: Text(rankName, textAlign: TextAlign.center, style: context.type.titleS),
          ),
        ],
      ),
    );
  }
}

@immutable
class StudyDay {
  const StudyDay({required this.label, required this.minutes, this.isToday = false});

  /// Short day name ("Mon").
  final String label;
  final int minutes;
  final bool isToday;
}

/// A week of study minutes as quiet bars — no streak mechanics (§22.1).
class StudyWeekBars extends StatelessWidget {
  const StudyWeekBars({required this.days, super.key, this.height = 72});

  final List<StudyDay> days;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final maxMinutes = days.fold<int>(0, (m, d) => math.max(m, d.minutes));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final day in days)
          Expanded(
            child: Semantics(
              label: l10n.studyDayMinutes(day.label, day.minutes),
              excludeSemantics: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    height: maxMinutes == 0 ? 4 : math.max(4, height * day.minutes / maxMinutes),
                    decoration: BoxDecoration(
                      // Studied days read as accent, today at full strength; an empty day is a
                      // quiet track mark rather than a missing bar.
                      color: day.minutes == 0
                          ? c.track
                          : day.isToday
                          ? c.accent
                          : c.accent.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(Radii.xs),
                    ),
                  ),
                  const SizedBox(height: Space.s1),
                  Text(
                    day.label,
                    textScaler: TextScaler.noScaling,
                    style: context.type.caption.copyWith(
                      color: day.isToday ? c.accentInk : c.muted,
                      fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
