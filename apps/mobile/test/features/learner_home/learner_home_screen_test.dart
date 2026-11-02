import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/core/platform/live_room.dart';
import 'package:syniastrolms_mobile/features/learner_home/learner_home.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _home() =>
    jsonDecode(jsonEncode(fixture('learning/home.json'))) as Map<String, dynamic>;

List<RouteBase> _routes() => [
  GoRoute(
    path: AppRoutes.home,
    builder: (_, _) => const Scaffold(body: SafeArea(child: LearnerHomeScreen())),
  ),
  GoRoute(path: AppRoutes.explore, builder: (_, _) => const Placeholder()),
  GoRoute(path: AppRoutes.learnCoursePattern, builder: (_, _) => const Placeholder()),
  GoRoute(path: AppRoutes.learnLessonPattern, builder: (_, _) => const Placeholder()),
  GoRoute(path: AppRoutes.myLearningPattern, builder: (_, _) => const Placeholder()),
  GoRoute(path: AppRoutes.assignmentPattern, builder: (_, _) => const Placeholder()),
  GoRoute(path: AppRoutes.liveClassPattern, builder: (_, _) => const Placeholder()),
  GoRoute(path: AppRoutes.live, builder: (_, _) => const Placeholder()),
];

/// `GET /live/learner` as the seed answers it: one class ahead (1 Oct 05:28 UTC), and recordings.
/// A phone screen tall enough to build every section at once: the live class and "To do" sit
/// below the courses and the catalogue, past a real phone's first screen.
const _tall = Size(400, 4000);

Map<String, dynamic> _schedule() =>
    jsonDecode(jsonEncode(fixture('live/learner.json'))) as Map<String, dynamic>;

void main() {
  late FakeAdapter adapter;

  setUp(() {
    adapter = FakeAdapter();
    // The catalogue (Home's Discover band) is answered on its own, so the queue below keeps the
    // order of Home's own reads whichever section happens to be built first.
    adapter.handler = (options) async {
      final path = options.path;
      if (path == '/catalog/courses') {
        return FakeAdapter.jsonResponse(fixture('catalog/courses.json'));
      }
      if (path == '/catalog/levels') {
        return FakeAdapter.jsonResponse(fixture('catalog/levels.json'));
      }
      if (adapter.queue.isEmpty) {
        throw StateError('No fake response queued for ${options.method} $path');
      }
      return adapter.queue.removeAt(0)(options);
    };
  });

  Future<GoRouter> pumpHome(
    WidgetTester tester, {
    Size size = const Size(400, 900),
    double textScale = 1,
    DateTime? now,
    OpenLiveRoom? openLiveRoom,
  }) => pumpPublicRouter(
    tester,
    adapter: adapter,
    routes: _routes(),
    initialLocation: AppRoutes.home,
    signedInAs: learner(),
    size: size,
    textScale: textScale,
    clock: now == null ? null : () => now,
    openLiveRoom: openLiveRoom,
  );

  testWidgets('opens on continue and the shortcuts, then courses, discover, the class, to do', (
    tester,
  ) async {
    adapter
      ..enqueueJson(_home())
      ..enqueueJson(_schedule());

    // Tall enough to build every section at once: the order is what is checked.
    await pumpHome(tester, now: DateTime.utc(2026, 9, 30, 6), size: _tall);
    await tester.pumpAndSettle();

    // The greeting is the shell's app bar (app_shell_test: home header); the page opens on where
    // to pick up, not on the catalogue's search.
    expect(find.text('Search the LMS’s courses'), findsNothing);
    expect(find.text('Calculating the balance at birth'), findsOneWidget);

    // Continue learning · the four shortcuts · Your courses · Discover · Next live class · To do ·
    // Recently viewed · This week · Explore courses.
    const order = [
      'Continue learning',
      'My Courses',
      'Your courses',
      'Discover more courses',
      'Next live class',
      'To do',
      'Recently viewed',
      'This week',
      'Explore courses',
    ];
    for (final text in order) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    double y(String text) => tester.getTopLeft(find.text(text)).dy;
    for (var i = 1; i < order.length; i++) {
      expect(y(order[i - 1]), lessThan(y(order[i])), reason: '${order[i - 1]} above ${order[i]}');
    }
  });

  testWidgets('the next class is the schedule\'s, with the seat button the Live tab offers', (
    tester,
  ) async {
    adapter
      ..enqueueJson(_home())
      ..enqueueJson(_schedule());

    await pumpHome(tester, now: DateTime.utc(2026, 9, 30, 6), size: _tall);
    await tester.pumpAndSettle();

    expect(find.text('Reading dignities in real charts'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Save my seat'), findsOneWidget);
    // Recordings are the Live tab's business, never "next".
    expect(find.text('Dasha timing office hours'), findsNothing);
  });

  testWidgets('a class that has begun is "Live now", and Join is the action', (tester) async {
    // The seeded class is in the built-in room, so it is live once its host has opened it.
    final started = _schedule();
    final row = (started['upcoming']! as List<dynamic>).first as Map<String, dynamic>;
    (row['liveClass']! as Map<String, dynamic>)['startedAt'] = '2026-10-01T05:28:00.000Z';
    adapter
      ..enqueueJson(_home())
      ..enqueueJson(started);

    // Ten minutes into the seeded class.
    final router = await pumpHome(tester, now: DateTime.utc(2026, 10, 1, 5, 38), size: _tall);
    await tester.pumpAndSettle();

    expect(find.text('Next live class'), findsNothing);
    expect(find.widgetWithText(SectionHeader, 'Live now'), findsOneWidget);
    // The built-in room opens inside the app.
    expect(find.widgetWithText(AppButton, 'Join the class'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Save my seat'), findsNothing);

    await tester.tap(find.text('Reading dignities in real charts'));
    await tester.pumpAndSettle();
    expect(locationOf(router), '/live/cmum8kcg70087mmzwqracp24y');
  });

  group('Join on the class card', () {
    Map<String, dynamic> started() {
      final raw = _schedule();
      final row = (raw['upcoming']! as List<dynamic>).first as Map<String, dynamic>;
      (row['liveClass']! as Map<String, dynamic>)['startedAt'] = '2026-10-01T05:28:00.000Z';
      return raw;
    }

    // Ten minutes into the seeded class, which its host has opened.
    final tenIn = DateTime.utc(2026, 10, 1, 5, 38);

    testWidgets('says why the academy refused, as the Live tab does', (tester) async {
      adapter
        ..enqueueJson(_home())
        ..enqueueJson(started());
      await pumpHome(tester, now: tenIn, size: _tall);
      await tester.pumpAndSettle();

      adapter
        ..enqueueJson({'message': 'This class has ended.'}, status: 409)
        ..enqueueJson(started());
      await tester.tap(find.widgetWithText(AppButton, 'Join the class'));
      await tester.pumpAndSettle();

      expect(adapter.requests.map((r) => r.path), contains(endsWith('/join')));
      expect(find.text('This class has ended.'), findsOneWidget);
    });

    testWidgets('says when this phone could not open the room', (tester) async {
      adapter
        ..enqueueJson(_home())
        ..enqueueJson(started());
      await pumpHome(
        tester,
        now: tenIn,
        size: _tall,
        openLiveRoom: (room, {onClosed}) async => throw const LiveRoomUnavailable('no camera'),
      );
      await tester.pumpAndSettle();

      adapter.enqueueJson({
        'kind': 'room',
        'room': {
          'provider': 'jitsi',
          'domain': 'meet.jit.si',
          'room': 'shubh-abc',
          'displayName': 'Ananya Rao',
          'moderator': false,
        },
      });
      await tester.tap(find.widgetWithText(AppButton, 'Join the class'));
      await tester.pumpAndSettle();

      expect(
        find.text('The class couldn’t open on this phone. Check your connection and try again.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('a schedule that cannot be read leaves the feed\'s own entry for the class', (
    tester,
  ) async {
    adapter
      ..enqueueJson(_home())
      ..enqueueJson({'message': 'Server error.'}, status: 500);
    final router = await pumpHome(tester, size: _tall);
    await tester.pumpAndSettle();

    final live = LearnerHome.fromJson(
      _home(),
    ).upcoming.firstWhere((i) => i.kind == UpcomingKind.live);
    expect(find.text('Next live class'), findsOneWidget);
    expect(find.text(live.title), findsOneWidget);
    expect(find.byType(ErrorState), findsNothing, reason: 'Home itself still loaded');

    await tester.tap(find.text(live.title));
    await tester.pumpAndSettle();
    expect(locationOf(router), '/live/${live.id}');
  });

  testWidgets('no class ahead and nothing due: those sections are left out', (tester) async {
    final raw = _home();
    (raw['upcoming']! as List<dynamic>).clear();
    adapter
      ..enqueueJson(raw)
      ..enqueueJson({'live': <Object>[], 'upcoming': <Object>[], 'recordings': <Object>[]});

    await pumpHome(tester, size: _tall);
    await tester.pumpAndSettle();

    expect(find.text('Continue learning'), findsOneWidget);
    expect(find.text('Next live class'), findsNothing);
    expect(find.text('Live now'), findsNothing);
    expect(find.text('To do'), findsNothing);
  });

  testWidgets('the one course already in Continue learning is not listed again', (tester) async {
    final raw = _home();
    final courses = raw['courses']! as List<dynamic>;
    final resumable = LearnerHome.fromJson(
      raw,
    ).courses.indexWhere((c) => c.next != null && showsInProgress(c));
    final only = courses[resumable];
    courses
      ..clear()
      ..add(only);
    adapter.enqueueJson(raw);

    await pumpHome(tester);
    await tester.pumpAndSettle();

    expect(find.text('Continue learning'), findsOneWidget);
    expect(find.text('Your courses'), findsNothing);
  });

  testWidgets('discovery is the last thing on Home, and opens Explore', (tester) async {
    adapter.enqueueJson(_home());
    final router = await pumpHome(tester);
    await tester.pumpAndSettle();

    final explore = find.text('Explore courses');
    await tester.scrollUntilVisible(explore, 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(explore);
    await tester.pumpAndSettle();
    expect(locationOf(router), AppRoutes.explore);
  });

  testWidgets('progress is the server\'s figure, shown not computed', (tester) async {
    adapter.enqueueJson(_home());

    await pumpHome(tester);
    await tester.pumpAndSettle();

    final ring = tester.widget<ProgressRing>(find.byType(ProgressRing).first);
    expect((ring.value * 100).round(), 32);
    final lessons = find.text('1 of 4 lessons');
    await tester.scrollUntilVisible(lessons, 300, scrollable: find.byType(Scrollable).first);
    expect(lessons, findsOneWidget);
  });

  testWidgets('Resume opens exactly the lesson the server named', (tester) async {
    adapter.enqueueJson(_home());
    final router = await pumpHome(tester);
    await tester.pumpAndSettle();

    final home = LearnerHome.fromJson(_home());
    final course = home.courses.firstWhere((c) => c.next != null);

    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();

    expect(locationOf(router), '/learn/${course.course.id}/lessons/${course.next!.id}');
  });

  testWidgets('an upcoming item opens the route its web path maps to', (tester) async {
    adapter.enqueueJson(_home());
    final router = await pumpHome(tester, size: _tall);
    await tester.pumpAndSettle();

    final overdue = LearnerHome.fromJson(
      _home(),
    ).upcoming.firstWhere((i) => i.flag == UpcomingFlag.overdue);

    await tester.tap(find.text(overdue.title));
    await tester.pumpAndSettle();

    expect(locationOf(router), '/assignments/${overdue.id}');
  });

  testWidgets('a web path the app does not own is not followed', (tester) async {
    final raw = _home();
    (raw['upcoming']! as List<dynamic>)
      ..clear()
      ..add({
        'id': 'x',
        'kind': 'live',
        'title': 'Somewhere else',
        'context': 'Nowhere',
        'at': '2026-09-25T06:00:00.000Z',
        'to': '/admin/settings/danger',
      });
    adapter.enqueueJson(raw);
    final router = await pumpHome(tester, size: _tall);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Somewhere else'));
    await tester.pumpAndSettle();

    expect(locationOf(router), AppRoutes.home);
  });

  testWidgets('a learner with no enrolments is pointed at Explore', (tester) async {
    adapter.enqueueJson({
      'firstName': 'Ananya',
      'courses': <Object>[],
      'saved': <Object>[],
      'recent': <Object>[],
      'upcoming': <Object>[],
      'week': <Object>[],
    });
    final router = await pumpHome(tester);
    await tester.pumpAndSettle();

    expect(find.text('Your learning starts here'), findsOneWidget);

    await tester.tap(find.text('Explore courses'));
    await tester.pumpAndSettle();
    expect(locationOf(router), AppRoutes.explore);
  });

  testWidgets('a failed read offers a retry that reads again', (tester) async {
    adapter
      ..enqueueJson({'message': 'Server error.'}, status: 500)
      ..enqueueJson(_home());

    await pumpHome(tester);
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Continue learning'), findsOneWidget);
  });

  testWidgets('offline says so instead of showing an empty home', (tester) async {
    // Every attempt fails, retries included, so the screen reaches its offline state.
    adapter.handler = (options) async =>
        throw DioException(requestOptions: options, type: DioExceptionType.connectionError);

    await pumpHome(tester);
    // The client retries a connection failure twice with backoff; nothing schedules a frame
    // while it waits, so the test has to let that time pass before the state is final.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text("You're offline. Connect to continue."), findsOneWidget);
    expect(find.text('Your learning starts here'), findsNothing);
  });

  testWidgets('the courses go two across from the medium breakpoint up', (tester) async {
    adapter.enqueueJson(_home());

    await pumpHome(tester, size: const Size(840, 1600));
    await tester.pumpAndSettle();

    final rows = find.byType(LearnerCourseRow);
    expect(rows, findsWidgets);
    final first = tester.getTopLeft(rows.at(0));
    final second = tester.getTopLeft(rows.at(1));
    expect(second.dy, first.dy, reason: 'two courses share a row on a tablet');
  });

  testWidgets('everything still fits at 200% text', (tester) async {
    adapter.enqueueJson(_home());

    await pumpHome(tester, textScale: 2);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'no overflow at double the text size');
    expect(find.text('Continue learning'), findsOneWidget);
  });
}
