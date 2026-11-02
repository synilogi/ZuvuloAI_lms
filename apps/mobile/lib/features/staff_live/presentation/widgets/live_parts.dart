import 'package:flutter/material.dart';

import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_live_controller.dart';

/// The badge for a phase, as the academy's own rule derives it. A class that is over with no
/// recording ever kept is just "Ended": "recording expired" only when there was one.
StatusKind livePhaseKind(LivePhase phase, [LiveClass? cls]) => switch (phase) {
  LivePhase.recordingExpired when cls != null && cls.recording == null => StatusKind.ended,
  LivePhase.upcoming || LivePhase.unknown => StatusKind.scheduled,
  LivePhase.startingSoon => StatusKind.startingSoon,
  LivePhase.live => StatusKind.live,
  LivePhase.ended => StatusKind.ended,
  LivePhase.recordingExpired => StatusKind.recordingExpired,
  LivePhase.cancelled => StatusKind.cancelled,
};

String visibilityLabel(AppLocalizations l10n, LiveVisibility visibility) => switch (visibility) {
  LiveVisibility.enrolled || LiveVisibility.unknown => l10n.staffLiveVisibilityEnrolled,
  LiveVisibility.cohort => l10n.staffLiveVisibilityCohort,
  LiveVisibility.public => l10n.staffLiveVisibilityPublic,
};

/// A reminder offset in the words a person uses for it.
String reminderLabel(AppLocalizations l10n, int minutes) {
  if (minutes == 1440) return l10n.staffLiveReminderDay;
  if (minutes >= 60 && minutes % 60 == 0) return l10n.staffLiveReminderHours(minutes ~/ 60);
  return l10n.staffLiveReminderOffset(minutes);
}

/// The reminder offsets the form offers, from the academy's own settings downwards.
const reminderChoices = [1440, 240, 60, 30, 15, 10, 5];

/// The colours a class's strip takes for where it stands: the live kind's own hue while it is
/// still to come, red while it is live, and quiet once it is over or called off — as the learner's
/// cards read.
ToneColors liveStripColors(BuildContext context, LivePhase phase) {
  final c = context.colors;
  return switch (phase) {
    LivePhase.live => c.tone(Tone.danger),
    LivePhase.upcoming ||
    LivePhase.startingSoon ||
    LivePhase.unknown => c.hue(AppNavIcons.of(AppIcons.live).hue),
    LivePhase.ended || LivePhase.recordingExpired || LivePhase.cancelled => c.tone(Tone.neutral),
  };
}

/// One class in the staff schedule: when it is, where it stands, and how full it is.
class StaffLiveCard extends StatelessWidget {
  const StaffLiveCard({required this.row, required this.onOpen, required this.now, super.key});

  final StaffLiveRow row;
  final VoidCallback onOpen;

  /// The device's idea of now, for the phase the badge shows.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cls = row.liveClass;
    // The badge follows the clock, from the server's own timestamps (§14).
    final phase = cls.cancelled ? LivePhase.cancelled : row.phaseAt(now);

    return StripCard(
      strip: liveStripColors(context, phase),
      stripIcon: AppIcons.live,
      stripLabel: row.courseTitle,
      badge: StatusBadge(livePhaseKind(phase, cls)),
      title: cls.title,
      onTap: onOpen,
      facts: [
        MetaItem(
          icon: AppIcons.date,
          label: [
            DatesIst.dateTime(l10n, cls.startsAt),
            AppDurations.minutes(l10n, cls.durationMin),
          ].join(' · '),
        ),
        MetaItem(icon: AppIcons.instructor, label: l10n.liveWithInstructor(row.instructorName)),
        MetaItem(
          icon: AppIcons.people,
          // The route omits the count for a class with no registrations at all.
          label: switch (cls.capacity) {
            final capacity? => l10n.staffLiveOfCapacity(cls.registered ?? 0, capacity),
            null => l10n.staffLiveRegisteredCount(cls.registered ?? 0),
          },
        ),
      ],
    );
  }
}

/// The reminder offsets the academy will use, as chips that can be switched on and off.
class ReminderChips extends StatelessWidget {
  const ReminderChips({required this.selected, required this.onToggle, super.key});

  final List<int> selected;

  /// Null while the academy will not take a change.
  final void Function(int minutes)? onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Whatever the academy already set, even an offset this app does not offer itself.
    final offsets = {...reminderChoices, ...selected}.toList()..sort((a, b) => b.compareTo(a));

    return Wrap(
      spacing: Space.s2,
      runSpacing: Space.s2,
      children: [
        for (final minutes in offsets)
          FilterChip(
            label: Text(reminderLabel(l10n, minutes)),
            selected: selected.contains(minutes),
            onSelected: onToggle == null ? null : (_) => onToggle!(minutes),
          ),
      ],
    );
  }
}
