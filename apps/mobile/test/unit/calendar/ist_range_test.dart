import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/staff_calendar/staff_calendar.dart';

/// The IST arithmetic the calendar's range is built from (§21). A day is an IST calendar day, held as
/// a UTC-flagged midnight; the route's `from`/`to` are those days, and an event is filed under the
/// IST day it falls on — not the UTC one.
void main() {
  group('the IST day an instant falls on', () {
    test('a mid-afternoon instant is that same day', () {
      expect(
        istDayOf(DateTime.utc(2026, 9, 30, 8, 30)),
        DateTime.utc(2026, 9, 30),
        reason: '14:00 IST on the 30th',
      );
    });

    test('an instant late in UTC has already turned the IST date', () {
      // 19:00 UTC is 00:30 IST the next morning.
      expect(istDayOf(DateTime.utc(2026, 9, 30, 19)), DateTime.utc(2026, 10));
    });

    test('an instant just before the IST midnight is still the earlier day', () {
      // 18:29 UTC is 23:59 IST on the same date.
      expect(istDayOf(DateTime.utc(2026, 9, 30, 18, 29)), DateTime.utc(2026, 9, 30));
    });

    test('an instant early in UTC is the same IST day', () {
      // 00:30 UTC is 06:00 IST.
      expect(istDayOf(DateTime.utc(2026, 9, 30, 0, 30)), DateTime.utc(2026, 9, 30));
    });

    test('the day it gives is always a UTC-flagged midnight, so days compare by equality', () {
      final day = istDayOf(DateTime.utc(2026, 9, 30, 8, 30));
      expect(day.isUtc, isTrue);
      expect([day.hour, day.minute, day.second], [0, 0, 0]);
      expect(day, istDayOf(DateTime.utc(2026, 9, 30, 13)));
    });
  });

  group('the week a day sits in', () {
    test('starts on the Monday', () {
      // 30 Sep 2026 is a Wednesday.
      expect(istWeekStart(DateTime.utc(2026, 9, 30)), DateTime.utc(2026, 9, 28));
      expect(istWeekStart(DateTime.utc(2026, 9, 28)), DateTime.utc(2026, 9, 28));
      expect(istWeekStart(DateTime.utc(2026, 10, 4)), DateTime.utc(2026, 9, 28));
    });

    test('is seven days, Monday to Sunday', () {
      final week = istWeekOf(DateTime.utc(2026, 9, 30));

      expect(week, hasLength(7));
      expect(week.first, DateTime.utc(2026, 9, 28));
      expect(week.last, DateTime.utc(2026, 10, 4));
      expect(week.first.weekday, DateTime.monday);
      expect(week.last.weekday, DateTime.sunday);
    });

    test('crosses a month without a gap', () {
      final week = istWeekOf(DateTime.utc(2026, 10));
      expect(week.map((d) => d.day), [28, 29, 30, 1, 2, 3, 4]);
    });
  });

  group('the month grid', () {
    test('covers whole weeks either side of the month', () {
      final grid = istMonthGrid(DateTime.utc(2026, 10, 15));

      expect(grid.length % 7, 0);
      expect(grid.first.weekday, DateTime.monday);
      expect(grid.last.weekday, DateTime.sunday);
      // October 2026 begins on a Thursday, so the grid opens on 28 September.
      expect(grid.first, DateTime.utc(2026, 9, 28));
      expect(grid.contains(DateTime.utc(2026, 10)), isTrue);
      expect(grid.contains(DateTime.utc(2026, 10, 31)), isTrue);
    });

    test('has no repeated day, and runs forward', () {
      final grid = istMonthGrid(DateTime.utc(2026, 10, 15));

      expect(grid.toSet(), hasLength(grid.length));
      for (var i = 1; i < grid.length; i++) {
        expect(grid[i].difference(grid[i - 1]).inDays, 1);
      }
    });

    test('a February in a leap year is covered whole', () {
      final grid = istMonthGrid(DateTime.utc(2028, 2, 10));

      expect(grid.contains(DateTime.utc(2028, 2, 29)), isTrue);
      expect(grid.length % 7, 0);
    });
  });

  group('the range the route is asked for', () {
    test('a week view asks for that Monday to that Sunday', () {
      final view = CalendarView(day: _wednesday);
      final (from, to) = view.range;

      expect(from, DateTime.utc(2026, 9, 28));
      expect(to, DateTime.utc(2026, 10, 4));
    });

    test('a month view asks for the whole grid', () {
      final view = CalendarView(day: _wednesday, wholeMonth: true);
      final (from, to) = view.range;

      expect(from, DateTime.utc(2026, 8, 31), reason: 'September 2026 opens on a Tuesday');
      expect(to.isAfter(DateTime.utc(2026, 9, 30)), isTrue);
      expect(to.weekday, DateTime.sunday);
    });

    test('two views of the same week ask for the same range', () {
      expect(
        CalendarView(day: DateTime.utc(2026, 9, 28)).range,
        CalendarView(day: DateTime.utc(2026, 10, 4)).range,
      );
    });
  });

  group('when an event is over', () {
    CalendarEvent event(CalendarTiming timing, {int? durationMin}) => CalendarEvent(
      id: 'e1',
      timing: timing,
      startsAt: DateTime.utc(2026, 9, 30, 8, 30),
      durationMin: durationMin,
    );

    test('a timed event ends after its length', () {
      expect(event(CalendarTiming.timed, durationMin: 45).endsAt, DateTime.utc(2026, 9, 30, 9, 15));
    });

    test('a moment ends when it happens', () {
      expect(event(CalendarTiming.moment).endsAt, DateTime.utc(2026, 9, 30, 8, 30));
    });

    test('an all-day event ends at the end of its IST day, not its UTC one', () {
      // 14:00 IST on the 30th, so the day ends at 00:00 IST on the 1st — 18:30 UTC on the 30th.
      expect(event(CalendarTiming.allDay).endsAt, DateTime.utc(2026, 9, 30, 18, 30));
    });

    test('an all-day event late in UTC belongs to the IST day it reads as', () {
      final late = CalendarEvent(
        id: 'e2',
        timing: CalendarTiming.allDay,
        startsAt: DateTime.utc(2026, 9, 30, 19),
      );

      expect(late.istDay, DateTime.utc(2026, 10));
      expect(late.endsAt, DateTime.utc(2026, 10, 1, 18, 30));
    });
  });
}

/// 30 September 2026, a Wednesday.
final _wednesday = DateTime.utc(2026, 9, 30);
