import 'package:flutter/material.dart';

import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/format/ist.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../staff_live/staff_live.dart';
import '../../application/staff_calendar_controller.dart';

String eventTypeLabel(AppLocalizations l10n, CalendarEventType type) => switch (type) {
  CalendarEventType.live => l10n.calendarTypeLive,
  CalendarEventType.assignment => l10n.calendarTypeAssignment,
  CalendarEventType.quiz => l10n.calendarTypeQuiz,
  CalendarEventType.milestone => l10n.calendarTypeMilestone,
  CalendarEventType.reminder || CalendarEventType.unknown => l10n.calendarTypeReminder,
};

IconData eventTypeIcon(CalendarEventType type) => switch (type) {
  CalendarEventType.live => AppIcons.live,
  CalendarEventType.assignment => AppIcons.assignment,
  CalendarEventType.quiz => AppIcons.quiz,
  CalendarEventType.milestone => AppIcons.rocket,
  CalendarEventType.reminder || CalendarEventType.unknown => AppIcons.notifications,
};

String milestoneLabel(AppLocalizations l10n, MilestoneKind kind) => switch (kind) {
  MilestoneKind.cohortStarts => l10n.calendarMilestoneCohortStarts,
  MilestoneKind.chapterRelease => l10n.calendarMilestoneChapterRelease,
  MilestoneKind.enrolmentCloses => l10n.calendarMilestoneEnrolmentCloses,
  MilestoneKind.cohortEnds => l10n.calendarMilestoneCohortEnds,
  MilestoneKind.courseLaunch || MilestoneKind.unknown => l10n.calendarMilestoneCourseLaunch,
};

String timingLabel(AppLocalizations l10n, CalendarTiming timing) => switch (timing) {
  CalendarTiming.timed || CalendarTiming.unknown => l10n.calendarTimingTimed,
  CalendarTiming.moment => l10n.calendarTimingMoment,
  CalendarTiming.allDay => l10n.calendarTimingAllDay,
};

/// When the event happens, in the words its own timing calls for.
String whenLabel(AppLocalizations l10n, CalendarEvent event) => switch (event.timing) {
  CalendarTiming.allDay => l10n.calendarAllDay,
  CalendarTiming.moment => l10n.calendarMoment(DatesIst.time(event.startsAt)),
  _ =>
    '${DatesIst.time(event.startsAt)} · '
        '${AppDurations.minutes(l10n, event.durationMin ?? 0)}',
};

/// A notify offset in the words a person uses for it.
String reminderLabelFor(AppLocalizations l10n, int minutes) {
  if (minutes == 1440) return l10n.staffLiveReminderDay;
  if (minutes >= 60 && minutes % 60 == 0) return l10n.staffLiveReminderHours(minutes ~/ 60);
  return l10n.staffLiveReminderOffset(minutes);
}

/// The seven days of the week in view, with a dot on each day that has something on it.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    required this.days,
    required this.selected,
    required this.busy,
    required this.onPick,
    required this.today,
    super.key,
  });

  final List<DateTime> days;
  final DateTime selected;

  /// The IST days in the range that carry at least one event.
  final Set<DateTime> busy;
  final ValueChanged<DateTime> onPick;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: Semantics(
              selected: day == selected,
              button: true,
              label: DatesIst.date(day),
              child: ExcludeSemantics(
                child: InkWell(
                  borderRadius: BorderRadius.circular(Radii.md),
                  onTap: () => onPick(day),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: Space.s2),
                    decoration: BoxDecoration(
                      color: day == selected ? c.accent : null,
                      borderRadius: BorderRadius.circular(Radii.lg),
                      border: day == today
                          ? Border.all(color: c.accent)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DatesIst.weekdayInitial(day),
                          style: context.type.caption.copyWith(
                            color: day == selected ? c.onAccent.withValues(alpha: 0.8) : c.muted,
                          ),
                        ),
                        const SizedBox(height: Space.s1),
                        Text(
                          '${Ist.wallClock(day).day}',
                          style: context.type.label.copyWith(
                            color: day == selected ? c.onAccent : c.text,
                          ),
                        ),
                        const SizedBox(height: Space.s1),
                        // A day with something on it carries a dot, not a count: the agenda says
                        // what it is.
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: busy.contains(day)
                                ? (day == selected ? c.onAccent : c.accent)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The hue an event's kind is told apart by: live classes pink, deadlines and quizzes orange,
/// milestones violet, reminders blue — as the navigation colours those areas.
Hue eventTypeHue(CalendarEventType type) => switch (type) {
  CalendarEventType.live => AppNavIcons.of(AppIcons.live).hue,
  CalendarEventType.assignment || CalendarEventType.quiz => Hue.orange,
  CalendarEventType.milestone => Hue.violet,
  CalendarEventType.reminder || CalendarEventType.unknown => AppNavIcons.of(AppIcons.calendar).hue,
};

/// The colours an event's strip takes: a live class reads as the schedule does (red while live,
/// quiet once over); anything ticked off is quiet; everything else wears its kind's hue.
ToneColors eventStripColors(
  BuildContext context, {
  required CalendarEventType type,
  required bool done,
  LivePhase? phase,
}) {
  final c = context.colors;
  if (type == CalendarEventType.live && phase != null) return liveStripColors(context, phase);
  if (done) return c.tone(Tone.neutral);
  return c.hue(eventTypeHue(type));
}

/// One event in the day's agenda: what it is, when, and what it belongs to.
class AgendaRow extends StatelessWidget {
  const AgendaRow({required this.row, required this.onOpen, super.key});

  final CalendarRow row;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final event = row.event;
    final due = row.due;

    return StripCard(
      strip: eventStripColors(context, type: event.type, done: event.done, phase: row.phase),
      stripIcon: eventTypeIcon(event.type),
      stripLabel: eventTypeLabel(l10n, event.type),
      // A live class carries the phase the academy sent; anything else, whether it is done.
      badge: switch ((row.phase, event.done)) {
        (final phase?, _) => StatusBadge(livePhaseKind(phase)),
        (null, true) => const StatusBadge(StatusKind.done),
        _ => null,
      },
      title: event.title,
      onTap: onOpen,
      facts: [
        MetaItem(icon: AppIcons.time, label: whenLabel(l10n, event)),
        if (row.courseTitle case final course?) MetaItem(icon: AppIcons.courses, label: course),
        if (due != null)
          MetaItem(
            icon: AppIcons.assignment,
            label: l10n.calendarDueSummary(due.submitted, due.learners),
          )
        else if (row.instructorName case final name?)
          MetaItem(icon: AppIcons.instructor, label: name),
      ],
    );
  }
}

/// A month at a glance: every day in the grid, with a dot for the days that carry something. Shown
/// from the tablet breakpoint, beside the day's agenda (§20).
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    required this.days,
    required this.selected,
    required this.busy,
    required this.onPick,
    required this.today,
    super.key,
  });

  final List<DateTime> days;
  final DateTime selected;
  final Set<DateTime> busy;
  final ValueChanged<DateTime> onPick;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final month = Ist.wallClock(selected).month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final day in days.take(7))
              Expanded(
                child: Center(
                  child: Text(
                    DatesIst.weekdayInitial(day),
                    style: context.type.caption.copyWith(color: c.muted),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.s2),
        for (var week = 0; week < days.length / 7; week++)
          Row(
            children: [
              for (final day in days.skip(week * 7).take(7))
                Expanded(
                  child: Semantics(
                    selected: day == selected,
                    button: true,
                    label: DatesIst.date(day),
                    child: ExcludeSemantics(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(Radii.sm),
                        onTap: () => onPick(day),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          padding: const EdgeInsets.symmetric(vertical: Space.s2),
                          decoration: BoxDecoration(
                            color: day == selected ? c.accent : null,
                            borderRadius: BorderRadius.circular(Radii.md),
                            border: day == today
                                ? Border.all(color: c.accent)
                                : Border.all(color: Colors.transparent),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${Ist.wallClock(day).day}',
                                style: context.type.bodyS.copyWith(
                                  // A day from the month either side is quieter.
                                  color: day == selected
                                      ? c.onAccent
                                      : (Ist.wallClock(day).month == month ? c.text : c.faint),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: busy.contains(day)
                                      ? (day == selected ? c.onAccent : c.accent)
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
