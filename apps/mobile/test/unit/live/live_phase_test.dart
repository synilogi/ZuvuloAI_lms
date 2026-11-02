import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/shared/domain/live_class.dart';

/// `deriveLiveClassPhase` (`packages/domain/src/live-class.ts`), ported. The cases below are the
/// boundaries the server reads the same way, so a screen that moves a class on by the clock can
/// never disagree with the answer it came with (§14).
LiveClass _class({
  required DateTime startsAt,
  int durationMin = 60,
  bool cancelled = false,
  DateTime? recordingUntil,
  MeetingKind kind = MeetingKind.external,
  DateTime? startedAt,
  DateTime? endedAt,
}) => LiveClass(
  id: 'l1',
  startsAt: startsAt,
  durationMin: durationMin,
  cancelled: cancelled,
  meeting: LiveMeeting(
    kind: kind,
    link: kind == MeetingKind.external ? 'https://meet.example.com/x' : null,
  ),
  startedAt: startedAt,
  endedAt: endedAt,
  recording: recordingUntil == null
      ? null
      : LiveRecording(durationMin: 58, availableUntil: recordingUntil),
);

void main() {
  final now = DateTime.utc(2026, 9, 29, 12);

  test('a class is upcoming until a quarter of an hour before it starts', () {
    expect(
      deriveLivePhase(_class(startsAt: now.add(const Duration(days: 2))), now),
      LivePhase.upcoming,
    );
    expect(
      deriveLivePhase(_class(startsAt: now.add(const Duration(minutes: 16))), now),
      LivePhase.upcoming,
    );
  });

  test('the join window opens exactly fifteen minutes before the start', () {
    expect(
      deriveLivePhase(_class(startsAt: now.add(joinWindow)), now),
      LivePhase.startingSoon,
      reason: 'the boundary itself is inside the window, as the server reads it',
    );
    expect(
      deriveLivePhase(_class(startsAt: now.add(const Duration(seconds: 1))), now),
      LivePhase.startingSoon,
    );
    expect(canJoinPhase(LivePhase.startingSoon), isTrue);
    expect(canJoinPhase(LivePhase.upcoming), isFalse);
  });

  test('the built-in room runs on its host: live from their start until their end', () {
    final room = _class(startsAt: now.subtract(const Duration(minutes: 5)), kind: MeetingKind.room);
    // In its slot, not opened: learners wait, and cannot go in.
    expect(deriveLivePhase(room, now), LivePhase.startingSoon);
    expect(canJoinPhase(LivePhase.startingSoon, room), isFalse);
    expect(room.waitingForHostAt(now), isTrue);
    expect(canStartRoom(room, now), isTrue);
    expect(
      canStartRoom(
        _class(startsAt: now.add(const Duration(hours: 1)), kind: MeetingKind.room),
        now,
      ),
      isFalse,
    );

    final started = room.copyWith(startedAt: now.subtract(const Duration(minutes: 1)));
    expect(deriveLivePhase(started, now), LivePhase.live);
    expect(canJoinPhase(LivePhase.live, started), isTrue);
    expect(started.waitingForHostAt(now), isFalse);
    // An overrun stays live for an hour past the slot.
    expect(deriveLivePhase(started, now.add(const Duration(minutes: 110))), LivePhase.live);
    expect(
      deriveLivePhase(started, now.add(const Duration(minutes: 116))),
      LivePhase.recordingExpired,
    );

    final ended = started.copyWith(endedAt: now);
    expect(deriveLivePhase(ended, now), LivePhase.recordingExpired);
    // Never opened, and the slot is over: missed.
    expect(deriveLivePhase(room, now.add(const Duration(hours: 1))), LivePhase.recordingExpired);
  });

  test('a class is live from its start until its end', () {
    expect(deriveLivePhase(_class(startsAt: now), now), LivePhase.live);
    expect(
      deriveLivePhase(_class(startsAt: now.subtract(const Duration(minutes: 59))), now),
      LivePhase.live,
    );
    expect(canJoinPhase(LivePhase.live), isTrue);
  });

  test('once it has ended it is a recording, or nothing to open at all', () {
    final ended = _class(startsAt: now.subtract(const Duration(hours: 2)));

    expect(deriveLivePhase(ended, now), LivePhase.recordingExpired, reason: 'no recording kept');
    expect(
      deriveLivePhase(
        _class(
          startsAt: now.subtract(const Duration(hours: 2)),
          recordingUntil: now.add(const Duration(days: 20)),
        ),
        now,
      ),
      LivePhase.ended,
    );
    expect(
      deriveLivePhase(
        _class(
          startsAt: now.subtract(const Duration(days: 40)),
          recordingUntil: now.subtract(const Duration(days: 1)),
        ),
        now,
      ),
      LivePhase.recordingExpired,
    );
    expect(canJoinPhase(LivePhase.ended), isFalse);
  });

  test('a cancelled class is cancelled whatever the clock says', () {
    expect(deriveLivePhase(_class(startsAt: now, cancelled: true), now), LivePhase.cancelled);
    expect(canJoinPhase(LivePhase.cancelled), isFalse);
  });

  group('the meeting link', () {
    LiveMeeting meeting(String? link, {MeetingKind kind = MeetingKind.external}) =>
        LiveMeeting(kind: kind, link: link);

    test('opens only over https', () {
      expect(
        meeting('https://meet.example.com/abc').joinable.toString(),
        'https://meet.example.com/abc',
      );
      expect(meeting('http://meet.example.com/abc').joinable, isNull);
      expect(meeting('javascript:alert(1)').joinable, isNull);
      expect(meeting('meet.example.com/abc').joinable, isNull);
      expect(meeting(null).joinable, isNull);
      expect(meeting('').joinable, isNull);
    });

    test("the academy's own room has nothing this app can open (B12)", () {
      expect(meeting('https://meet.example.com', kind: MeetingKind.room).joinable, isNull);
      expect(const LiveMeeting().joinable, isNull);
    });
  });

  test('a row reads its phase from the clock, not from the phase it arrived with', () {
    final row = LearnerLiveRow(
      liveClass: _class(startsAt: now.add(const Duration(minutes: 10))),
      // The server answered while it was still more than fifteen minutes away.
      phase: LivePhase.upcoming,
    );

    expect(row.phase, LivePhase.upcoming);
    expect(row.phaseAt(now), LivePhase.startingSoon);
  });
}
