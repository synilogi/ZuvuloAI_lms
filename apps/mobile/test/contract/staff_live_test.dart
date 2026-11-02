import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/staff_live/staff_live.dart';

/// Contract tests (§23) for the staff live screens, against what the real API returned.
Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

Map<String, dynamic> _map(String path) => _fixture(path)! as Map<String, dynamic>;

void main() {
  group('the academy\'s schedule', () {
    late StaffLivePage page;

    setUp(() => page = StaffLivePage.fromJson(_map('staff/live-schedule.json')));

    test('the counts cover the four views and add up to the whole schedule', () {
      expect(page.countOf('upcoming'), 1);
      expect(page.countOf('live'), 0);
      expect(page.countOf('history'), 7);
      expect(page.countOf('cancelled'), 12);
      expect(page.countOf('nonsense'), 0);
      expect(
        page.countOf('upcoming') +
            page.countOf('live') +
            page.countOf('history') +
            page.countOf('cancelled'),
        page.total,
      );
    });

    test('every row carries the class, its phase and whose it is', () {
      for (final row in page.rows) {
        expect(row.liveClass.id, isNotEmpty);
        expect(row.liveClass.title, isNotEmpty);
        expect(row.phase, isNot(LivePhase.unknown));
        expect(row.courseTitle, isNotEmpty);
        expect(row.instructorName, isNotEmpty);
        expect(row.liveClass.durationMin, greaterThan(0));
      }
    });

    test('a row falls in the view the route counted it under', () {
      final views = <String, int>{};
      for (final row in page.rows) {
        views[row.view] = (views[row.view] ?? 0) + 1;
      }
      for (final entry in views.entries) {
        expect(entry.value, page.countOf(entry.key), reason: entry.key);
      }
    });

    test('a cancelled class reads as cancelled whatever its times say', () {
      final cancelled = page.rows.where((r) => r.liveClass.cancelled);
      expect(cancelled, isNotEmpty);
      for (final row in cancelled) {
        expect(row.phase, LivePhase.cancelled);
        expect(row.view, 'cancelled');
      }
    });
  });

  group('one class in full', () {
    late StaffLiveDetail detail;

    setUp(() => detail = StaffLiveDetail.fromJson(_map('staff/live-class.json')));

    test('it carries the class, who teaches it, and where it happens', () {
      expect(detail.liveClass.title, 'Reading dignities in real charts');
      expect(detail.phase, LivePhase.upcoming);
      expect(detail.courseTitle, isNotEmpty);
      expect(detail.instructorName, 'Dr. Meenakshi Iyer');
      expect(detail.instructorTitle, isNotEmpty);
      expect(detail.liveClass.capacity, 40);
      expect(detail.liveClass.visibility, isNot(LiveVisibility.unknown));
      expect(detail.liveClass.meeting.kind, MeetingKind.room);
    });

    test('the agenda is the academy\'s, and fits inside the class', () {
      expect(detail.liveClass.agenda, hasLength(3));
      expect(detail.liveClass.agenda.first.title, isNotEmpty);
      expect(
        detail.liveClass.agendaMinutes,
        lessThanOrEqualTo(detail.liveClass.durationMin),
        reason: 'the academy keeps the agenda at or under the class length',
      );
    });

    test('who registered is named, and attendance is only what the academy marked', () {
      expect(detail.attendeeTotal, 1);
      expect(detail.attendees, hasLength(1));
      final attendee = detail.attendees.single;
      expect(attendee.id, isNotEmpty);
      expect(attendee.name, 'Ananya Rao');
      expect(attendee.city, isNotEmpty);
      expect(attendee.attended, isNull, reason: 'nothing is marked until the academy marks it');
      expect(detail.liveClass.registered, detail.attendeeTotal);
    });

    test('the reminders are the offsets the academy set', () {
      expect(detail.liveClass.reminders, [1440, 60]);
    });

    test('a neighbour in the same course is offered by id and title', () {
      expect(detail.previous!.id, isNotEmpty);
      expect(detail.previous!.title, isNotEmpty);
      expect(detail.previous!.startsAt!.isUtc, isTrue);
      expect(detail.next!.id, isNotEmpty);
    });

    test('an ended class carries its recording, and nothing to play it with', () {
      final ended = StaffLiveDetail.fromJson(_map('staff/live-class-ended.json'));

      expect(ended.phase, LivePhase.ended);
      expect(ended.liveClass.recording!.durationMin, 42);
      expect(ended.liveClass.recording!.availableUntil, isNotNull);
      // Finding 16: a recording has no address, so the app offers no player.
      expect(ended.recordingViews, isNull);
    });
  });

  group('the phase the app shows', () {
    // An outside meeting, which runs on the clock; the built-in room runs on its host (below).
    LiveClass classAt(DateTime start, {int durationMin = 60, bool cancelled = false}) => LiveClass(
      id: 'l1',
      courseId: 'c1',
      instructorId: 'i1',
      title: 'A class',
      startsAt: start,
      durationMin: durationMin,
      cancelled: cancelled,
      meeting: const LiveMeeting(kind: MeetingKind.external, link: 'https://meet.example.com/a'),
    );

    test('the built-in room is live only once its host starts it, as the academy rules', () {
      final at = DateTime.utc(2026, 9, 30, 12);
      final room = classAt(
        at.subtract(const Duration(minutes: 10)),
      ).copyWith(meeting: const LiveMeeting());
      expect(deriveLivePhase(room, at), LivePhase.startingSoon);
      expect(canStartRoom(room, at), isTrue);
      expect(deriveLivePhase(room.copyWith(startedAt: at), at), LivePhase.live);
      expect(
        deriveLivePhase(room.copyWith(startedAt: at, endedAt: at), at),
        LivePhase.recordingExpired,
      );
    });

    final now = DateTime.utc(2026, 9, 30, 12);

    test('follows the same rule as the academy, from its own timestamps', () {
      expect(deriveLivePhase(classAt(now.add(const Duration(hours: 2))), now), LivePhase.upcoming);
      expect(
        deriveLivePhase(classAt(now.add(const Duration(minutes: 10))), now),
        LivePhase.startingSoon,
        reason: 'the join window opens fifteen minutes ahead',
      );
      expect(
        deriveLivePhase(classAt(now.subtract(const Duration(minutes: 10))), now),
        LivePhase.live,
      );
      // A finished class with nothing to watch reads as `recording-expired`, which is the rule the
      // domain writes: `ended` means the recording is still there to see.
      expect(
        deriveLivePhase(classAt(now.subtract(const Duration(hours: 2))), now),
        LivePhase.recordingExpired,
      );
      expect(
        deriveLivePhase(
          classAt(now.subtract(const Duration(hours: 2))).copyWith(
            recording: LiveRecording(
              durationMin: 42,
              availableUntil: now.add(const Duration(days: 7)),
            ),
          ),
          now,
        ),
        LivePhase.ended,
      );
      expect(
        deriveLivePhase(
          classAt(now.subtract(const Duration(days: 40))).copyWith(
            recording: LiveRecording(
              durationMin: 42,
              availableUntil: now.subtract(const Duration(days: 1)),
            ),
          ),
          now,
        ),
        LivePhase.recordingExpired,
        reason: 'once the academy\'s window closes there is nothing left to watch',
      );
      expect(
        deriveLivePhase(classAt(now.add(const Duration(hours: 2)), cancelled: true), now),
        LivePhase.cancelled,
        reason: 'a cancelled class is cancelled whenever it was due',
      );
    });

    test('joining is offered only while the academy would allow it', () {
      expect(canJoinPhase(LivePhase.startingSoon), isTrue);
      expect(canJoinPhase(LivePhase.live), isTrue);
      expect(canJoinPhase(LivePhase.upcoming), isFalse);
      expect(canJoinPhase(LivePhase.ended), isFalse);
      expect(canJoinPhase(LivePhase.cancelled), isFalse);
    });

    test('a row and a detail read the clock the same way', () {
      final row = StaffLiveRow(liveClass: classAt(now.add(const Duration(minutes: 5))));
      final detail = StaffLiveDetail(liveClass: classAt(now.add(const Duration(minutes: 5))));

      expect(row.phaseAt(now), LivePhase.startingSoon);
      expect(detail.phaseAt(now), LivePhase.startingSoon);
    });
  });

  group('whether the academy would take an edit', () {
    final now = DateTime.utc(2026, 9, 30, 12);

    StaffLiveDetail detailFor({required DateTime start, bool cancelled = false}) => StaffLiveDetail(
      liveClass: LiveClass(
        id: 'l1',
        courseId: 'c1',
        instructorId: 'i1',
        title: 'A class',
        startsAt: start,
        durationMin: 60,
        cancelled: cancelled,
      ),
    );

    test('a class still to come may be edited', () {
      expect(detailFor(start: now.add(const Duration(hours: 1))).editableAt(now), isTrue);
    });

    test('one that has started, or was called off, may not', () {
      expect(detailFor(start: now.subtract(const Duration(minutes: 1))).editableAt(now), isFalse);
      expect(
        detailFor(start: now.add(const Duration(hours: 1)), cancelled: true).editableAt(now),
        isFalse,
      );
    });
  });

  group('the form a write sends', () {
    late LiveClassForm form;

    setUp(() {
      final detail = StaffLiveDetail.fromJson(_map('staff/live-class.json'));
      form = LiveClassForm.of(detail.liveClass);
    });

    test('an edit starts from the class exactly as it stands', () {
      expect(form.title, 'Reading dignities in real charts');
      expect(form.durationMin, greaterThan(0));
      expect(form.capacity, 40);
      expect(form.agenda, hasLength(3));
      expect(form.reminders, [1440, 60]);
      expect(form.meetingKind, MeetingKind.room);
    });

    test('it sends every field, because a PATCH takes the whole object', () {
      final body = form.toBody();

      expect(
        body.keys,
        containsAll(<String>[
          'courseId',
          'title',
          'instructorId',
          'startsAt',
          'durationMin',
          'description',
          'agenda',
          'visibility',
          'meeting',
          'reminders',
        ]),
      );
      expect(body['startsAt'], endsWith('Z'), reason: 'the route stores a UTC instant');
    });

    test('the meeting names `link`, which is the field the write path stores', () {
      final external = LiveClassForm.of(
        StaffLiveDetail.fromJson(_map('staff/live-class.json')).liveClass,
      ).copyWith(meetingKind: MeetingKind.external, meetingLink: 'https://meet.example.com/x');

      final meeting = external.toBody()['meeting']! as Map<String, Object?>;
      expect(meeting['kind'], 'external');
      expect(meeting['link'], 'https://meet.example.com/x');
      expect(
        meeting.containsKey('url'),
        isFalse,
        reason: 'the schema names url but the validator reads link (finding 15)',
      );
    });

    test('an academy room carries no link at all', () {
      final meeting = form.toBody()['meeting']! as Map<String, Object?>;
      expect(meeting['kind'], 'room');
      expect(meeting.containsKey('link'), isFalse);
    });

    test('a capacity, description or chapter left empty is sent as null, which clears it', () {
      // `PATCH /live/:id` keeps a field that is left out; only `null` clears it. An edit that empties
      // the capacity must not quietly keep the old limit.
      final body = form.copyWith(capacity: null, description: '   ', chapterId: null).toBody();
      expect(body.containsKey('capacity'), isTrue);
      expect(body['capacity'], isNull);
      expect(body.containsKey('description'), isTrue);
      expect(body['description'], isNull);
      expect(body.containsKey('chapterId'), isTrue);
      expect(body['chapterId'], isNull);
      // What is set is sent as it is.
      expect(form.toBody()['capacity'], 40);
      expect(form.toBody()['description'], startsWith('A live walkthrough'));
    });

    test('the start is an instant with the offset the route insists on', () {
      final start = DateTime.utc(2026, 11, 2, 4, 30);
      final sent = form.copyWith(startsAt: start.toLocal()).toBody()['startsAt']! as String;
      // The route's own pattern: a date-time with its offset (`Z` or `+05:30`), at most milliseconds.
      expect(
        RegExp(
          r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}(\.\d{1,3})?)?(Z|[+-]\d{2}:\d{2})$',
        ).hasMatch(sent),
        isTrue,
        reason: sent,
      );
      expect(DateTime.parse(sent), start);
    });
  });

  group('what the form checks before asking', () {
    final now = DateTime.utc(2026, 9, 30, 12);

    LiveClassForm ready() => LiveClassForm(
      courseId: 'c1',
      title: 'Reading dignities',
      instructorId: 'i1',
      startsAt: now.add(const Duration(hours: 1)),
      durationMin: 60,
      meetingLink: 'https://meet.example.com/x',
    );

    test('a complete class has nothing to fix', () {
      expect(liveFormProblems(ready(), now: now), isEmpty);
    });

    test('it names each field the academy\'s own validator would refuse', () {
      expect(liveFormProblems(ready().copyWith(title: 'Hi'), now: now), ['title']);
      expect(liveFormProblems(ready().copyWith(courseId: ''), now: now), ['course']);
      expect(liveFormProblems(ready().copyWith(instructorId: ''), now: now), ['instructor']);
      expect(
        liveFormProblems(
          ready().copyWith(startsAt: now.subtract(const Duration(minutes: 1))),
          now: now,
        ),
        ['startsAt'],
      );
      expect(liveFormProblems(ready().copyWith(durationMin: 10), now: now), ['duration']);
      expect(liveFormProblems(ready().copyWith(durationMin: 300), now: now), ['duration']);
      expect(
        liveFormProblems(
          ready().copyWith(meetingKind: MeetingKind.external, meetingLink: 'meet.example.com'),
          now: now,
        ),
        ['meeting'],
      );
      // The built-in room needs no link at all.
      expect(liveFormProblems(ready().copyWith(meetingLink: ''), now: now), isEmpty);
    });

    test('a capacity below what is already taken is refused, as the academy refuses it', () {
      expect(liveFormProblems(ready().copyWith(capacity: 3), now: now, registered: 5), [
        'capacity',
      ]);
      expect(liveFormProblems(ready().copyWith(capacity: 5), now: now, registered: 5), isEmpty);
      expect(liveFormProblems(ready().copyWith(capacity: 0), now: now), ['capacity']);
    });

    test('an agenda longer than the class is refused', () {
      final long = ready().copyWith(
        durationMin: 30,
        agenda: const [
          AgendaItem(title: 'One', minutes: 20),
          AgendaItem(title: 'Two', minutes: 20),
        ],
      );
      expect(liveFormProblems(long, now: now), ['agenda']);
    });

    test('an academy room needs no link', () {
      expect(
        liveFormProblems(
          ready().copyWith(meetingKind: MeetingKind.room, meetingLink: ''),
          now: now,
        ),
        isEmpty,
      );
    });
  });
}
