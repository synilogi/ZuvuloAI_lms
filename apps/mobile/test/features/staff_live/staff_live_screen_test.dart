import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/app/routing/up_navigation.dart';
import 'package:syniastrolms_mobile/core/platform/external_link.dart';
import 'package:syniastrolms_mobile/core/platform/live_room.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_live/staff_live.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(jsonEncode(fixture('staff/$name.json'))) as Map<String, dynamic>;

/// The fixture's own class starts on this day, so a fixed clock puts it just ahead.
DateTime _startOf(Map<String, dynamic> detail) =>
    DateTime.parse((detail['liveClass']! as Map<String, dynamic>)['startsAt']! as String);

UserProfile _admin() => UserProfile(
  id: 'u_admin',
  name: 'Kavita Menon',
  email: 'admin@example.test',
  role: UserRole.admin,
  descriptor: 'Academy admin',
  permissions: PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

/// An admin who may read the schedule and nothing more.
UserProfile _reader() => const UserProfile(
  id: 'u_reader',
  name: 'Reader',
  email: 'reader@example.test',
  role: UserRole.admin,
  descriptor: 'Academy admin',
  permissions: [PermissionKey.catalogView],
);

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  void answering({
    Map<String, dynamic>? schedule,
    Map<String, dynamic>? detail,
    Object? write,
    int writeStatus = 200,
    String? plan,
  }) {
    adapter.handler = (options) async {
      if (plan != null && options.path == '/academy/plan') {
        return FakeAdapter.jsonResponse(fixture('entitlements/$plan'));
      }
      if (options.method == 'POST' && options.path.endsWith('/start')) {
        final cls = {...(detail ?? _json('live-class'))['liveClass'] as Map<String, dynamic>};
        cls['startedAt'] = DateTime.now().toUtc().toIso8601String();
        return FakeAdapter.jsonResponse({
          'liveClass': cls,
          'phase': 'live',
          'room': {
            'provider': 'jitsi',
            'domain': 'meet.jit.si',
            'room': 'shubh-host',
            'subject': cls['title'],
            'displayName': 'Kavita Menon',
            'moderator': true,
            'recording': false,
          },
        });
      }
      if (options.method != 'GET') {
        return FakeAdapter.jsonResponse(
          write ?? (detail ?? _json('live-class'))['liveClass'],
          status: writeStatus,
        );
      }
      if (options.path == '/courses') {
        return FakeAdapter.jsonResponse(fixture('staff/courses.json'));
      }
      if (options.path == '/instructors') {
        return FakeAdapter.jsonResponse(fixture('staff/instructors.json'));
      }
      if (options.path.startsWith('/live/')) {
        return FakeAdapter.jsonResponse(detail ?? _json('live-class'));
      }
      return FakeAdapter.jsonResponse(schedule ?? _json('live-schedule'));
    };
  }

  Future<GoRouter> pump(
    WidgetTester tester, {
    required String at,
    DateTime? now,
    DateTime Function()? clock,
    UserProfile? signedInAs,
    Size size = const Size(400, 5000),
    double textScale = 1,
    OpenExternalLink? openExternalLink,
    OpenLiveRoom? openLiveRoom,
  }) => pumpPublicRouter(
    tester,
    adapter: adapter,
    signedInAs: signedInAs ?? _admin(),
    initialLocation: at,
    size: size,
    textScale: textScale,
    clock: clock ?? () => now!,
    openExternalLink: openExternalLink,
    openLiveRoom: openLiveRoom,
    routes: [
      GoRoute(
        path: AppRoutes.staffLive,
        builder: (_, _) => const Scaffold(body: SafeArea(child: StaffLiveScreen())),
      ),
      GoRoute(
        path: AppRoutes.staffLiveNew,
        // The shell names the schedule as this page's parent; the test stands in for it.
        builder: (_, _) => const UpNavigation(
          up: AppRoutes.staffLive,
          child: Scaffold(body: SafeArea(child: LiveFormScreen())),
        ),
      ),
      GoRoute(
        path: AppRoutes.staffLiveClassPattern,
        builder: (_, state) => Scaffold(
          body: SafeArea(child: StaffLiveClassScreen(liveId: state.pathParameters['liveId'] ?? '')),
        ),
      ),
      GoRoute(
        path: AppRoutes.staffLiveEditPattern,
        builder: (_, state) => Scaffold(
          body: SafeArea(child: LiveFormScreen(liveId: state.pathParameters['liveId'] ?? '')),
        ),
      ),
    ],
  );

  /// Well before the fixture's class: it reads as upcoming.
  DateTime longBefore() => _startOf(_json('live-class')).subtract(const Duration(days: 2));

  /// Inside the join window.
  DateTime justBefore() => _startOf(_json('live-class')).subtract(const Duration(minutes: 5));

  group('the schedule', () {
    testWidgets('shows the academy\'s classes with the counts it sent', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffLive, now: longBefore());
      await tester.pumpAndSettle();

      expect(find.byType(StaffLiveCard), findsWidgets);
      expect(find.text('Upcoming'), findsWidgets);
      expect(find.text('Cancelled'), findsWidgets);
      expect(find.textContaining('Reading dignities in real charts'), findsWidgets);
    });

    testWidgets('a view asks the academy for that view alone', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffLive, now: longBefore());
      await tester.pumpAndSettle();

      await tester.tap(find.text('History').first);
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/live').last.queryParameters['view'],
        'history',
      );
    });

    testWidgets('searching narrows it', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffLive, now: longBefore());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'dignities');
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/live').last.queryParameters['search'],
        'dignities',
      );
    });

    testWidgets('an empty schedule says what scheduling one does', (tester) async {
      answering(
        schedule: {
          'rows': const <Object>[],
          'total': 0,
          'counts': const {'upcoming': 0, 'live': 0, 'history': 0, 'cancelled': 0},
        },
      );

      await pump(tester, at: AppRoutes.staffLive, now: longBefore());
      await tester.pumpAndSettle();

      expect(find.text('Nothing scheduled'), findsOneWidget);
      expect(find.textContaining('learners are told'), findsOneWidget);
    });

    testWidgets('opening a class goes to its own screen', (tester) async {
      answering();

      final router = await pump(tester, at: AppRoutes.staffLive, now: longBefore());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(StaffLiveCard).first);
      await tester.pumpAndSettle();

      expect(locationOf(router), startsWith('/staff/live/'));
    });

    testWidgets('the course filter sits in the Filters sheet, and narrows the schedule', (
      tester,
    ) async {
      answering();

      await pump(tester, at: AppRoutes.staffLive, now: longBefore());
      await tester.pumpAndSettle();

      // The selects no longer sit above the list: they are behind the Filters button.
      expect(find.text('Every course'), findsNothing);
      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Every course'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jaimini Astrology: Chara Karakas').last);
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/live').last.queryParameters['courseId'],
        isNotNull,
      );
      // The button counts the filter that is on.
      expect(find.byTooltip('Filters, 1 on'), findsOneWidget);
    });

    testWidgets('someone who may not run classes is offered no scheduling', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffLive, now: longBefore(), signedInAs: _reader());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppButton, 'Schedule a class'), findsNothing);
      expect(find.byType(StaffLiveCard), findsWidgets);
    });
  });

  group('under the academy\'s plan', () {
    Finder scheduleFab() => find.widgetWithText(AppFab, 'Schedule a class');

    Future<void> settle(WidgetTester tester) async {
      // The plan is read beside the schedule; let both answers land.
      for (var i = 0; i < 3; i++) {
        await tester.pump(Duration.zero);
        await tester.pumpAndSettle();
      }
    }

    testWidgets('read-only: scheduling is disabled, and says why', (tester) async {
      answering(plan: 'academy-plan-lapsed.json');

      final router = await pump(tester, at: AppRoutes.staffLive, now: longBefore());
      await settle(tester);

      expect(scheduleFab(), findsOneWidget);
      expect(tester.widget<AppFab>(scheduleFab()).onPressed, isNull);
      expect(find.byTooltip('Adding to Live classes needs an active plan.'), findsOneWidget);
      // Existing classes stay readable.
      expect(find.byType(StaffLiveCard), findsWidgets);

      await tester.tap(scheduleFab(), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(locationOf(router), AppRoutes.staffLive);
    });

    testWidgets('open: scheduling goes to the form', (tester) async {
      answering(plan: 'academy-plan-active.json');

      final router = await pump(tester, at: AppRoutes.staffLive, now: longBefore());
      await settle(tester);

      expect(tester.widget<AppFab>(scheduleFab()).onPressed, isNotNull);
      await tester.tap(scheduleFab());
      await tester.pumpAndSettle();
      expect(locationOf(router), AppRoutes.staffLiveNew);
    });
  });

  group('one class', () {
    testWidgets('reads out when it is, who teaches it and who registered', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffLiveClass('l1'), now: longBefore());
      await tester.pumpAndSettle();

      expect(find.text('Reading dignities in real charts'), findsOneWidget);
      expect(find.textContaining('Dr. Meenakshi Iyer'), findsWidgets);
      expect(find.text('Who registered'), findsOneWidget);
      expect(find.text('Ananya Rao'), findsOneWidget);
      expect(find.text('What happens'), findsOneWidget);
      expect(find.text('Recap of dignity rules'), findsOneWidget);
    });

    testWidgets('the phase follows the clock, and joining waits for the window', (tester) async {
      // The fixture's class is hosted in the academy's own room, so there is no link to open.
      final external = _json('live-class');
      (external['liveClass']! as Map<String, dynamic>)['meeting'] = const {
        'kind': 'external',
        'link': 'https://meet.example.com/dignities',
      };
      answering(detail: external);

      await pump(tester, at: AppRoutes.staffLiveClass('l1'), now: longBefore());
      await tester.pumpAndSettle();

      expect(find.text('Scheduled'), findsWidgets);
      expect(
        tester.widget<AppButton>(find.widgetWithText(AppButton, 'Open the meeting')).onPressed,
        isNull,
        reason: 'the join window has not opened yet',
      );
      expect(find.textContaining('opens 15 minutes before'), findsOneWidget);
    });

    testWidgets('inside the window the meeting opens, outside the app', (tester) async {
      final external = _json('live-class');
      (external['liveClass']! as Map<String, dynamic>)['meeting'] = const {
        'kind': 'external',
        'link': 'https://meet.example.com/dignities',
      };
      answering(detail: external);
      final opened = <Uri>[];

      await pump(
        tester,
        at: AppRoutes.staffLiveClass('l1'),
        now: justBefore(),
        openExternalLink: (link) async => opened.add(link),
      );
      await tester.pumpAndSettle();

      expect(find.text('Starting soon'), findsWidgets);
      await tester.tap(find.widgetWithText(AppButton, 'Open the meeting'));
      await tester.pumpAndSettle();

      expect(opened.single.toString(), 'https://meet.example.com/dignities');
    });

    testWidgets('a class in the built-in room is started here, and opens in the app', (
      tester,
    ) async {
      answering();
      final rooms = <LiveRoomJoin>[];

      await pump(
        tester,
        at: AppRoutes.staffLiveClass('l1'),
        now: justBefore(),
        openLiveRoom: (room, {onClosed}) async => rooms.add(room),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppButton, 'Open the meeting'), findsNothing);
      expect(find.textContaining('Learners can join once you start'), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, 'Start class'));
      await tester.pumpAndSettle();

      expect(adapter.requests.map((r) => r.path), contains('/live/l1/start'));
      expect(rooms.single.room, 'shubh-host');
      expect(rooms.single.moderator, isTrue);
    });

    testWidgets('Start appears at the quarter hour on its own, with nothing read again', (
      tester,
    ) async {
      // Read twenty minutes ahead: the academy said the room may not open yet, as it was too early.
      final detail = _json('live-class');
      detail['room'] = {'provider': 'jitsi', 'recording': false, 'canStart': false};
      answering(detail: detail);
      var now = _startOf(detail).subtract(const Duration(minutes: 20));

      await pump(tester, at: AppRoutes.staffLiveClass('l1'), clock: () => now);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppButton, 'Start class'), findsNothing);
      final reads = adapter.requests.length;

      // Six minutes on, one tick of the clock: the window has opened.
      now = now.add(const Duration(minutes: 6));
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppButton, 'Start class'), findsOneWidget);
      expect(adapter.requests.length, reads, reason: 'the clock decided, not another read');
    });

    testWidgets('Start is never offered for a class the academy has cancelled', (tester) async {
      final detail = _json('live-class');
      (detail['liveClass']! as Map<String, dynamic>)['cancelled'] = true;
      detail['room'] = {'provider': 'jitsi', 'recording': false, 'canStart': true};
      answering(detail: detail);

      await pump(tester, at: AppRoutes.staffLiveClass('l1'), now: justBefore());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppButton, 'Start class'), findsNothing);
    });

    testWidgets('a room that drops the host says so', (tester) async {
      answering();

      await pump(
        tester,
        at: AppRoutes.staffLiveClass('l1'),
        now: justBefore(),
        openLiveRoom: (room, {onClosed}) async => onClosed?.call(connectionLost: true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Start class'));
      await tester.pumpAndSettle();

      expect(
        find.text('The class connection was lost. If the class is still on, join again.'),
        findsOneWidget,
      );
    });

    testWidgets('an outside meeting that nothing on the phone can open says so', (tester) async {
      final external = _json('live-class');
      (external['liveClass']! as Map<String, dynamic>)['meeting'] = const {
        'kind': 'external',
        'link': 'https://meet.example.com/dignities',
      };
      answering(detail: external);
      Future<bool> nothingTakesIt(Uri link) async => false;

      await pump(
        tester,
        at: AppRoutes.staffLiveClass('l1'),
        now: justBefore(),
        openExternalLink: nothingTakesIt,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Open the meeting'));
      await tester.pumpAndSettle();

      expect(find.textContaining('The meeting link couldn’t be opened on this phone'), findsOne);
    });

    testWidgets('a meeting link that is not a safe https link is not opened, and nothing breaks', (
      tester,
    ) async {
      final external = _json('live-class');
      (external['liveClass']! as Map<String, dynamic>)['meeting'] = const {
        'kind': 'external',
        // Starts like a link, and does not parse as one.
        'link': 'https://[meet.example.com',
      };
      answering(detail: external);
      final opened = <Uri>[];

      await pump(
        tester,
        at: AppRoutes.staffLiveClass('l1'),
        now: justBefore(),
        openExternalLink: (link) async => opened.add(link),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Open the meeting'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(opened, isEmpty);
      expect(find.textContaining('meeting link can’t be opened'), findsOneWidget);
    });

    testWidgets('who registered is marked in words that claim no more than the academy knows', (
      tester,
    ) async {
      final ended = _json('live-class');
      final cls = ended['liveClass']! as Map<String, dynamic>;
      cls['startedAt'] = cls['startsAt'];
      cls['endedAt'] = DateTime.parse(
        cls['startsAt']! as String,
      ).add(const Duration(minutes: 50)).toIso8601String();
      ended['attendees'] = [
        {'id': 's1', 'name': 'Came In', 'attended': true, 'joinedAt': cls['startsAt']},
        {'id': 's2', 'name': 'Never Came', 'attended': false},
        {'id': 's3', 'name': 'No Record Yet'},
      ];
      answering(detail: ended);

      await pump(
        tester,
        at: AppRoutes.staffLiveClass('l1'),
        now: longBefore().add(const Duration(days: 3)),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('No Record Yet'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Joined'), findsOneWidget, reason: 'joined the room from the app');
      expect(find.text('Missed'), findsOneWidget);
      expect(find.text('Came'), findsNothing);
      expect(find.text('Attended'), findsNothing);
      expect(find.textContaining('Joined '), findsOneWidget, reason: 'the time they went in');
    });

    testWidgets('at an outside meeting, opening the link is all that is said', (tester) async {
      final external = _json('live-class');
      final cls = external['liveClass']! as Map<String, dynamic>;
      cls['meeting'] = const {'kind': 'external', 'link': 'https://meet.example.com/dignities'};
      external['attendees'] = [
        {'id': 's1', 'name': 'Opened It', 'joinedAt': cls['startsAt']},
        {'id': 's2', 'name': 'Held A Place'},
      ];
      answering(detail: external);

      await pump(tester, at: AppRoutes.staffLiveClass('l1'), now: justBefore());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Held A Place'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.textContaining('Opened the link '), findsOneWidget);
      expect(find.text('Joined'), findsNothing);
      expect(find.text('Missed'), findsNothing);
      expect(find.textContaining('Joined '), findsNothing);
    });

    testWidgets('cancelling asks for a reason the learners will read', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffLiveClass('l1'), now: longBefore());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(AppButton, 'Cancel the class'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(AppButton, 'Cancel the class'));
      await tester.pumpAndSettle();

      expect(find.text('Call this class off?'), findsOneWidget);
      // The field marks itself required, so the label carries the marker too.
      expect(find.textContaining('Why (learners see this)'), findsOneWidget);

      await tester.enterText(
        find.descendant(of: find.byType(AppDialog), matching: find.byType(TextField)),
        'The instructor is unwell.',
      );
      await tester.pumpAndSettle();

      // There is no un-cancel route, so the dialog asks for an acknowledgement first.
      final confirm = find.widgetWithText(AppButton, 'Cancel the class').last;
      expect(tester.widget<AppButton>(confirm).onPressed, isNull);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      final sent = adapter.requests.where((r) => r.method == 'POST').last;
      expect(sent.path, endsWith('/cancel'));
      expect((sent.data! as Map)['reason'], 'The instructor is unwell.');
    });

    testWidgets('a cancelled class shows the academy\'s reason and offers no edit', (tester) async {
      final cancelled = _json('live-class');
      (cancelled['liveClass']! as Map<String, dynamic>)
        ..['cancelled'] = true
        ..['cancelReason'] = 'The instructor is unwell.';
      cancelled['phase'] = 'cancelled';
      answering(detail: cancelled);

      await pump(tester, at: AppRoutes.staffLiveClass('l1'), now: longBefore());
      await tester.pumpAndSettle();

      expect(find.textContaining('The instructor is unwell.'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Edit'), findsNothing);
      expect(find.widgetWithText(AppButton, 'Cancel the class'), findsNothing);
      expect(find.textContaining('cancelled class can no longer be edited'), findsOneWidget);
    });

    testWidgets('a class that has started can no longer be edited, and says so', (tester) async {
      final started = _json('live-class');
      (started['liveClass']! as Map<String, dynamic>)['startedAt'] =
          (started['liveClass']! as Map<String, dynamic>)['startsAt'];
      answering(detail: started);

      await pump(
        tester,
        at: AppRoutes.staffLiveClass('l1'),
        now: _startOf(_json('live-class')).add(const Duration(minutes: 5)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live now'), findsWidgets);
      expect(find.widgetWithText(AppButton, 'Edit'), findsNothing);
      expect(find.textContaining('has started can no longer be edited'), findsOneWidget);
      // Under way: the host goes back in or ends it; cancelling is no longer the way.
      expect(find.widgetWithText(AppButton, 'Rejoin as host'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'End class'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Cancel the class'), findsNothing);
    });

    testWidgets('reminding reports the academy\'s own count', (tester) async {
      answering(write: const {'sent': 4});

      await pump(tester, at: AppRoutes.staffLiveClass('l1'), now: longBefore());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(AppButton, 'Remind them now'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(AppButton, 'Remind them now'));
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.method == 'POST').last.path, endsWith('/remind'));
      expect(find.text('4 learners were reminded'), findsOneWidget);
    });

    testWidgets('the reminder offsets the academy set are the ones switched on', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffLiveClass('l1'), now: longBefore());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('A day before'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(
        tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'A day before')).selected,
        isTrue,
      );
      expect(
        tester.widget<FilterChip>(find.widgetWithText(FilterChip, '1 h before')).selected,
        isTrue,
      );
      expect(
        tester.widget<FilterChip>(find.widgetWithText(FilterChip, '30 min before')).selected,
        isFalse,
      );
    });

    testWidgets('a class that is not this account\'s reads as not found', (tester) async {
      adapter.handler = (options) async =>
          FakeAdapter.jsonResponse(const {'message': 'Live class not found.'}, status: 404);

      await pump(tester, at: AppRoutes.staffLiveClass('someone-elses'), now: longBefore());
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundView), findsOneWidget);
    });

    testWidgets('everything still fits at the largest text size', (tester) async {
      answering();

      await pump(
        tester,
        at: AppRoutes.staffLiveClass('l1'),
        now: longBefore(),
        size: const Size(400, 9000),
        textScale: 2,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('the form', () {
    testWidgets('a new class will not be sent until it has what the academy asks for', (
      tester,
    ) async {
      answering();

      await pump(tester, at: AppRoutes.staffLiveNew, now: longBefore());
      await tester.pumpAndSettle();

      // The page's name is the shell's app bar; the body opens on the form's first section.
      expect(find.byType(LiveFormScreen), findsOneWidget);
      expect(find.text('The class'), findsOneWidget);
      final button = find.widgetWithText(AppButton, 'Schedule it');
      await tester.scrollUntilVisible(button, 400, scrollable: find.byType(Scrollable).first);
      expect(
        tester.widget<AppButton>(button).onPressed,
        isNull,
        reason: 'no course, no title and no link yet',
      );
    });

    testWidgets('leaving an unsaved class asks first, then goes back to the schedule', (
      tester,
    ) async {
      answering();

      await pump(tester, at: AppRoutes.staffLiveNew, now: longBefore());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Reading the dashas');
      await tester.pumpAndSettle();

      // Back on a form with changes asks; it does not leave on its own.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Leave without saving?'), findsOneWidget);
      expect(find.byType(LiveFormScreen), findsOneWidget);

      await tester.tap(find.text("I understand this can't be undone"));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Leave'));
      await tester.pumpAndSettle();

      // The form was the only page: leaving goes up to the schedule rather than popping the last
      // page away (which left the screen blank).
      expect(tester.takeException(), isNull);
      expect(find.byType(LiveFormScreen), findsNothing);
      expect(find.byType(StaffLiveScreen), findsOneWidget);
    });

    testWidgets('a filled-in class is sent whole, with the link the write path stores', (
      tester,
    ) async {
      answering();

      await pump(tester, at: AppRoutes.staffLiveNew, now: longBefore());
      await tester.pumpAndSettle();

      // The course and the instructor come from the academy's own lists.
      await tester.tap(find.text('Course'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Foundations of Vedic Astrology').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Who teaches it'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dr. Meenakshi Iyer').last);
      await tester.pumpAndSettle();

      // Each field is found by its own label: the labels live in the decoration, so the field is
      // reached through the AppTextField that carries it.
      Finder fieldLabelled(String label) => find.descendant(
        of: find.ancestor(of: find.text(label), matching: find.byType(AppTextField)),
        matching: find.byType(TextField),
      );

      await tester.enterText(fieldLabelled('Title · Required'), 'Reading dignities');
      await tester.pumpAndSettle();
      await tester.enterText(fieldLabelled('How long (minutes)'), '90');
      await tester.pumpAndSettle();
      // The built-in room is the default; this class runs on an outside meeting instead.
      await tester.scrollUntilVisible(
        find.text('Where the class runs'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Where the class runs'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Outside meeting link').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Meeting link'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(fieldLabelled('Meeting link'), 'https://meet.example.com/dignities');
      await tester.pumpAndSettle();

      final button = find.widgetWithText(AppButton, 'Schedule it');
      await tester.scrollUntilVisible(button, 400, scrollable: find.byType(Scrollable).first);
      expect(tester.widget<AppButton>(button).onPressed, isNotNull);
      await tester.tap(button);
      await tester.pumpAndSettle();

      final sent = adapter.requests.where((r) => r.method == 'POST').last;
      expect(sent.path, '/live');
      final body = sent.data! as Map<String, Object?>;
      expect(body['title'], 'Reading dignities');
      expect(body['durationMin'], 90);
      expect((body['meeting']! as Map)['link'], 'https://meet.example.com/dignities');
      expect(body['startsAt'], isNotNull);
    });

    testWidgets('an edit opens on the class as the academy has it', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffLiveEdit('l1'), now: longBefore());
      await tester.pumpAndSettle();

      // The page's name is the shell's app bar; the body opens on the form's first section.
      expect(find.text('The class'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Reading dignities in real charts'), findsOneWidget);
      // Its capacity: the duration happens to be 40 minutes too, so the field is named.
      expect(
        find.descendant(
          of: find.ancestor(of: find.text('Seats (optional)'), matching: find.byType(AppTextField)),
          matching: find.byType(TextField),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(AppButton, 'Save'), findsOneWidget);
    });

    testWidgets('a refused write shows the academy\'s words on each field it named', (
      tester,
    ) async {
      answering(
        write: const {
          'message': 'Check the class details before saving.',
          'issues': [
            {'field': 'title', 'message': 'Give the class a title of at least 3 characters.'},
            {'field': 'duration', 'message': 'A class runs between 15 minutes and 4 hours.'},
          ],
        },
        writeStatus: 409,
      );

      await pump(tester, at: AppRoutes.staffLiveEdit('l1'), now: longBefore());
      await tester.pumpAndSettle();
      final button = find.widgetWithText(AppButton, 'Save');
      await tester.scrollUntilVisible(button, 400, scrollable: find.byType(Scrollable).first);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Give the class a title of at least 3 characters.'), findsOneWidget);
      expect(find.text('A class runs between 15 minutes and 4 hours.'), findsOneWidget);
    });

    testWidgets('an agenda longer than the class is called out', (tester) async {
      final long = _json('live-class');
      (long['liveClass']! as Map<String, dynamic>)
        ..['durationMin'] = 20
        ..['agenda'] = const [
          {'title': 'Recap', 'minutes': 30},
        ];
      answering(detail: long);

      await pump(tester, at: AppRoutes.staffLiveEdit('l1'), now: longBefore());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('longer than the class'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.textContaining('runs 30 minutes'), findsOneWidget);
      final button = find.widgetWithText(AppButton, 'Save');
      await tester.scrollUntilVisible(button, 400, scrollable: find.byType(Scrollable).first);
      expect(tester.widget<AppButton>(button).onPressed, isNull);
    });
  });
}
