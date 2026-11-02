import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/platform/clock.dart';
import '../../../core/platform/external_link.dart';
import '../../../core/platform/live_room.dart';
import '../../../shared/domain/live_class.dart';
import '../data/live_api.dart';

/// The live-class models the screens read (§14, §26).
export '../../../shared/domain/live_class.dart';

/// The learner's schedule, in the academy's own three groups.
final liveScheduleProvider = FutureProvider<LiveSchedule>(
  (ref) => ref.watch(liveApiProvider).schedule(),
  isAutoDispose: true,
);

/// How often a live screen reads the clock again. A phase turns on time — Join opens fifteen
/// minutes before the start — without asking the server again (§14).
const livePhaseTick = Duration(seconds: 30);

/// The clock the live screens derive phases from. Auto-disposed, so it ticks only while one of
/// them is on screen.
final liveClockProvider = StreamProvider<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock();
  yield* Stream<DateTime>.periodic(livePhaseTick, (_) => clock());
}, isAutoDispose: true);

/// What a registration attempt left behind: the academy's own answer, or its refusal.
@immutable
class LiveRegistrationState {
  const LiveRegistrationState({this.busyFor, this.seats = const {}, this.failure});

  /// The class whose seat is being taken or given up.
  final String? busyFor;

  /// What the academy answered for each class it was asked about, by class id.
  final Map<String, LiveRegistration> seats;

  final AppFailure? failure;

  bool get busy => busyFor != null;

  /// Whether this learner holds a seat: the academy's last answer, else what the row arrived with.
  bool registeredFor(LearnerLiveRow row) => seats[row.liveClass.id]?.registered ?? row.registered;

  /// Seats left, but only where the academy has said — a learner's own row cannot be counted from
  /// (finding 17), and 999 means the class has no limit at all.
  int? spotsLeftFor(String liveClassId) {
    final seat = seats[liveClassId];
    if (seat == null || seat.isUnlimited) return null;
    return seat.spotsLeft;
  }
}

/// Taking and giving up a seat. The academy decides; the app only asks and shows the answer.
class LiveRegistrationController extends Notifier<LiveRegistrationState> {
  @override
  LiveRegistrationState build() => const LiveRegistrationState();

  /// Asks for a seat ([registered] true) or to give it up (false) — the learner's wish, not a flip,
  /// so a retry lands where they meant. One request at a time.
  Future<bool> setRegistered(String liveClassId, {required bool registered}) async {
    if (state.busy) return false;
    state = LiveRegistrationState(busyFor: liveClassId, seats: state.seats);
    try {
      final seat = await ref.read(liveApiProvider).register(liveClassId, registered: registered);
      // The screen that asked may have gone; there is nothing left to tell.
      if (!ref.mounted) return true;
      state = LiveRegistrationState(seats: {...state.seats, liveClassId: seat});
      // The schedule carries the registered flag, so it is read again.
      ref.invalidate(liveScheduleProvider);
      return true;
    } on ApiException catch (e) {
      if (!ref.mounted) return false;
      state = LiveRegistrationState(seats: state.seats, failure: e.failure);
      return false;
    }
  }

  void clearFailure() => state = LiveRegistrationState(seats: state.seats);
}

final liveRegistrationProvider =
    NotifierProvider<LiveRegistrationController, LiveRegistrationState>(
      LiveRegistrationController.new,
      isAutoDispose: true,
    );

/// Why going in did not work, when the academy itself did not refuse.
enum LiveJoinProblem {
  /// The academy let the learner in, but this phone could not open the room.
  roomFailed,

  /// The academy's answer held no https link to open (§13).
  linkUnusable,

  /// Nothing on this phone could open the meeting's link.
  linkNotOpened,

  /// The room closed on an error from the video service — the connection dropped, or the class
  /// ended under the learner.
  connectionLost,
}

/// What a join attempt left behind: which class is being opened, and the academy's refusal or the
/// phone's own problem, if any.
@immutable
class LiveJoinState {
  const LiveJoinState({this.busyFor, this.failure, this.problem});

  final String? busyFor;
  final AppFailure? failure;
  final LiveJoinProblem? problem;

  /// The academy let the learner in, but this phone could not open the room.
  bool get roomFailed => problem == LiveJoinProblem.roomFailed;

  bool get busy => busyFor != null;
}

/// Asks the learner whether to leave for [host] — the site the academy's link actually points at,
/// when it is not the one they were told about. True to go on.
typedef ConfirmMeetingHost = Future<bool> Function(String host);

/// Going into a class. The academy decides; the app opens what it answers with — the built-in room in
/// the Jitsi SDK (which the academy records as joined), or an outside meeting's link in the browser
/// (handed out only by this answer) — and reads the schedule again once the learner is back.
class LiveJoinController extends Notifier<LiveJoinState> {
  @override
  LiveJoinState build() => const LiveJoinState();

  /// [expectedHost] is the site the learner agreed to leave for. Should the academy's link point
  /// somewhere else (the class was edited meanwhile), [confirmHost] asks again before it opens.
  Future<bool> join(
    String liveClassId, {
    String? expectedHost,
    ConfirmMeetingHost? confirmHost,
  }) async {
    if (state.busy) return false;
    state = LiveJoinState(busyFor: liveClassId);
    try {
      final answer = await ref.read(liveApiProvider).join(liveClassId);
      // Gone from the screen while asking: nothing opens behind the learner's back.
      if (!ref.mounted) return false;
      final room = answer.room;
      if (answer.kind == MeetingKind.room && room != null) {
        await ref.read(openLiveRoomProvider)(
          room,
          onClosed: ({connectionLost = false}) {
            if (!ref.mounted) return;
            ref.invalidate(liveScheduleProvider);
            if (connectionLost) {
              state = const LiveJoinState(problem: LiveJoinProblem.connectionLost);
            }
          },
        );
      } else {
        final link = answer.kind == MeetingKind.external ? safeMeetingLink(answer.link) : null;
        if (link == null) {
          state = const LiveJoinState(problem: LiveJoinProblem.linkUnusable);
          return false;
        }
        final expected = expectedHost?.toLowerCase();
        if (expected != null && link.host.toLowerCase() != expected) {
          final go = confirmHost != null && await confirmHost(link.host);
          if (!ref.mounted) return false;
          if (!go) {
            state = const LiveJoinState();
            ref.invalidate(liveScheduleProvider);
            return false;
          }
        }
        final opened = await openedExternally(ref.read(openExternalLinkProvider), link);
        if (!ref.mounted) return opened;
        if (!opened) {
          state = const LiveJoinState(problem: LiveJoinProblem.linkNotOpened);
          return false;
        }
      }
      if (!ref.mounted) return true;
      // The room may already have closed, and said how.
      if (state.busyFor == liveClassId) state = const LiveJoinState();
      ref.invalidate(liveScheduleProvider);
      return true;
    } on ApiException catch (e) {
      if (!ref.mounted) return false;
      state = LiveJoinState(failure: e.failure);
      // A refusal often means the class moved on (the host has not started, or has ended it).
      ref.invalidate(liveScheduleProvider);
      return false;
    } on LiveRoomUnavailable {
      if (!ref.mounted) return false;
      state = const LiveJoinState(problem: LiveJoinProblem.roomFailed);
      return false;
    }
  }

  void clearFailure() => state = const LiveJoinState();
}

final liveJoinProvider = NotifierProvider<LiveJoinController, LiveJoinState>(
  LiveJoinController.new,
  isAutoDispose: true,
);

/// How often a screen reads the schedule again while a built-in room is waiting for its host or
/// in session: Join appears when the host opens the room, and goes when the host ends the class —
/// the clock alone cannot know a class was ended early — without a pull to refresh.
const hostWaitPoll = Duration(seconds: 15);

/// Where a kept recording plays from (`GET /live/:id/recording`), for the player to open with the
/// learner's own token.
String liveRecordingPath(String liveClassId) => LiveApi.recordingPath(liveClassId);
