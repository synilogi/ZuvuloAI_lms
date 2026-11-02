import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/staff_live/staff_live.dart';

/// The learner's side of an outside meeting, and the attendance record, as the API now sends them.
void main() {
  group('an outside meeting on a learner\'s payload', () {
    test('names the site it is on, and carries no link', () {
      final meeting = LiveMeeting.fromJson(const {'kind': 'external', 'linkHost': 'zoom.us'});

      expect(meeting.kind, MeetingKind.external);
      expect(meeting.link, isNull);
      expect(meeting.linkHost, 'zoom.us');
      expect(meeting.host, 'zoom.us');
      expect(meeting.joinable, isNull, reason: 'there is nothing to open until the academy says');
    });

    test('with no site named has none to show', () {
      expect(LiveMeeting.fromJson(const {'kind': 'external'}).host, isNull);
    });

    test('staff still read the link, and its site', () {
      final meeting = LiveMeeting.fromJson(const {
        'kind': 'external',
        'link': 'https://meet.example.com/dignities',
      });
      expect(meeting.joinable.toString(), 'https://meet.example.com/dignities');
      expect(meeting.host, 'meet.example.com');
    });

    test('the built-in room has no outside site at all', () {
      final room = LiveMeeting.fromJson(const {'kind': 'room', 'linkHost': 'zoom.us'});
      expect(room.host, isNull);
      expect(room.joinable, isNull);
    });

    test('a class reads the learner\'s shape whole', () {
      final cls = LiveClass.fromJson({
        'id': 'l1',
        'startsAt': '2026-10-01T05:28:42.246Z',
        'meeting': {'kind': 'external', 'linkHost': 'zoom.us'},
      });
      expect(cls.isRoom, isFalse);
      expect(cls.meeting.host, 'zoom.us');
    });
  });

  group('a link the app will open', () {
    test('is https with a host, and nothing else', () {
      expect(safeMeetingLink('https://zoom.us/j/1').toString(), 'https://zoom.us/j/1');
      expect(safeMeetingLink('  https://zoom.us/j/1 ').toString(), 'https://zoom.us/j/1');
      for (final bad in [
        null,
        '',
        'http://zoom.us/j/1',
        'javascript:alert(1)',
        'intent://scan/#Intent;scheme=zxing;end',
        'https:///no-host',
        'zoom.us/j/1',
      ]) {
        expect(safeMeetingLink(bad), isNull, reason: '$bad');
      }
    });

    test('never throws on a link a person mistyped', () {
      expect(() => safeMeetingLink('https://[::1'), returnsNormally);
      expect(safeMeetingLink('https://[::1'), isNull);
    });
  });

  group('attendance', () {
    test('is what the academy knows, and no more', () {
      expect(LiveAttendance.of(attended: true, inRoom: true), LiveAttendance.joined);
      expect(LiveAttendance.of(attended: false, inRoom: true), LiveAttendance.missed);
      expect(LiveAttendance.of(attended: true, inRoom: false), LiveAttendance.openedLink);
      expect(LiveAttendance.of(attended: false, inRoom: false), LiveAttendance.missed);
      expect(LiveAttendance.of(attended: null, inRoom: true), isNull);
      expect(LiveAttendance.of(attended: null, inRoom: false), isNull);
    });

    test('a learner\'s row and a staff attendee read true, false and nothing alike', () {
      final cls = {'id': 'l1', 'startsAt': '2026-10-01T05:28:42.246Z'};
      expect(LearnerLiveRow.fromJson({'liveClass': cls, 'attended': true}).attended, isTrue);
      expect(LearnerLiveRow.fromJson({'liveClass': cls, 'attended': false}).attended, isFalse);
      expect(LearnerLiveRow.fromJson({'liveClass': cls}).attended, isNull);
      expect(LearnerLiveRow.fromJson({'liveClass': cls, 'attended': null}).attended, isNull);

      final opened = LiveAttendee.fromJson(const {
        'id': 's1',
        'name': 'Ananya Rao',
        'joinedAt': '2026-10-01T05:30:00.000Z',
      });
      expect(opened.attended, isNull);
      expect(opened.joinedAt, DateTime.utc(2026, 10, 1, 5, 30));
      expect(LiveAttendee.fromJson(const {'id': 's1', 'attended': null}).attended, isNull);
      expect(LiveAttendee.fromJson(const {'id': 's1', 'attended': true}).attended, isTrue);
    });
  });

  group('the schedule', () {
    test('with only classes that are over is not empty', () {
      final schedule = LiveSchedule.fromJson({
        'live': <Object>[],
        'upcoming': <Object>[],
        'recordings': <Object>[],
        'history': [
          {
            'liveClass': {'id': 'l1', 'startsAt': '2026-09-01T05:00:00.000Z'},
            'phase': 'recording-expired',
            'attended': true,
          },
        ],
      });
      expect(schedule.isEmpty, isFalse);
      expect(schedule.rowFor('l1')?.attended, isTrue);
    });
  });

  group('when the host may start the built-in room', () {
    final start = DateTime.utc(2026, 10, 1, 10);

    StaffLiveDetail detail({
      bool? serverCanStart,
      Map<String, Object?> meeting = const {'kind': 'room'},
      bool cancelled = false,
      DateTime? startedAt,
      DateTime? endedAt,
    }) => StaffLiveDetail.fromJson({
      'liveClass': {
        'id': 'l1',
        'startsAt': start.toIso8601String(),
        'durationMin': 60,
        'meeting': meeting,
        'cancelled': cancelled,
        if (startedAt != null) 'startedAt': startedAt.toIso8601String(),
        if (endedAt != null) 'endedAt': endedAt.toIso8601String(),
      },
      if (serverCanStart != null) 'room': {'canStart': serverCanStart},
    });

    test('opens on the clock at the quarter hour, whatever the academy said earlier', () {
      // The page was read an hour ahead: the academy said no, because it was too early.
      final early = detail(serverCanStart: false);
      expect(early.canStartAt(start.subtract(const Duration(hours: 1))), isFalse);
      expect(early.canStartAt(start.subtract(const Duration(minutes: 16))), isFalse);
      expect(early.canStartAt(start.subtract(const Duration(minutes: 15))), isTrue);
      expect(early.canStartAt(start.add(const Duration(minutes: 59))), isTrue);
      // And closes at the scheduled end, as the academy's own rule does.
      expect(early.canStartAt(start.add(const Duration(minutes: 60))), isFalse);
    });

    test('never for what the academy already knows is over or elsewhere', () {
      final inWindow = start.subtract(const Duration(minutes: 5));
      expect(detail(serverCanStart: true, cancelled: true).canStartAt(inWindow), isFalse);
      expect(
        detail(serverCanStart: true, startedAt: inWindow).canStartAt(inWindow),
        isFalse,
        reason: 'started: it is rejoined, not started',
      );
      expect(detail(serverCanStart: true, endedAt: inWindow).canStartAt(inWindow), isFalse);
      expect(
        detail(
          serverCanStart: true,
          meeting: const {'kind': 'external', 'link': 'https://zoom.us/j/1'},
        ).canStartAt(inWindow),
        isFalse,
      );
    });

    test('a phone whose clock runs behind keeps the academy\'s yes until the scheduled end', () {
      final yes = detail(serverCanStart: true);
      // The phone thinks it is 20 minutes before the start; the academy said the room may open.
      expect(yes.canStartAt(start.subtract(const Duration(minutes: 20))), isTrue);
      expect(yes.canStartAt(start.add(const Duration(minutes: 61))), isFalse);
    });

    test('with no answer from the academy, the clock alone decides', () {
      final unknown = detail();
      expect(unknown.canStartAt(start.subtract(const Duration(minutes: 20))), isFalse);
      expect(unknown.canStartAt(start.subtract(const Duration(minutes: 10))), isTrue);
    });
  });
}
