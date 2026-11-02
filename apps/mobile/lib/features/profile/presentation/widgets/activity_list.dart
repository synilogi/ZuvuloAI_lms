import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/dates_ist.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/profile_controller.dart';

/// The learner's week and what they have been doing, as the academy recorded it.
class ActivityFeed extends ConsumerWidget {
  const ActivityFeed({super.key, this.now});

  /// Overridable so a test does not depend on the clock.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AsyncView<LearningActivity>(
      value: ref.watch(activityProvider),
      onRetry: () => ref.invalidate(activityProvider),
      skeleton: const DelayedLoading(skeleton: SkeletonCard()),
      data: (activity) => activity.isEmpty && activity.weekMinutes == 0
          ? EmptyState(title: l10n.profileActivityEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (activity.week.isNotEmpty) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.profileWeekMinutes(activity.weekMinutes),
                          style: context.type.bodyS.copyWith(color: context.colors.muted),
                        ),
                        const SizedBox(height: Space.s3),
                        StudyWeekBars(
                          days: [
                            for (final day in activity.week)
                              StudyDay(
                                label: DatesIst.parts(day.day ?? DateTime.now()).weekday,
                                minutes: day.minutes,
                                isToday: day.day != null && DatesIst.sameDay(day.day!, at),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.s3),
                ],
                if (activity.events.isNotEmpty)
                  _RecentEvents(events: activity.events.take(10).toList(), at: at),
              ],
            ),
    );
  }

  DateTime get at => now ?? DateTime.now();
}

/// The most recent few events, with the rest of the ten one tap away — so the profile's settings
/// are not pushed a long scroll down.
class _RecentEvents extends StatefulWidget {
  const _RecentEvents({required this.events, required this.at});

  final List<LearningEvent> events;
  final DateTime at;

  @override
  State<_RecentEvents> createState() => _RecentEventsState();
}

class _RecentEventsState extends State<_RecentEvents> {
  static const _collapsed = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final events = widget.events;
    final canExpand = events.length > _collapsed;
    final shown = _expanded || !canExpand ? events : events.take(_collapsed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: context.reduceMotion ? Duration.zero : Motion.standard,
          curve: Motion.enter,
          alignment: Alignment.topCenter,
          child: GroupedList(
            children: [
              for (final event in shown)
                AppListTile(
                  title: event.title,
                  subtitle: activityLabel(l10n, event.kind),
                  meta: DatesIst.relative(l10n, event.at, widget.at),
                  leading: AppIcon(activityIcon(event.kind), color: context.colors.muted),
                ),
            ],
          ),
        ),
        if (canExpand)
          Align(
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? l10n.actionShowLess : l10n.actionShowAll),
            ),
          ),
      ],
    );
  }
}
