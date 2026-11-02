import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/live/live.dart';

/// Contract tests (§23) for the learner's live classes, against what the real API returned.
Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

void main() {
  late LiveSchedule schedule;

  setUp(
    () => schedule = LiveSchedule.fromJson(_fixture('live/learner.json')! as Map<String, dynamic>),
  );

  test('the schedule arrives in the academy\'s own three groups', () {
    expect(schedule.isEmpty, isFalse);
    expect(schedule.upcoming, isNotEmpty);
    expect(schedule.recordings, isNotEmpty);
    // Every row says which phase the server read, and every date is an instant, not local time.
    for (final row in schedule.all) {
      expect(row.phase, isNot(LivePhase.unknown));
      expect(row.liveClass.startsAt.isUtc, isTrue);
      expect(row.courseTitle, isNotEmpty);
      expect(row.instructorName, isNotEmpty);
    }
  });

  test('an upcoming class carries what it is, when, and what it covers', () {
    final row = schedule.upcoming.first;
    final cls = row.liveClass;

    expect(row.phase, LivePhase.upcoming);
    expect(cls.title, 'Reading dignities in real charts');
    expect(cls.durationMin, 60);
    expect(cls.capacity, 40);
    expect(cls.description, isNotNull);
    expect(cls.agenda.map((a) => a.title), ['Recap of dignity rules', 'Live chart reading', 'Q&A']);
    expect(cls.agendaMinutes, 60);
    expect(cls.reminders, [1440, 60]);
    expect(cls.visibility, LiveVisibility.enrolled);
    expect(row.registered, isFalse, reason: 'an upcoming row says whether this learner has a seat');
    expect(cls.endsAt, cls.startsAt.add(const Duration(minutes: 60)));
  });

  test('every seeded class is hosted in the academy\'s own room, which cannot be opened', () {
    for (final row in schedule.all) {
      expect(row.liveClass.meeting.kind, MeetingKind.room);
      expect(row.liveClass.meeting.joinable, isNull, reason: 'B12 — there is no link to open');
    }
  });

  test(
    'a recording says how long it runs and how long it stays, and no address to play it from',
    () {
      final row = schedule.recordings.first;
      final recording = row.liveClass.recording!;

      expect(row.phase, LivePhase.ended);
      expect(recording.durationMin, greaterThan(0));
      expect(recording.availableUntil, isNotNull);
      expect(recording.availableUntil!.isUtc, isTrue);
      // There is no address in the payload: a kept file plays from `/live/:id/recording` with the
      // learner's token, and this captured one predates the kept file, so it has no status to play.
      expect(recording.toJson().keys, ['durationMin', 'availableUntil', 'status']);
      expect(recording.status, isNull);
      expect(recording.playable, isFalse);
    },
  );

  test('the counts on a learner\'s own row are their own, not the class\'s', () {
    // `/live/learner` includes only this learner's registrations, so `registered` is 0 or 1 and
    // says nothing about how full the class is (finding 17).
    for (final row in schedule.all) {
      expect(row.liveClass.registered, lessThanOrEqualTo(1));
    }
  });

  test('one class is found by its id, wherever it sits', () {
    final wanted = schedule.recordings.last.liveClass.id;

    expect(schedule.rowFor(wanted)!.liveClass.id, wanted);
    expect(schedule.rowFor('nope'), isNull);
  });

  test('the register answer says whether a seat is held, and 999 means no limit', () {
    expect(LiveRegistration.fromJson(const {'registered': true, 'spotsLeft': 12}).spotsLeft, 12);
    expect(
      LiveRegistration.fromJson(const {'registered': true, 'spotsLeft': 999}).isUnlimited,
      isTrue,
    );
    expect(
      LiveRegistration.fromJson(const {'registered': false, 'spotsLeft': 0}).registered,
      isFalse,
    );
  });
}
