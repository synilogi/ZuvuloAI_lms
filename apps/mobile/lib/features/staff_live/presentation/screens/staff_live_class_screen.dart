import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/auth/capabilities.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/format/figures.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/platform/external_link.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_live_controller.dart';
import '../widgets/live_parts.dart';

/// `/staff/live/:liveId` — one class: where it stands, who registered, and the decisions left. The
/// phase follows the clock for display; whether the academy will take an edit or a cancellation is
/// its own call, and its refusal is what the screen shows (§14, §18).
class StaffLiveClassScreen extends ConsumerWidget {
  const StaffLiveClassScreen({required this.liveId, super.key});

  final String liveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView<StaffLiveDetail>(
      value: ref.watch(staffLiveClassProvider(liveId)),
      onRetry: () => ref.invalidate(staffLiveClassProvider(liveId)),
      skeleton: const DelayedLoading(skeleton: SkeletonDetail()),
      notFound: NotFoundView(onBack: () => GoRouter.of(context).go(AppRoutes.staffLive)),
      data: (detail) => _LiveClass(liveId: liveId, detail: detail),
    );
  }
}

class _LiveClass extends ConsumerWidget {
  const _LiveClass({required this.liveId, required this.detail});

  final String liveId;
  final StaffLiveDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final cls = detail.liveClass;
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;
    final now = liveNow(ref);
    final phase = cls.cancelled ? LivePhase.cancelled : detail.phaseAt(now);
    final action = ref.watch(liveActionProvider);
    final controller = ref.read(liveActionProvider.notifier);
    final mayManage = watchCan(ref, Capability.manageLive);
    final mayNotify = watchCan(ref, Capability.notifyLive);
    final editable = detail.editableAt(now);
    // Read again on every tick of the clock: Start appears at the quarter hour without a refresh.
    final canStart = detail.canStartAt(now);
    final roomOpen = cls.isRoom && cls.startedAt != null && phase == LivePhase.live;

    // Whatever the academy answered is said once, in its own words.
    ref.listen(liveActionProvider, (previous, next) {
      if (next.ended && previous?.ended != true) {
        showAppSnackbar(context, l10n.staffLiveEnded, tone: SnackTone.success);
        controller.clearAnswer();
        return;
      }
      if (next.roomFailed && previous?.roomFailed != true) {
        showAppSnackbar(context, l10n.liveRoomUnavailable, tone: SnackTone.error);
        controller.clearAnswer();
        return;
      }
      if (next.connectionLost && previous?.connectionLost != true) {
        showAppSnackbar(context, l10n.liveConnectionLost, tone: SnackTone.error);
        controller.clearAnswer();
        return;
      }
      if (next.sent case final sent? when sent != previous?.sent) {
        showAppSnackbar(context, l10n.staffLiveRemindSent(sent), tone: SnackTone.success);
        controller.clearAnswer();
        return;
      }
      final failure = next.failure;
      final issue = next.issues.firstOrNull;
      if (failure == null && issue == null) return;
      if (failure == previous?.failure && issue == previous?.issues.firstOrNull) return;
      final kind = failure == null ? null : refusalKindOf(failure);
      showAppSnackbar(
        context,
        issue?.message ??
            (kind == null
                ? failure?.message ?? l10n.stateErrorBody
                : refusalMessage(l10n, kind, serverMessage: failure?.message)),
        tone: SnackTone.error,
      );
      controller.clearAnswer();
    });

    Future<void> openMeeting() async {
      // Only an https link, and never in a WebView (§13). A link that does not parse is not opened.
      final link = cls.meeting.joinable;
      if (link == null) {
        showAppSnackbar(context, l10n.staffLiveLinkUnusable, tone: SnackTone.error);
        return;
      }
      final opened = await openedExternally(ref.read(openExternalLinkProvider), link);
      if (!opened && context.mounted) {
        showAppSnackbar(context, l10n.liveLinkNotOpened, tone: SnackTone.error);
      }
    }

    Future<void> endClass() async {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierColor: c.scrim,
        builder: (_) => AppDialog(
          title: l10n.staffLiveEndConfirmTitle,
          message: l10n.staffLiveEndConfirmBody,
          confirmLabel: l10n.staffLiveEndAction,
          destructive: true,
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await controller.end(liveId);
    }

    Future<void> cancelClass() async {
      final reason = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        barrierColor: c.scrim,
        builder: (_) => AppDialog(
          title: l10n.staffLiveCancelConfirmTitle,
          message: l10n.staffLiveCancelConfirmBody,
          confirmLabel: l10n.staffLiveCancelAction,
          destructive: true,
          body: AppTextField(
            label: l10n.staffLiveCancelReasonLabel,
            controller: reason,
            maxLength: 1000,
            maxLines: 2,
            required: true,
          ),
        ),
      );
      if (confirmed != true || !context.mounted) return;
      final ok = await controller.cancel(liveId, reason: reason.text.trim());
      if (ok && context.mounted) {
        showAppSnackbar(context, l10n.staffLiveCancelled, tone: SnackTone.success);
      }
    }

    Widget header(String title, IconData icon, Hue hue, {String? action}) =>
        SectionHeader(title: title, icon: icon, iconColor: c.hue(hue).solid, actionLabel: action);

    // What can be done with the class right now, by the academy's own rules: the room is started,
    // gone back into or ended; an outside meeting is opened once its window is.
    final nowActions = <Widget>[
      // The built-in room: the host opens it in its window, goes back in while it runs, and
      // closes it — which is what settles attendance.
      if (mayManage && cls.isRoom && (canStart || roomOpen))
        AppButton(
          label: roomOpen ? l10n.staffLiveRejoinAction : l10n.staffLiveStartAction,
          icon: AppIcons.live,
          busy: action.busy,
          expand: true,
          onPressed: () => withLiveRoomJoining(
            context,
            () => controller.teach(liveId, alreadyStarted: roomOpen),
          ),
        ),
      if (mayManage && roomOpen)
        AppButton(
          label: l10n.staffLiveEndAction,
          variant: AppButtonVariant.destructiveOutline,
          busy: action.busy,
          expand: true,
          onPressed: endClass,
        ),
      if (cls.meeting.kind == MeetingKind.external && cls.meeting.link != null)
        AppButton(
          label: l10n.staffLiveJoinAction,
          icon: AppIcons.external,
          expand: true,
          onPressed: canJoinPhase(phase) ? openMeeting : null,
        ),
    ];
    // When the room or the link opens, in the academy's own terms.
    final roomNote = cls.isRoom && phase != LivePhase.cancelled
        ? (canStart
              ? l10n.staffLiveStartNote
              : phase == LivePhase.upcoming
              ? l10n.staffLiveStartNotYet
              : l10n.staffLiveRoomNote)
        : (!canJoinPhase(phase) && !cls.cancelled && phase == LivePhase.upcoming)
        ? l10n.staffLiveJoinNotReady
        : null;
    final manage = <Widget>[
      if (mayManage && editable)
        AppButton(
          label: l10n.staffLiveEditAction,
          icon: AppIcons.edit,
          variant: AppButtonVariant.secondary,
          onPressed: () => GoRouter.of(context).go(AppRoutes.staffLiveEdit(liveId)),
        ),
      if (mayNotify && !cls.cancelled)
        AppButton(
          label: l10n.staffLiveRemindAction,
          icon: AppIcons.notifications,
          variant: AppButtonVariant.secondary,
          busy: action.busy,
          onPressed: () => controller.remind(liveId),
        ),
      if (mayManage &&
          !cls.cancelled &&
          cls.startedAt == null &&
          (phase == LivePhase.upcoming || phase == LivePhase.startingSoon))
        AppButton(
          label: l10n.staffLiveCancelAction,
          variant: AppButtonVariant.destructiveOutline,
          busy: action.busy,
          onPressed: cancelClass,
        ),
    ];

    return RefreshIndicator(
      onRefresh: () => ref.refresh(staffLiveClassProvider(liveId).future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
        children: [
          _StateCard(detail: detail, phase: phase, actions: nowActions, note: roomNote),
          if (manage.isNotEmpty) ...[
            const SizedBox(height: Space.s3),
            Wrap(spacing: Space.s2, runSpacing: Space.s2, children: manage),
          ],
          // Why an edit is not offered, in the academy's own terms.
          if (mayManage && !editable) ...[
            const SizedBox(height: Space.s2),
            Text(
              cls.cancelled ? l10n.staffLiveEditClosedCancelled : l10n.staffLiveEditClosedStarted,
              style: context.type.caption.copyWith(color: c.muted),
            ),
          ],
          const SizedBox(height: Space.sectionGap),
          header(l10n.staffLiveDetailsTitle, AppIcons.info, Hue.blue),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s1),
            child: KeyValueTable(
              rows: [
                (l10n.staffLiveFormVisibility, visibilityLabel(l10n, cls.visibility)),
                if (cls.meeting.kind != MeetingKind.unknown)
                  (
                    l10n.staffLiveFormMeetingKind,
                    cls.isRoom ? l10n.staffLiveMeetingRoom : l10n.staffLiveMeetingExternal,
                  ),
                if (cls.capacity case final capacity?)
                  (l10n.staffLiveFormCapacity, l10n.liveCapacityLabel(capacity)),
                if (cls.recording case final recording?)
                  (
                    l10n.liveTabRecordings,
                    recording.status == RecordingStatus.processing
                        ? l10n.liveRecordingProcessing
                        : l10n.liveRecordingLength(recording.durationMin),
                  )
                else if (cls.isRoom && detail.room != null && phase != LivePhase.cancelled)
                  (
                    l10n.liveTabRecordings,
                    detail.room!.recording
                        ? l10n.staffLiveRecordingHow
                        : l10n.staffLiveRecordingNone,
                  ),
                if (detail.recordingViews case final views?)
                  (l10n.liveTabRecordings, l10n.staffLiveRecordingViews(views)),
              ],
            ),
          ),
          if (cls.description case final description? when description.isNotEmpty) ...[
            const SizedBox(height: Space.sectionGap),
            header(l10n.liveAboutTitle, AppIcons.lessonReading, Hue.violet),
            Text(description, style: context.type.bodyM),
          ],
          if (cls.agenda.isNotEmpty) ...[
            const SizedBox(height: Space.sectionGap),
            header(l10n.liveAgendaTitle, AppIcons.list, Hue.orange),
            GroupedList(
              children: [
                for (final item in cls.agenda)
                  AppListTile(title: item.title, meta: AppDurations.minutes(l10n, item.minutes)),
              ],
            ),
          ],
          if (mayNotify) ...[
            const SizedBox(height: Space.sectionGap),
            header(l10n.staffLiveRemindersTitle, AppIcons.notifications, Hue.gold),
            ReminderChips(
              selected: cls.reminders,
              onToggle: cls.cancelled
                  ? null
                  : (minutes) async {
                      final next = cls.reminders.contains(minutes)
                          ? (cls.reminders.toList()..remove(minutes))
                          : [...cls.reminders, minutes];
                      if (next.length > LiveClassForm.maxReminders) return;
                      final ok = await controller.setReminders(
                        liveId,
                        next..sort((a, b) => b.compareTo(a)),
                      );
                      if (ok && context.mounted) {
                        showAppSnackbar(
                          context,
                          l10n.staffLiveRemindersSaved,
                          tone: SnackTone.success,
                        );
                      }
                    },
            ),
          ],
          const SizedBox(height: Space.sectionGap),
          header(
            l10n.staffLiveAttendeesTitle,
            AppIcons.people,
            Hue.green,
            action: detail.attendeeTotal == 0 ? null : formatFigure(detail.attendeeTotal),
          ),
          if (detail.attendees.isEmpty)
            AppCard(
              child: Text(
                l10n.staffLiveNoAttendees,
                style: context.type.bodyM.copyWith(color: c.muted),
              ),
            )
          else
            GroupedList(
              children: [
                for (final attendee in detail.attendees)
                  AppListTile(
                    title: attendee.name,
                    leading: AvatarInitials(name: attendee.name, size: AvatarSizes.sm),
                    // Attendance is the academy's to mark, and says no more than it knows: who
                    // joined the built-in room from the app (not how long the video service kept
                    // them), who held a place and never joined, and — at an outside meeting, which
                    // it cannot see — who opened the link.
                    subtitle: [
                      if (attendee.city.isNotEmpty) attendee.city,
                      if (attendee.joinedAt case final at?)
                        cls.isRoom
                            ? l10n.staffLiveJoinedAt(DatesIst.time(at))
                            : l10n.staffLiveOpenedLinkAt(DatesIst.time(at)),
                    ].join(' · ').ifEmptyNull,
                    trailing: switch (LiveAttendance.of(
                      attended: attendee.attended,
                      inRoom: cls.isRoom,
                    )) {
                      final record? => LiveAttendanceBadge(record),
                      null => null,
                    },
                  ),
              ],
            ),
          const SizedBox(height: Space.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppButton(
                label: l10n.actionPrevious,
                variant: AppButtonVariant.tertiary,
                onPressed: detail.previous == null
                    ? null
                    : () => GoRouter.of(context).go(AppRoutes.staffLiveClass(detail.previous!.id)),
              ),
              AppButton(
                label: l10n.actionNext,
                variant: AppButtonVariant.tertiary,
                onPressed: detail.next == null
                    ? null
                    : () => GoRouter.of(context).go(AppRoutes.staffLiveClass(detail.next!.id)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The head of the page: the class, where it stands now — scheduled, live, over or called off, on
/// a strip in that state's colour — and, under its facts, what can be done about it right now.
class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.detail,
    required this.phase,
    required this.actions,
    required this.note,
  });

  final StaffLiveDetail detail;
  final LivePhase phase;

  /// The actions the class's state allows now, already decided by the screen.
  final List<Widget> actions;

  /// When the room or link opens, if that is worth saying.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final cls = detail.liveClass;
    final strip = liveStripColors(context, phase);

    return AppCard(
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
                      detail.courseTitle,
                      style: type.caption.copyWith(color: strip.ink, fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: Space.s2),
                  StatusBadge(livePhaseKind(phase, cls)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(header: true, child: Text(cls.title, style: type.titleL)),
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
                  label: l10n.liveWithInstructor(detail.instructorName),
                ),
                if (cls.cancelReason case final reason? when reason.isNotEmpty) ...[
                  const SizedBox(height: Space.s3),
                  Text(
                    l10n.staffLiveCancelReason(reason),
                    style: type.bodyM.copyWith(color: c.dangerInk),
                  ),
                ],
                for (var i = 0; i < actions.length; i++) ...[
                  SizedBox(height: i == 0 ? Space.s4 : Space.s2),
                  actions[i],
                ],
                if (note case final note?) ...[
                  const SizedBox(height: Space.s3),
                  Text(note, style: type.caption.copyWith(color: c.muted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String? get ifEmptyNull => isEmpty ? null : this;
}
