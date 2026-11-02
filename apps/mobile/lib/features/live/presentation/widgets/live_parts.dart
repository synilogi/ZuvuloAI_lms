import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/live_controller.dart';

/// The badge a class carries, from the phase read off the clock. A class that is over with no
/// recording ever kept is just "Ended": "recording expired" only when there was one.
StatusKind? livePhaseBadge(LivePhase phase, [LiveClass? cls]) => switch (phase) {
  LivePhase.recordingExpired when cls != null && cls.recording == null => StatusKind.ended,
  LivePhase.live => StatusKind.live,
  LivePhase.startingSoon => StatusKind.startingSoon,
  LivePhase.upcoming => StatusKind.upcoming,
  LivePhase.cancelled => StatusKind.cancelled,
  LivePhase.ended => StatusKind.ended,
  LivePhase.recordingExpired => StatusKind.recordingExpired,
  LivePhase.unknown => null,
};

/// When the class is, said the way a person reads it: live now, a countdown, or the date it ran.
String liveTimingLabel(AppLocalizations l10n, LearnerLiveRow row, DateTime now) {
  final phase = row.phaseAt(now);
  return switch (phase) {
    LivePhase.live => l10n.statusLive,
    // Before the start it counts down; past it, a built-in room is still waiting for its host.
    LivePhase.startingSoon =>
      now.isBefore(row.liveClass.startsAt)
          ? l10n.liveStartsAt(DatesIst.relative(l10n, row.liveClass.startsAt, now))
          : l10n.statusStartingSoon,
    LivePhase.upcoming => l10n.liveStartsAt(DatesIst.relative(l10n, row.liveClass.startsAt, now)),
    _ => l10n.liveEndedOn(DatesIst.dateTime(l10n, row.liveClass.startsAt)),
  };
}

/// One class in the schedule, under a tinted strip naming its course and phase: when it is, whose
/// it is, where it stands, and the action offered on it.
class LiveClassCard extends StatelessWidget {
  const LiveClassCard({
    required this.row,
    required this.now,
    required this.onOpen,
    super.key,
    this.registered = false,
    this.trailing,
  });

  final LearnerLiveRow row;

  /// The clock the phase is read from, so a test does not depend on the real one.
  final DateTime now;
  final VoidCallback onOpen;
  final bool registered;

  /// The action offered on this card, if any.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final cls = row.liveClass;
    final phase = row.phaseAt(now);
    // A tinted strip names the course and the phase: red while live, blue before it starts, quiet
    // once it is over.
    final strip = switch (phase) {
      LivePhase.live => c.tone(Tone.danger),
      LivePhase.upcoming || LivePhase.startingSoon => c.hue(Hue.blue),
      _ => c.tone(Tone.neutral),
    };
    final badge = livePhaseBadge(phase, cls);
    return AppCard(
      onTap: onOpen,
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
                children: [
                  AppIcon(AppIcons.live, size: IconSizes.md, color: strip.solid),
                  const SizedBox(width: Space.s2),
                  Expanded(
                    child: Text(
                      row.courseTitle,
                      style: type.caption.copyWith(color: strip.ink, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null) ...[const SizedBox(width: Space.s2), StatusBadge(badge)],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(cls.title, style: type.titleM, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: Space.s2),
                MetaItem(
                  icon: AppIcons.date,
                  label: [
                    DatesIst.dateTime(l10n, cls.startsAt),
                    AppDurations.minutes(l10n, cls.durationMin),
                  ].join(' · '),
                ),
                const SizedBox(height: Space.s1),
                MetaItem(
                  icon: AppIcons.instructor,
                  label: l10n.liveWithInstructor(row.instructorName),
                ),
                const SizedBox(height: Space.s3),
                Row(
                  children: [
                    Flexible(child: CountdownChip(label: liveTimingLabel(l10n, row, now))),
                    if (registered) ...[
                      const SizedBox(width: Space.s2),
                      const StatusBadge(StatusKind.enrolled),
                    ],
                  ],
                ),
                if (trailing != null) ...[const SizedBox(height: Space.s3), trailing!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The learner's own record of a class that is over (see [LiveAttendance]); nothing when there is
/// none.
class AttendanceBadge extends StatelessWidget {
  const AttendanceBadge({required this.attended, required this.inRoom, super.key});

  final bool? attended;

  /// Whether the class was in the academy's built-in room.
  final bool inRoom;

  @override
  Widget build(BuildContext context) =>
      switch (LiveAttendance.of(attended: attended, inRoom: inRoom)) {
        final record? => LiveAttendanceBadge(record),
        null => const SizedBox.shrink(),
      };
}

/// Said above a schedule that could not be read again: what is on screen is the last answer, not
/// an error page. The screen goes on trying.
class LiveRefreshNote extends StatelessWidget {
  const LiveRefreshNote({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.s3),
        child: Row(
          children: [
            AppIcon(AppIcons.warning, size: IconSizes.sm, color: c.warnInk),
            const SizedBox(width: Space.s2),
            Expanded(
              child: Text(
                context.l10n.liveRefreshFailed,
                style: context.type.caption.copyWith(color: c.warnInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// While a built-in room waits for its host or is in session, reads the schedule again every
/// [hostWaitPoll], so Join appears when the host opens the room and the class shows as over when
/// the host ends it early. Stops the moment no such room is on the screen.
class HostWaitPoller extends ConsumerStatefulWidget {
  const HostWaitPoller({required this.active, required this.child, super.key});

  final bool active;
  final Widget child;

  @override
  ConsumerState<HostWaitPoller> createState() => _HostWaitPollerState();
}

class _HostWaitPollerState extends ConsumerState<HostWaitPoller> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(HostWaitPoller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _sync();
  }

  void _sync() {
    _timer?.cancel();
    _timer = widget.active
        ? Timer.periodic(hostWaitPoll, (_) => ref.invalidate(liveScheduleProvider))
        : null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A recording the academy kept: how long it runs and how long it stays. A kept file plays here; one
/// still being prepared, or one with no file (sample data), says so rather than offering a button that
/// cannot work.
class LiveRecordingNote extends StatelessWidget {
  const LiveRecordingNote({required this.recording, super.key});

  final LiveRecording recording;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final until = recording.availableUntil;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recording.durationMin > 0)
          Text(
            l10n.liveRecordingLength(recording.durationMin),
            style: context.type.bodyS.copyWith(color: c.muted),
          ),
        if (until != null)
          Text(
            l10n.liveRecordingUntil(DatesIst.date(until)),
            style: context.type.caption.copyWith(color: c.muted),
          ),
        if (!recording.playable) ...[
          const SizedBox(height: Space.s1),
          Text(
            recording.status == RecordingStatus.processing
                ? l10n.liveRecordingProcessing
                : l10n.liveRecordingNotPlayable,
            style: context.type.caption.copyWith(color: c.muted),
          ),
        ],
      ],
    );
  }
}

/// What the class covers, in the academy's own order.
class LiveAgenda extends StatelessWidget {
  const LiveAgenda({required this.agenda, super.key});

  final List<AgendaItem> agenda;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.liveAgendaTitle),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in agenda)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.s1),
                  child: Text(
                    l10n.liveAgendaItem(item.title, item.minutes),
                    style: context.type.bodyM,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
