import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/staff_calendar/staff_calendar.dart';
import 'package:syniastrolms_mobile/shared/domain/live_class.dart';

/// Contract tests (§23) for the staff calendar, against what the real API returned.
Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

Map<String, dynamic> _map(String path) => _fixture(path)! as Map<String, dynamic>;

void main() {
  group('a month of the calendar', () {
    late CalendarPage page;

    setUp(() => page = CalendarPage.fromJson(_map('staff/calendar-month.json')));

    test('the counts cover every type and add up to the whole range', () {
      expect(page.countOf(CalendarEventType.live), 15);
      expect(page.countOf(CalendarEventType.assignment), 1);
      expect(page.countOf(CalendarEventType.quiz), 1);
      expect(page.countOf(CalendarEventType.milestone), 1);
      expect(page.countOf(CalendarEventType.reminder), 2);
      expect(
        CalendarEventType.values
            .where((t) => t != CalendarEventType.unknown)
            .fold<int>(0, (n, t) => n + page.countOf(t)),
        page.total,
      );
      expect(page.rows, hasLength(page.total));
    });

    test('every row carries an event the app can read', () {
      for (final row in page.rows) {
        expect(row.event.id, isNotEmpty);
        expect(row.event.type, isNot(CalendarEventType.unknown));
        expect(row.event.timing, isNot(CalendarTiming.unknown));
        expect(row.event.title, isNotEmpty);
        expect(row.event.startsAt.isUtc, isTrue);
      }
    });

    test('a live row is derived, carries its phase, and points at its own record', () {
      final live = page.rows.where((r) => r.event.type == CalendarEventType.live);
      expect(live, isNotEmpty);
      for (final row in live) {
        expect(row.event.id, startsWith('live-'));
        expect(row.event.isDerived, isTrue);
        expect(row.event.source!.kind, 'live-class');
        expect(row.event.source!.id, isNotEmpty);
        expect(row.phase, isNot(LivePhase.unknown));
        expect(row.event.timing, CalendarTiming.timed);
        expect(row.courseTitle, isNotNull);
      }
    });

    test('a deadline row is derived too, and says how many have handed in', () {
      final deadline = page.rows.singleWhere((r) => r.event.type == CalendarEventType.assignment);

      expect(deadline.event.id, startsWith('assignment-'));
      expect(deadline.event.isDerived, isTrue);
      expect(deadline.event.source!.kind, 'assignment');
      expect(deadline.event.timing, CalendarTiming.moment);
      expect(deadline.due!.learners, greaterThan(0));
      expect(deadline.due!.submitted, 0);
      expect(deadline.due!.outstanding, deadline.due!.learners);
    });

    test('the calendar\'s own events are not derived', () {
      final own = page.rows.where(
        (r) =>
            r.event.type != CalendarEventType.live && r.event.type != CalendarEventType.assignment,
      );
      expect(own, isNotEmpty);
      for (final row in own) {
        expect(row.event.isDerived, isFalse);
        expect(row.event.ownerId, isNotNull, reason: 'it belongs to whoever set it');
      }
    });

    test('an event is filed under the IST day it falls on', () {
      final milestone = page.rows.singleWhere((r) => r.event.type == CalendarEventType.milestone);

      // Stored as midnight UTC on the 12th, which is 05:30 IST on the 12th.
      expect(milestone.event.timing, CalendarTiming.allDay);
      expect(milestone.event.istDay, DateTime.utc(2026, 10, 12));
      expect(
        page.on(DateTime.utc(2026, 10, 12)).map((r) => r.event.id),
        contains(milestone.event.id),
      );
      expect(page.busyDays, contains(DateTime.utc(2026, 10, 12)));
    });

    test('a day with nothing on it is empty, not missing', () {
      // Every busy day has rows; a day outside them has none.
      for (final day in page.busyDays) {
        expect(page.on(day), isNotEmpty);
      }
      expect(page.on(DateTime.utc(2020)), isEmpty);
    });
  });

  group('a reminder in full', () {
    late CalendarDetail detail;

    setUp(() => detail = CalendarDetail.fromJson(_map('staff/calendar-reminder.json')));

    test('it belongs to whoever set it, and they may change it', () {
      expect(detail.event.type, CalendarEventType.reminder);
      expect(detail.event.audience, ReminderAudience.me);
      expect(detail.event.ownerId, isNotEmpty);
      expect(detail.event.notifyMin, 60);
      expect(detail.event.durationMin, 30);
      expect(detail.event.done, isFalse);
      expect(detail.editable, isTrue);
      // A private reminder reaches nobody else, so there is no audience to count.
      expect(detail.audienceSize, isNull);
      expect(detail.courseTitle, isNull);
    });
  });

  group('a quiz window in full', () {
    late CalendarDetail detail;

    setUp(() => detail = CalendarDetail.fromJson(_map('staff/calendar-quiz-event.json')));

    test('it names the quiz learners take, and how many they are', () {
      expect(detail.event.type, CalendarEventType.quiz);
      expect(detail.event.timing, CalendarTiming.moment);
      expect(detail.event.quizId, isNotEmpty);
      expect(detail.courseTitle, isNotEmpty);
      expect(detail.audienceSize, 17);
      expect(detail.editable, isTrue);
      final quiz = detail.quiz!;
      expect(quiz.title, isNotEmpty);
      expect(quiz.status, 'published');
      expect(quiz.questions, 3);
      expect(quiz.passMark, 70);
      expect(quiz.attempts, 3);
      expect(quiz.timeLimitMin, isNull, reason: 'this quiz has no limit');
    });
  });

  group('a live class read through the calendar', () {
    late CalendarDetail detail;

    setUp(() => detail = CalendarDetail.fromJson(_map('staff/calendar-live.json')));

    test('it is not the calendar\'s to change, and says where it lives', () {
      expect(detail.event.type, CalendarEventType.live);
      expect(detail.editable, isFalse);
      expect(detail.event.source!.kind, 'live-class');
      expect(detail.event.source!.id, isNotEmpty);
      expect(detail.phase, LivePhase.upcoming);
      expect(detail.instructorName, isNotEmpty);
      expect(detail.instructorTitle, isNotEmpty);
      expect(detail.live!.capacity, 40);
      expect(detail.audienceSize, 17);
    });
  });

  group('a deadline read through the calendar', () {
    late CalendarDetail detail;

    setUp(() => detail = CalendarDetail.fromJson(_map('staff/calendar-assignment.json')));

    test('it is not the calendar\'s to change, and names who still owes it', () {
      expect(detail.event.type, CalendarEventType.assignment);
      expect(detail.editable, isFalse);
      expect(detail.event.source!.kind, 'assignment');
      expect(detail.due!.learners, 17);
      expect(detail.due!.submitted, 0);
      expect(detail.learnersDue, isNotEmpty);
      expect(detail.learnersDue.length, lessThanOrEqualTo(8));
      // Those who still owe it come first.
      expect(detail.learnersDue.first.submitted, isFalse);
      for (final learner in detail.learnersDue) {
        expect(learner.id, isNotEmpty);
        expect(learner.name, isNotEmpty);
      }
    });
  });

  group('the body a write sends', () {
    test('an edit starts from the event exactly as it stands', () {
      final detail = CalendarDetail.fromJson(_map('staff/calendar-reminder.json'));
      final form = CalendarEventForm.of(detail.event);

      expect(form.type, CalendarEventType.reminder);
      expect(form.title, detail.event.title);
      expect(form.timing, CalendarTiming.timed);
      expect(form.durationMin, 30);
      expect(form.audience, ReminderAudience.me);
      expect(form.notifyMin, 60);
    });

    test('a timed event sends its length; a moment and an all-day one do not', () {
      final timed = CalendarEventForm(
        title: 'A reminder',
        startsAt: DateTime.utc(2026, 10, 8, 9, 30),
        durationMin: 45,
      );
      expect(timed.toInput()['durationMin'], 45);
      expect(
        timed.copyWith(timing: CalendarTiming.moment).toInput().containsKey('durationMin'),
        isFalse,
      );
      expect(
        timed.copyWith(timing: CalendarTiming.allDay).toInput().containsKey('durationMin'),
        isFalse,
      );
    });

    test('an all-day event sends the route\'s own hyphenated word', () {
      final form = CalendarEventForm(
        title: 'A milestone',
        timing: CalendarTiming.allDay,
        startsAt: DateTime.utc(2026, 10, 12),
      );

      expect(form.toInput()['timing'], 'all-day');
    });

    test('a milestone kind travels hyphenated, as the route names it', () {
      final form = CalendarEventForm(
        type: CalendarEventType.milestone,
        title: 'Chapter two opens',
        timing: CalendarTiming.allDay,
        startsAt: DateTime.utc(2026, 10, 12),
        milestone: MilestoneKind.chapterRelease,
      );

      expect(form.toInput()['milestone'], 'chapter-release');
    });

    test('an audience travels only for a reminder', () {
      final reminder = CalendarEventForm(
        title: 'A reminder',
        startsAt: DateTime.utc(2026, 10, 8),
        audience: ReminderAudience.learners,
      );
      expect(reminder.toInput()['audience'], 'learners');
      expect(
        reminder.copyWith(type: CalendarEventType.milestone).toInput().containsKey('audience'),
        isFalse,
      );
    });

    test('the start is a UTC instant, whatever was picked', () {
      final form = CalendarEventForm(
        title: 'A reminder',
        startsAt: DateTime.utc(2026, 10, 8, 9, 30),
      );

      expect(form.toInput()['startsAt'], '2026-10-08T09:30:00.000Z');
    });
  });

  group('what the form checks before asking', () {
    final now = DateTime.utc(2026, 9, 30, 12);

    CalendarEventForm reminder() => CalendarEventForm(
      title: 'Prepare the chart pack',
      startsAt: now.add(const Duration(days: 1)),
      durationMin: 30,
    );

    test('a complete private reminder has nothing to fix', () {
      expect(calendarFormProblems(reminder(), now: now), isEmpty);
    });

    test('a live class or a deadline is never written here', () {
      expect(
        calendarFormProblems(reminder().copyWith(type: CalendarEventType.live), now: now),
        contains('type'),
      );
      expect(
        calendarFormProblems(reminder().copyWith(type: CalendarEventType.assignment), now: now),
        contains('type'),
      );
    });

    test('a title of fewer than three characters is refused', () {
      expect(calendarFormProblems(reminder().copyWith(title: 'Hi'), now: now), ['title']);
    });

    test('a reminder for learners needs the course whose learners it reaches', () {
      expect(
        calendarFormProblems(reminder().copyWith(audience: ReminderAudience.learners), now: now),
        ['course'],
      );
      expect(
        calendarFormProblems(
          reminder().copyWith(audience: ReminderAudience.learners, courseId: 'c1'),
          now: now,
        ),
        isEmpty,
      );
    });

    test('a quiz window needs a course and a quiz', () {
      expect(calendarFormProblems(reminder().copyWith(type: CalendarEventType.quiz), now: now), [
        'course',
        'quiz',
      ]);
    });

    test('a milestone needs its kind, and a chapter release needs the chapter', () {
      expect(
        calendarFormProblems(
          reminder().copyWith(type: CalendarEventType.milestone, courseId: 'c1'),
          now: now,
        ),
        ['milestone'],
      );
      expect(
        calendarFormProblems(
          reminder().copyWith(
            type: CalendarEventType.milestone,
            courseId: 'c1',
            milestone: MilestoneKind.chapterRelease,
          ),
          now: now,
        ),
        ['chapter'],
      );
      expect(
        calendarFormProblems(
          reminder().copyWith(
            type: CalendarEventType.milestone,
            courseId: 'c1',
            milestone: MilestoneKind.cohortStarts,
          ),
          now: now,
        ),
        isEmpty,
      );
    });

    test('a start that has gone is refused, and a timed event checks the instant', () {
      expect(
        calendarFormProblems(
          reminder().copyWith(startsAt: now.subtract(const Duration(minutes: 1))),
          now: now,
        ),
        ['startsAt'],
      );
    });

    test('an all-day event is judged by its IST date, so today still counts', () {
      // 12:00 UTC is 17:30 IST — earlier the same IST day, so today is still allowed.
      final today = CalendarEventForm(
        title: 'A milestone',
        timing: CalendarTiming.allDay,
        startsAt: DateTime.utc(2026, 9, 30, 2),
      );
      expect(calendarFormProblems(today, now: now), isEmpty);

      final yesterday = today.copyWith(startsAt: DateTime.utc(2026, 9, 29, 2));
      expect(calendarFormProblems(yesterday, now: now), ['startsAt']);
    });

    test('a timed event runs between five minutes and twelve hours', () {
      expect(calendarFormProblems(reminder().copyWith(durationMin: 4), now: now), ['duration']);
      expect(calendarFormProblems(reminder().copyWith(durationMin: 721), now: now), ['duration']);
      expect(calendarFormProblems(reminder().copyWith(durationMin: 720), now: now), isEmpty);
      // A moment has no length to check.
      expect(
        calendarFormProblems(
          reminder().copyWith(timing: CalendarTiming.moment, durationMin: 0),
          now: now,
        ),
        isEmpty,
      );
    });
  });
}
