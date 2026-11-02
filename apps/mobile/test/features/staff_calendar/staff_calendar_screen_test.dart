import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_calendar/staff_calendar.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(jsonEncode(fixture('staff/$name.json'))) as Map<String, dynamic>;

/// The fixtures were captured for October 2026; this is a Thursday in that month.
final _now = DateTime.utc(2026, 10, 8, 4);

UserProfile _admin() => UserProfile(
  id: 'u_admin',
  name: 'Kavita Menon',
  email: 'admin@example.test',
  role: UserRole.admin,
  descriptor: 'Academy admin',
  permissions: PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  void answering({
    Map<String, dynamic>? month,
    String detail = 'calendar-reminder',
    Map<String, dynamic>? detailJson,
    Object? write,
    int writeStatus = 200,
  }) {
    adapter.handler = (options) async {
      if (options.method != 'GET') {
        return FakeAdapter.jsonResponse(
          write ?? (detailJson ?? _json(detail))['event'],
          status: writeStatus,
        );
      }
      if (options.path == '/courses') {
        return FakeAdapter.jsonResponse(fixture('staff/courses.json'));
      }
      if (options.path == '/quizzes') {
        return FakeAdapter.jsonResponse(fixture('staff/quizzes.json'));
      }
      if (options.path == '/instructors') {
        return FakeAdapter.jsonResponse(fixture('staff/instructors.json'));
      }
      if (options.path.startsWith('/calendar/')) {
        return FakeAdapter.jsonResponse(detailJson ?? _json(detail));
      }
      return FakeAdapter.jsonResponse(month ?? _json('calendar-month'));
    };
  }

  Future<GoRouter> pump(
    WidgetTester tester, {
    required String at,
    UserProfile? signedInAs,
    Size size = const Size(400, 5000),
    double textScale = 1,
  }) => pumpPublicRouter(
    tester,
    adapter: adapter,
    signedInAs: signedInAs ?? _admin(),
    initialLocation: at,
    size: size,
    textScale: textScale,
    clock: () => _now,
    routes: [
      GoRoute(
        path: AppRoutes.staffCalendar,
        builder: (_, _) => const Scaffold(body: SafeArea(child: StaffCalendarScreen())),
      ),
      GoRoute(
        path: AppRoutes.staffCalendarNew,
        builder: (_, _) => const Scaffold(body: SafeArea(child: CalendarFormScreen())),
      ),
      GoRoute(
        path: AppRoutes.staffEventPattern,
        builder: (_, state) => Scaffold(
          body: SafeArea(
            child: CalendarEventScreen(eventId: state.pathParameters['eventId'] ?? ''),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.staffEventEditPattern,
        builder: (_, state) => Scaffold(
          body: SafeArea(child: CalendarFormScreen(eventId: state.pathParameters['eventId'] ?? '')),
        ),
      ),
      GoRoute(path: AppRoutes.staffLiveClassPattern, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.staffSubmissionsPattern, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.staffQuizPattern, builder: (_, _) => const Placeholder()),
    ],
  );

  group('the calendar', () {
    testWidgets('opens on today\'s agenda, in the week it falls in', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffCalendar);
      await tester.pumpAndSettle();

      // 8 October 2026 carries the fixture's own reminder.
      expect(find.textContaining('prepare the chart pack'), findsOneWidget);
      expect(find.textContaining('Week of'), findsOneWidget);
      expect(adapter.requests.where((r) => r.path == '/calendar').first.queryParameters, {
        'from': '2026-10-05',
        'to': '2026-10-11',
      });
    });

    testWidgets('the type chips carry the counts for the whole range', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffCalendar);
      await tester.pumpAndSettle();

      expect(find.text('Everything'), findsOneWidget);
      expect(typeChip('Live', 15), findsOneWidget);
      expect(typeChip('Reminders', 2), findsOneWidget);
      expect(typeChip('Deadlines', 1), findsOneWidget);
    });

    testWidgets('a type chip asks the academy for that type alone', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffCalendar);
      await tester.pumpAndSettle();

      // The chips scroll sideways; the last one is brought into view first, as a person would.
      await tester.ensureVisible(typeChip('Reminders', 2));
      await tester.pumpAndSettle();
      await tester.tap(typeChip('Reminders', 2));
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/calendar').last.queryParameters['types'],
        const ['reminder'],
      );
    });

    testWidgets('a day with nothing on it says so, and the week still reads', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffCalendar);
      await tester.pumpAndSettle();

      // The 7th of October carries nothing in the captured month; the 5th, 8th and 9th do.
      await tester.tap(find.text('7'));
      await tester.pumpAndSettle();

      expect(find.text('Nothing on this day'), findsOneWidget);
      // The week itself still has events, so this is a quiet day and not an empty range.
      expect(find.text('Nothing in this range'), findsNothing);
    });

    testWidgets('moving a week asks for the next range', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffCalendar);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Next'));
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.path == '/calendar').last.queryParameters, {
        'from': '2026-10-12',
        'to': '2026-10-18',
      });
    });

    testWidgets('an empty range says what the calendar is for', (tester) async {
      answering(
        month: {
          'rows': const <Object>[],
          'total': 0,
          'counts': const {'live': 0, 'assignment': 0, 'quiz': 0, 'milestone': 0, 'reminder': 0},
        },
      );

      await pump(tester, at: AppRoutes.staffCalendar);
      await tester.pumpAndSettle();

      expect(find.text('Nothing in this range'), findsOneWidget);
      expect(find.textContaining('your own reminders appear here'), findsOneWidget);
    });

    testWidgets('a tablet shows the month grid beside the day', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffCalendar, size: const Size(900, 5000));
      await tester.pumpAndSettle();

      expect(find.byType(MonthGrid), findsOneWidget);
      expect(find.byType(WeekStrip), findsNothing);
      // The whole grid is read, not just the week.
      expect(
        adapter.requests.where((r) => r.path == '/calendar').last.queryParameters['from'],
        '2026-09-28',
      );
    });

    testWidgets('the course filter sits in the Filters sheet, and narrows the range', (
      tester,
    ) async {
      answering();

      await pump(tester, at: AppRoutes.staffCalendar);
      await tester.pumpAndSettle();

      expect(find.text('Every course'), findsNothing);
      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Every course'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jaimini Astrology: Chara Karakas').last);
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/calendar').last.queryParameters['courseId'],
        isNotNull,
      );
    });

    testWidgets('opening an event goes to its own screen', (tester) async {
      answering();

      final router = await pump(tester, at: AppRoutes.staffCalendar);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AgendaRow).first);
      await tester.pumpAndSettle();

      expect(locationOf(router), startsWith('/staff/calendar/'));
    });
  });

  group('one event', () {
    testWidgets('a reminder can be ticked off, edited and removed', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffEvent('e1'));
      await tester.pumpAndSettle();

      expect(find.textContaining('prepare the chart pack'), findsOneWidget);
      expect(find.text('Only me'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Mark it done'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Edit'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Remove'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Mark it done'));
      await tester.pumpAndSettle();

      final sent = adapter.requests.where((r) => r.method == 'POST').last;
      expect(sent.path, endsWith('/done'));
      expect((sent.data! as Map)['done'], isTrue);
    });

    testWidgets('removing one asks first, and says it is gone', (tester) async {
      adapter.handler = (options) async {
        if (options.method == 'DELETE') return FakeAdapter.noContent();
        if (options.path.startsWith('/calendar/')) {
          return FakeAdapter.jsonResponse(_json('calendar-reminder'));
        }
        return FakeAdapter.jsonResponse(_json('calendar-month'));
      };

      await pump(tester, at: AppRoutes.staffEvent('e1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Remove'));
      await tester.pumpAndSettle();

      expect(find.text('Remove this event?'), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Remove').last);
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.method == 'DELETE'), hasLength(1));
    });

    testWidgets('a live class read here is not the calendar\'s to change', (tester) async {
      answering(detail: 'calendar-live');

      final router = await pump(tester, at: AppRoutes.staffEvent('live-l1'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppButton, 'Edit'), findsNothing);
      expect(find.widgetWithText(AppButton, 'Remove'), findsNothing);
      expect(find.text('A live class is changed in Live classes.'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Open the live class'));
      await tester.pumpAndSettle();

      expect(locationOf(router), startsWith('/staff/live/'));
    });

    testWidgets('a deadline points at its hand-ins and names who still owes it', (tester) async {
      answering(detail: 'calendar-assignment');

      final router = await pump(tester, at: AppRoutes.staffEvent('assignment-a1'));
      await tester.pumpAndSettle();

      expect(find.text('Still to hand in'), findsOneWidget);
      expect(find.textContaining('of 17 have handed in'), findsWidgets);
      expect(find.text('A deadline is changed on the assignment itself.'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'See the hand-ins'));
      await tester.pumpAndSettle();

      expect(locationOf(router), contains('/submissions'));
    });

    testWidgets('a quiz window reads out the quiz it points at', (tester) async {
      answering(detail: 'calendar-quiz-event');

      await pump(tester, at: AppRoutes.staffEvent('e2'));
      await tester.pumpAndSettle();

      expect(find.textContaining('The Nine Planets'), findsWidgets);
      expect(find.text('17 learners'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Open the quiz'), findsOneWidget);
    });

    testWidgets('an event that is not there reads as not found', (tester) async {
      adapter.handler = (options) async =>
          FakeAdapter.jsonResponse(const {'message': 'Event not found.'}, status: 404);

      await pump(tester, at: AppRoutes.staffEvent('nope'));
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundView), findsOneWidget);
    });
  });

  group('the form', () {
    testWidgets('a new event will not be sent until it has a title and a future start', (
      tester,
    ) async {
      answering();

      await pump(tester, at: AppRoutes.staffCalendarNew);
      await tester.pumpAndSettle();

      // The page's name is the shell's app bar; the body opens on the form's first section.
      expect(find.byType(CalendarFormScreen), findsOneWidget);
      expect(find.text('The event'), findsOneWidget);
      final button = find.widgetWithText(AppButton, 'Add it');
      await tester.scrollUntilVisible(button, 400, scrollable: find.byType(Scrollable).first);
      expect(tester.widget<AppButton>(button).onPressed, isNull, reason: 'no title yet');
    });

    testWidgets('a private reminder needs nothing but a title, and is sent wrapped', (
      tester,
    ) async {
      answering();

      await pump(tester, at: AppRoutes.staffCalendarNew);
      await tester.pumpAndSettle();

      Finder fieldLabelled(String label) => find.descendant(
        of: find.ancestor(of: find.text(label), matching: find.byType(AppTextField)),
        matching: find.byType(TextField),
      );
      await tester.enterText(fieldLabelled('Title · Required'), 'Prepare the chart pack');
      await tester.pumpAndSettle();

      final button = find.widgetWithText(AppButton, 'Add it');
      await tester.scrollUntilVisible(button, 400, scrollable: find.byType(Scrollable).first);
      expect(tester.widget<AppButton>(button).onPressed, isNotNull);
      await tester.tap(button);
      await tester.pumpAndSettle();

      final sent = adapter.requests.where((r) => r.method == 'POST').last;
      expect(sent.path, '/calendar');
      final input = (sent.data! as Map)['input']! as Map<String, Object?>;
      expect(input['type'], 'reminder');
      expect(input['title'], 'Prepare the chart pack');
      expect(input['audience'], 'me');
      expect(input['durationMin'], isNotNull, reason: 'a timed event carries its length');
    });

    testWidgets('a reminder for learners asks which course they are on', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffCalendarNew);
      await tester.pumpAndSettle();
      expect(find.text('Course'), findsNothing);

      await tester.tap(find.text('Who it is for'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('The course’s learners').last);
      await tester.pumpAndSettle();

      expect(find.text('Course'), findsOneWidget);
    });

    testWidgets('a milestone asks its kind, and a chapter release asks the chapter', (
      tester,
    ) async {
      answering();

      await pump(tester, at: AppRoutes.staffCalendarNew);
      await tester.pumpAndSettle();

      await tester.tap(find.text('What it is'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Milestones').last);
      await tester.pumpAndSettle();

      expect(find.text('What kind of milestone'), findsOneWidget);
      expect(find.text('Chapter'), findsNothing);

      await tester.tap(find.text('What kind of milestone'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A chapter opens').last);
      await tester.pumpAndSettle();
      // The chapter list needs a course chosen first.
      await tester.tap(find.text('Course'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Foundations of Vedic Astrology').last);
      await tester.pumpAndSettle();

      expect(find.text('Chapter'), findsOneWidget);
    });

    testWidgets('an all-day event hides the length, and reads as a date', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffCalendarNew);
      await tester.pumpAndSettle();
      expect(find.text('How long (minutes)'), findsOneWidget);

      await tester.tap(find.text('When'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('The whole day').last);
      await tester.pumpAndSettle();

      expect(find.text('How long (minutes)'), findsNothing);
      expect(find.text('Day'), findsOneWidget);
    });

    testWidgets('a refused write shows the academy\'s words on each field', (tester) async {
      answering(
        write: const {
          'message': 'Check the event before saving.',
          'issues': [
            {'field': 'title', 'message': 'Give the event a title of at least 3 characters.'},
          ],
        },
        writeStatus: 409,
      );

      await pump(tester, at: AppRoutes.staffEventEdit('e1'));
      await tester.pumpAndSettle();

      final button = find.widgetWithText(AppButton, 'Save');
      await tester.scrollUntilVisible(button, 400, scrollable: find.byType(Scrollable).first);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Give the event a title of at least 3 characters.'), findsOneWidget);
    });

    testWidgets('a derived event cannot be edited, and the form says where it lives', (
      tester,
    ) async {
      answering(detail: 'calendar-live');

      await pump(tester, at: AppRoutes.staffEventEdit('live-l1'));
      await tester.pumpAndSettle();

      expect(find.text('A live class is changed in Live classes.'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Save'), findsNothing);
    });

    testWidgets('everything still fits at the largest text size', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffCalendar, size: const Size(400, 9000), textScale: 2);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

/// A calendar type chip showing [label] with the server's [count] beside it.
Finder typeChip(String label, int count) =>
    find.byWidgetPredicate((w) => w is AppFilterChip && w.label == label && w.count == count);
