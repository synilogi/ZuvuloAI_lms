import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../media/media.dart';
import '../../application/live_controller.dart';
import '../widgets/live_parts.dart';
import 'live_screen.dart';

/// `/live/:liveId` — one class: what it covers, who teaches it, and the way in. There is no
/// learner endpoint for a single class, so it is read from the schedule the list already has
/// (§14).
class LiveDetailScreen extends ConsumerWidget {
  const LiveDetailScreen({required this.liveClassId, super.key});

  final String liveClassId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(liveScheduleProvider);
    return AsyncView<LiveSchedule>(
      value: value,
      // This page reads the schedule again while its room waits or runs; a read that fails keeps
      // the class on screen, and says so.
      keepDataOnError: true,
      onRetry: () => ref.invalidate(liveScheduleProvider),
      skeleton: const DelayedLoading(skeleton: SkeletonDetail()),
      data: (schedule) {
        final row = schedule.rowFor(liveClassId);
        if (row == null) {
          // A cancelled class is in none of the route's three buckets (finding 18), so this is
          // also what a learner sees after one is called off.
          return EmptyState(
            title: context.l10n.liveNotInSchedule,
            message: context.l10n.liveEmptyBody,
            actionLabel: context.l10n.actionBack,
            onAction: () => GoRouter.of(context).go(AppRoutes.live),
          );
        }
        return _LiveClass(row: row, stale: value.hasError);
      },
    );
  }
}

class _LiveClass extends ConsumerWidget {
  const _LiveClass({required this.row, required this.stale});

  final LearnerLiveRow row;

  /// The last read failed, so this is the class as it was.
  final bool stale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final now = ref.watch(liveClockProvider).value ?? DateTime.now().toUtc();
    final cls = row.liveClass;
    final phase = row.phaseAt(now);
    final recording = cls.recording;
    final over = phase == LivePhase.ended || phase == LivePhase.recordingExpired;
    listenForJoinFailures(context, ref);

    return HostWaitPoller(
      // Waiting for the host to open the room, or in a room the host may end early.
      active: cls.waitingForHostAt(now) || (cls.isRoom && phase == LivePhase.live),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Space.s4, Space.s4, Space.s4, Space.s6),
              children: [
                if (stale) const LiveRefreshNote(),
                DetailHeader(
                  icon: AppIcons.live,
                  tone: Tone.info,
                  eyebrow: row.courseTitle,
                  badge: switch (livePhaseBadge(phase, cls)) {
                    final status? => StatusBadge(status),
                    null => null,
                  },
                  title: cls.title,
                  facts: [
                    MetaItem(
                      icon: AppIcons.date,
                      label: l10n.liveStartsAt(DatesIst.dateTime(l10n, cls.startsAt)),
                    ),
                    MetaItem(
                      icon: AppIcons.time,
                      label: AppDurations.minutes(l10n, cls.durationMin),
                    ),
                    MetaItem(
                      icon: AppIcons.instructor,
                      label: l10n.liveWithInstructor(row.instructorName),
                    ),
                    if (cls.capacity case final capacity?)
                      MetaItem(icon: AppIcons.people, label: l10n.liveCapacityLabel(capacity)),
                  ],
                  footer: [
                    if (over && row.attended != null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: AttendanceBadge(attended: row.attended, inRoom: cls.isRoom),
                      ),
                    if (phase == LivePhase.cancelled)
                      Text(
                        cls.cancelReason?.trim().isNotEmpty ?? false
                            ? cls.cancelReason!
                            : l10n.liveCancelledNote,
                        style: context.type.bodyM.copyWith(color: c.dangerInk),
                      ),
                  ],
                ),
                if (cls.description?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: Space.sectionGap),
                  SectionHeader(title: l10n.liveAboutTitle),
                  Text(cls.description!, style: context.type.bodyM),
                ],
                if (cls.agenda.isNotEmpty) ...[
                  const SizedBox(height: Space.sectionGap),
                  LiveAgenda(agenda: cls.agenda),
                ],
                if (cls.reminders.isNotEmpty) ...[
                  const SizedBox(height: Space.s3),
                  Text(
                    l10n.liveRemindersNote,
                    style: context.type.caption.copyWith(color: c.muted),
                  ),
                ],
                if (recording != null) ...[
                  const SizedBox(height: Space.sectionGap),
                  SectionHeader(title: l10n.liveTabRecordings),
                  // The kept file streams from the API with the learner's own token, like a lesson video.
                  if (recording.playable && phase == LivePhase.ended) ...[
                    AppVideoPlayer(url: liveRecordingPath(cls.id)),
                    const SizedBox(height: Space.s2),
                  ],
                  LiveRecordingNote(recording: recording),
                ],
                const SizedBox(height: Space.sectionGap),
                AppButton(
                  label: l10n.actionOpenCourse,
                  variant: AppButtonVariant.tertiary,
                  onPressed: cls.courseId.isEmpty
                      ? null
                      : () => GoRouter.of(context).go(AppRoutes.learnCourse(cls.courseId)),
                ),
              ],
            ),
          ),
          if (phase != LivePhase.cancelled &&
              phase != LivePhase.ended &&
              phase != LivePhase.recordingExpired)
            StickyActionBar(
              primary: LiveAction(row: row, now: now, showJoinNote: !cls.isRoom),
            ),
        ],
      ),
    );
  }
}
