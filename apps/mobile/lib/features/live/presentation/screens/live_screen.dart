import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/live_controller.dart';
import '../widgets/live_parts.dart';

/// `/live` — the learner's schedule in the academy's own three groups: live now, upcoming, and
/// the classes that have a recording. A shell body.
///
/// The phase is read off the clock every 30 s, so a class moves from upcoming to starting soon —
/// and Join opens — without asking the server again (§14).
class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final value = ref.watch(liveScheduleProvider);
    // The screen reads itself again while a room waits for its host or is in session. A read that
    // fails then keeps the last schedule on screen and says so; only a first read draws the error.
    final stale = value.hasError;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(liveScheduleProvider.future),
      child: AsyncView<LiveSchedule>(
        value: value,
        keepDataOnError: true,
        onRetry: () => ref.invalidate(liveScheduleProvider),
        data: (schedule) => schedule.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (stale)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, 0),
                      child: LiveRefreshNote(),
                    ),
                  SizedBox(
                    height: 360,
                    child: EmptyState(title: l10n.liveEmptyTitle, message: l10n.liveEmptyBody),
                  ),
                ],
              )
            : _Schedule(schedule: schedule, stale: stale),
      ),
    );
  }
}

class _Schedule extends ConsumerWidget {
  const _Schedule({required this.schedule, required this.stale});

  final LiveSchedule schedule;

  /// The last read failed, so this is the schedule as it was.
  final bool stale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final now = ref.watch(liveClockProvider).value ?? DateTime.now().toUtc();
    final seats = ref.watch(liveRegistrationProvider);

    listenForRegistrationFailures(context, ref);
    listenForJoinFailures(context, ref);

    void open(String liveId) => GoRouter.of(context).go(AppRoutes.liveClass(liveId));

    // A class that has started moves itself out of "upcoming" as the clock passes it.
    final live = [
      ...schedule.live,
      ...schedule.upcoming.where((r) => r.phaseAt(now) == LivePhase.live),
    ];
    final upcoming = schedule.upcoming.where((r) => r.phaseAt(now) != LivePhase.live).toList();
    final waiting = upcoming.any((r) => r.liveClass.waitingForHostAt(now));
    // A room in session can be ended early by its host; only the server knows when.
    final inSession = live.any((r) => r.liveClass.isRoom);

    return HostWaitPoller(
      active: waiting || inSession,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s6),
        children: [
          if (stale) const LiveRefreshNote(),
          if (live.isNotEmpty) ...[
            SectionHeader(
              title: l10n.liveTabLiveNow,
              icon: AppIcons.live,
              iconColor: context.colors.danger,
            ),
            for (final row in live) ...[
              LiveClassCard(
                row: row,
                now: now,
                registered: seats.registeredFor(row),
                onOpen: () => open(row.liveClass.id),
                trailing: LiveAction(row: row, now: now),
              ),
              const SizedBox(height: Space.s3),
            ],
            const SizedBox(height: Space.s2),
          ],
          if (upcoming.isNotEmpty) ...[
            SectionHeader(
              title: l10n.liveTabUpcoming,
              icon: AppIcons.date,
              iconColor: context.colors.hue(Hue.blue).solid,
            ),
            for (final row in upcoming) ...[
              LiveClassCard(
                row: row,
                now: now,
                registered: seats.registeredFor(row),
                onOpen: () => open(row.liveClass.id),
                trailing: LiveAction(row: row, now: now),
              ),
              const SizedBox(height: Space.s3),
            ],
            const SizedBox(height: Space.s2),
          ],
          if (schedule.recordings.isNotEmpty) ...[
            SectionHeader(
              title: l10n.liveTabRecordings,
              icon: AppIcons.play,
              iconColor: context.colors.hue(Hue.pink).solid,
            ),
            for (final row in schedule.recordings) ...[
              LiveClassCard(row: row, now: now, onOpen: () => open(row.liveClass.id)),
              const SizedBox(height: Space.s3),
            ],
            const SizedBox(height: Space.s2),
          ],
          if (schedule.history.isNotEmpty) ...[
            SectionHeader(
              title: l10n.liveAttendanceTitle,
              icon: AppIcons.check,
              iconColor: context.colors.hue(Hue.green).solid,
            ),
            for (final row in schedule.history) ...[
              LiveClassCard(
                row: row,
                now: now,
                onOpen: () => open(row.liveClass.id),
                // No record, no claim: a place held at an outside meeting has nothing to show.
                trailing: row.attended == null
                    ? null
                    : Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: AttendanceBadge(
                          attended: row.attended,
                          inRoom: row.liveClass.isRoom,
                        ),
                      ),
              ),
              const SizedBox(height: Space.s3),
            ],
          ],
        ],
      ),
    );
  }
}

/// Whether this screen is the one in front. The shell keeps every tab alive behind the one shown
/// (Home and Live both offer Join), and only the one in front speaks — once.
bool _inFront(BuildContext context) => TickerMode.of(context);

/// Says once, in the academy's own words, why a learner could not go in — or what this phone could
/// not do once they were let in.
void listenForJoinFailures(BuildContext context, WidgetRef ref) {
  final inFront = _inFront(context);
  ref.listen(liveJoinProvider, (previous, next) {
    if (!inFront) return;
    final l10n = context.l10n;
    final problem = next.problem;
    if (problem != null && problem != previous?.problem) {
      showAppSnackbar(context, switch (problem) {
        LiveJoinProblem.roomFailed => l10n.liveRoomUnavailable,
        LiveJoinProblem.linkUnusable => l10n.liveLinkUnusable,
        LiveJoinProblem.linkNotOpened => l10n.liveLinkNotOpened,
        LiveJoinProblem.connectionLost => l10n.liveConnectionLost,
      }, tone: SnackTone.error);
      ref.read(liveJoinProvider.notifier).clearFailure();
      return;
    }
    final failure = next.failure;
    if (failure == null || failure == previous?.failure) return;
    showAppSnackbar(context, failure.message ?? l10n.stateErrorBody, tone: SnackTone.error);
    ref.read(liveJoinProvider.notifier).clearFailure();
  });
}

/// Says once, in the academy's own words, why a seat was not taken or given up.
void listenForRegistrationFailures(BuildContext context, WidgetRef ref) {
  final inFront = _inFront(context);
  ref.listen(liveRegistrationProvider, (previous, next) {
    if (!inFront) return;
    final failure = next.failure;
    if (failure == null || failure == previous?.failure) return;
    showAppSnackbar(context, failure.message ?? context.l10n.stateErrorBody, tone: SnackTone.error);
    ref.read(liveRegistrationProvider.notifier).clearFailure();
  });
}

/// The one class a learner should know about first: one that is live now, else the next to start.
/// The schedule's own order decides between equals; the clock only moves a class that has begun
/// out of "upcoming", as the schedule page does.
LearnerLiveRow? nextLiveClass(LiveSchedule schedule, DateTime now) =>
    schedule.live.firstOrNull ??
    schedule.upcoming.where((r) => r.phaseAt(now) == LivePhase.live).firstOrNull ??
    // Never a cancelled or finished one: "next" is only ever a class that is still ahead.
    schedule.upcoming
        .where((r) => const {LivePhase.upcoming, LivePhase.startingSoon}.contains(r.phaseAt(now)))
        .firstOrNull;

/// What a class offers right now: the way in once the room opens, a seat while it is still ahead,
/// and nothing at all once it is over.
class LiveAction extends StatelessWidget {
  const LiveAction({required this.row, required this.now, super.key, this.showJoinNote = false});

  final LearnerLiveRow row;
  final DateTime now;

  /// Says when the room opens, for a class that has a link but is not there yet.
  final bool showJoinNote;

  @override
  Widget build(BuildContext context) {
    final phase = row.phaseAt(now);
    final cls = row.liveClass;
    if (canJoinPhase(phase, cls)) return JoinButton(row: row, now: now);
    // In the window, but the host hasn't opened the room: the learner waits here, and may still take
    // a place. The screen asks again every few seconds, so Join appears on its own.
    if (cls.waitingForHostAt(now)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.liveWaitingForHost(row.instructorName),
            style: context.type.bodyS.copyWith(color: context.colors.muted),
          ),
          const SizedBox(height: Space.s2),
          RegisterButton(row: row),
        ],
      );
    }
    if (phase != LivePhase.upcoming) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegisterButton(row: row),
        if (showJoinNote) ...[
          const SizedBox(height: Space.s2),
          Text(
            context.l10n.liveJoinOpensNote,
            style: context.type.caption.copyWith(color: context.colors.muted),
          ),
        ],
      ],
    );
  }
}

/// Taking or giving up a seat. The button asks for what it says — a seat, or to give it up — and is
/// off while any seat request is out. The academy answers with how many are left, and that answer is
/// the only place a seat count comes from (finding 17).
class RegisterButton extends ConsumerWidget {
  const RegisterButton({required this.row, super.key});

  final LearnerLiveRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final seats = ref.watch(liveRegistrationProvider);
    final offline = ref.watch(isOnlineProvider).value == false;
    final registered = seats.registeredFor(row);
    final left = seats.spotsLeftFor(row.liveClass.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: registered ? l10n.liveUnregisterAction : l10n.liveRegisterAction,
          variant: registered ? AppButtonVariant.secondary : AppButtonVariant.primary,
          busy: seats.busyFor == row.liveClass.id,
          onPressed: offline || seats.busy
              ? null
              : () => ref
                    .read(liveRegistrationProvider.notifier)
                    .setRegistered(row.liveClass.id, registered: !registered),
        ),
        if (left != null) ...[
          const SizedBox(height: Space.s1),
          Text(
            l10n.liveSpotsLeft(left),
            style: context.type.caption.copyWith(color: context.colors.muted),
          ),
        ],
      ],
    );
  }
}

/// Joining. The built-in room opens inside the app; an outside meeting opens in the browser, only
/// over https, after naming the site it is on (§13, §18, B12). Either way the academy is asked first:
/// it refuses if the class is not on, and only its answer carries an outside meeting's link — a
/// learner's schedule names the site ([LiveMeeting.host]) and nothing more.
class JoinButton extends ConsumerWidget {
  const JoinButton({required this.row, required this.now, super.key});

  final LearnerLiveRow row;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cls = row.liveClass;
    final joining = ref.watch(liveJoinProvider);
    final offline = ref.watch(isOnlineProvider).value == false;
    final host = cls.meeting.host;
    // An outside meeting whose site the academy could not name has no link worth opening.
    if (!cls.isRoom && host == null) {
      return Text(
        l10n.liveRoomUnavailable,
        style: context.type.bodyS.copyWith(color: context.colors.muted),
      );
    }
    final open = canJoinPhase(row.phaseAt(now), cls);
    return AppButton(
      label: l10n.liveJoinAction,
      icon: cls.isRoom ? AppIcons.live : AppIcons.external,
      busy: joining.busyFor == cls.id,
      onPressed: open && !offline && !joining.busy ? () => _join(context, ref, host) : null,
    );
  }

  Future<void> _join(BuildContext context, WidgetRef ref, String? host) async {
    final l10n = context.l10n;
    Future<bool> confirm(String message) async =>
        await showDialog<bool>(
          context: context,
          builder: (_) => AppDialog(
            title: l10n.liveJoinConfirmTitle,
            message: message,
            confirmLabel: l10n.liveJoinAction,
          ),
        ) ==
        true;

    if (host != null && !await confirm(l10n.liveJoinConfirmBody(host))) return;
    if (!context.mounted) return;
    Future<bool> join() => ref
        .read(liveJoinProvider.notifier)
        .join(
          row.liveClass.id,
          expectedHost: host,
          // The link the academy hands over is on another site than the one just named: ask again.
          confirmHost: (other) async =>
              context.mounted && await confirm(l10n.liveJoinOtherHostBody(other)),
        );
    // The built-in room opens on black, the way the call itself looks; an outside meeting opens in the browser.
    if (row.liveClass.isRoom) {
      await withLiveRoomJoining(context, join);
    } else {
      await join();
    }
  }
}
