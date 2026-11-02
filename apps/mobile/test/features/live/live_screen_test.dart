import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/core/platform/external_link.dart';
import 'package:syniastrolms_mobile/core/platform/live_room.dart';
import 'package:syniastrolms_mobile/features/live/live.dart';
import 'package:syniastrolms_mobile/features/media/media.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

/// The captured schedule, with the one upcoming class moved relative to **now** so a test can put
/// it in any phase without waiting for the clock.
Map<String, dynamic> _schedule({
  Duration startsIn = const Duration(days: 2),
  int durationMin = 60,
  Map<String, Object?>? meeting,
  bool registered = false,
}) {
  final raw = jsonDecode(jsonEncode(fixture('live/learner.json'))) as Map<String, dynamic>;
  final row = (raw['upcoming']! as List<dynamic>).first as Map<String, dynamic>;
  final cls = row['liveClass']! as Map<String, dynamic>;
  cls['startsAt'] = DateTime.now().toUtc().add(startsIn).toIso8601String();
  cls['durationMin'] = durationMin;
  if (meeting != null) cls['meeting'] = meeting;
  row['registered'] = registered;
  return raw;
}

/// An outside meeting as a learner's schedule carries it: the site it is on, never the link — that
/// comes only from `POST /live/:id/join` (`forLearner` in apps/api/src/lib/mapLive.ts).
const _external = {'kind': 'external', 'linkHost': 'meet.example.com'};

/// A class that is over, with this learner's record of it, as `history` carries it.
Map<String, dynamic> _past({
  required String id,
  required String title,
  required bool? attended,
  Map<String, Object?> meeting = const {'kind': 'room'},
}) {
  final raw = jsonDecode(jsonEncode(fixture('live/learner.json'))) as Map<String, dynamic>;
  final row = (raw['upcoming']! as List<dynamic>).first as Map<String, dynamic>;
  final cls = row['liveClass']! as Map<String, dynamic>;
  cls['id'] = id;
  cls['title'] = title;
  cls['startsAt'] = DateTime.now().toUtc().subtract(const Duration(days: 3)).toIso8601String();
  cls['meeting'] = meeting;
  if (meeting['kind'] == 'room') {
    cls['startedAt'] = cls['startsAt'];
    cls['endedAt'] = DateTime.now().toUtc().subtract(const Duration(days: 2)).toIso8601String();
  }
  row
    ..remove('registered')
    ..['phase'] = 'recording-expired';
  if (attended != null) row['attended'] = attended;
  return row;
}

void main() {
  late FakeAdapter adapter;
  late List<Uri> opened;
  late List<LiveRoomJoin> rooms;

  /// The clock the screens read, so a test can move time instead of waiting for it.
  late DateTime now;

  setUp(() {
    adapter = FakeAdapter();
    opened = [];
    rooms = [];
    now = DateTime.now().toUtc();
  });

  Future<GoRouter> pumpLive(
    WidgetTester tester, {
    OpenExternalLink? openExternalLink,
    OpenLiveRoom? openLiveRoom,
  }) => pumpPublicRouter(
    tester,
    adapter: adapter,
    signedInAs: learner(),
    initialLocation: AppRoutes.live,
    size: const Size(400, 1800),
    openExternalLink: openExternalLink ?? (link) async => opened.add(link),
    openLiveRoom: openLiveRoom ?? (room, {onClosed}) async => rooms.add(room),
    clock: () => now,
    routes: [
      GoRoute(
        path: AppRoutes.live,
        builder: (_, _) => const Scaffold(body: SafeArea(child: LiveScreen())),
      ),
      GoRoute(
        path: AppRoutes.liveClassPattern,
        builder: (_, state) => Scaffold(
          body: SafeArea(
            child: LiveDetailScreen(liveClassId: state.pathParameters['liveId'] ?? ''),
          ),
        ),
      ),
      GoRoute(path: AppRoutes.learnCoursePattern, builder: (_, _) => const Placeholder()),
    ],
  );

  testWidgets('the schedule shows what is coming and what was recorded', (tester) async {
    adapter.enqueueJson(_schedule());

    await pumpLive(tester);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(SectionHeader, 'Upcoming'), findsOneWidget);
    expect(find.widgetWithText(SectionHeader, 'Recordings'), findsOneWidget);
    expect(find.text('Reading dignities in real charts'), findsOneWidget);
    expect(find.text('With Dr. Meenakshi Iyer'), findsWidgets);
    expect(find.byType(LiveClassCard), findsWidgets);
    // Nothing is live, so there is no "Live now" section.
    expect(find.widgetWithText(SectionHeader, 'Live now'), findsNothing);
  });

  testWidgets('a class in the built-in room waits for its host, then opens in the app', (
    tester,
  ) async {
    adapter.enqueueJson(_schedule(startsIn: const Duration(minutes: -5)));

    await pumpLive(tester);
    await tester.pumpAndSettle();

    // In its slot, but the host has not opened the room: no way in yet, and it says who it waits for.
    expect(find.widgetWithText(SectionHeader, 'Live now'), findsNothing);
    expect(find.textContaining('Waiting for Dr. Meenakshi Iyer to start'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Join the class'), findsNothing);

    // The host starts: the next read of the schedule carries startedAt, and Join opens the room here.
    final started = _schedule(startsIn: const Duration(minutes: -5));
    final row = (started['upcoming']! as List<dynamic>).first as Map<String, dynamic>;
    (row['liveClass']! as Map<String, dynamic>)['startedAt'] = DateTime.now()
        .toUtc()
        .toIso8601String();
    adapter.enqueueJson(started);
    await tester.pump(hostWaitPoll);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SectionHeader, 'Live now'), findsOneWidget);

    adapter
      ..enqueueJson({
        'kind': 'room',
        'room': {
          'provider': 'jitsi',
          'domain': 'meet.jit.si',
          'room': 'shubh-abc',
          'subject': 'Reading dignities in real charts',
          'displayName': 'Ananya Rao',
          'moderator': false,
          'recording': false,
        },
      })
      ..enqueueJson(started);
    await tester.tap(find.widgetWithText(AppButton, 'Join the class').first);
    await tester.pumpAndSettle();

    expect(adapter.requests.map((r) => r.path), contains(endsWith('/join')));
    expect(rooms.single.room, 'shubh-abc');
    expect(rooms.single.serverUrl.toString(), 'https://meet.jit.si');
    expect(opened, isEmpty, reason: 'the built-in room never leaves for the browser');
  });

  testWidgets('a room the host ends early stops offering Join without a pull to refresh', (
    tester,
  ) async {
    // In session: the host started it five minutes ago.
    Map<String, dynamic> withRoom({String? endedAt}) {
      final raw = _schedule(startsIn: const Duration(minutes: -5));
      final cls =
          ((raw['upcoming']! as List<dynamic>).first as Map<String, dynamic>)['liveClass']!
              as Map<String, dynamic>;
      cls['startedAt'] = DateTime.now()
          .toUtc()
          .subtract(const Duration(minutes: 5))
          .toIso8601String();
      if (endedAt != null) cls['endedAt'] = endedAt;
      return raw;
    }

    adapter.enqueueJson(withRoom());
    await pumpLive(tester);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppButton, 'Join the class'), findsOneWidget);

    // The host ends the class well inside its slot; the clock alone would still call it live.
    adapter.enqueueJson(withRoom(endedAt: DateTime.now().toUtc().toIso8601String()));
    await tester.pump(hostWaitPoll);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppButton, 'Join the class'), findsNothing);
    expect(find.widgetWithText(SectionHeader, 'Live now'), findsNothing);
  });

  testWidgets('Join is offered only inside the window, and names the host first', (tester) async {
    adapter.enqueueJson(_schedule(startsIn: const Duration(minutes: 10), meeting: _external));

    await pumpLive(tester);
    await tester.pumpAndSettle();

    final join = find.widgetWithText(AppButton, 'Join the class').first;
    expect(
      tester.widget<AppButton>(join).onPressed,
      isNotNull,
      reason: 'ten minutes away is inside the quarter-hour window',
    );

    // The schedule names the site, and nothing has been opened or asked for yet.
    final readsBefore = adapter.requests.length;
    await tester.tap(join);
    await tester.pumpAndSettle();
    expect(find.text('Open the meeting?'), findsOneWidget);
    expect(find.text('This opens meet.example.com outside the app.'), findsOneWidget);
    expect(
      adapter.requests.length,
      readsBefore,
      reason: 'nothing is asked until the learner agrees',
    );

    // The academy is asked first — the link is handed out only here — then that link opens.
    adapter.enqueueJson({'kind': 'external', 'link': 'https://meet.example.com/dignities'});
    adapter.enqueueJson(_schedule(startsIn: const Duration(minutes: 10), meeting: _external));
    await tester.tap(
      find.descendant(of: find.byType(AppDialog), matching: find.text('Join the class')),
    );
    await tester.pumpAndSettle();

    expect(adapter.requests.map((r) => r.path), contains(endsWith('/join')));
    expect(opened.single.toString(), 'https://meet.example.com/dignities');
  });

  testWidgets('before the window opens there is a seat to take, not a way in', (tester) async {
    adapter.enqueueJson(_schedule(startsIn: const Duration(minutes: 40), meeting: _external));

    final router = await pumpLive(tester);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppButton, 'Join the class'), findsNothing);
    expect(find.widgetWithText(AppButton, 'Save my seat'), findsOneWidget);
    expect(opened, isEmpty);

    // On the class's own page it also says when the room opens.
    final row = tester.widget<LiveClassCard>(find.byType(LiveClassCard).first).row;
    router.go(AppRoutes.liveClass(row.liveClass.id));
    await tester.pumpAndSettle();
    expect(find.text('Join opens 15 minutes before the start.'), findsOneWidget);
  });

  testWidgets('taking a seat asks the academy, and shows the seats it says are left', (
    tester,
  ) async {
    adapter.enqueueJson(_schedule());

    await pumpLive(tester);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppButton, 'Save my seat'), findsOneWidget);
    adapter
      ..enqueueJson(const {'registered': true, 'spotsLeft': 39})
      ..enqueueJson(_schedule(registered: true));
    await tester.tap(find.widgetWithText(AppButton, 'Save my seat'));
    await tester.pumpAndSettle();

    expect(adapter.requests.map((r) => r.path), contains(endsWith('/register')));
    expect(find.widgetWithText(AppButton, 'Give up my seat'), findsOneWidget);
    expect(find.text('39 seats left'), findsOneWidget);
  });

  testWidgets('a class the academy will not seat says why, in its own words', (tester) async {
    adapter.enqueueJson(_schedule());

    await pumpLive(tester);
    await tester.pumpAndSettle();

    adapter.enqueueJson({'message': 'This class is full.'}, status: 409);
    await tester.tap(find.widgetWithText(AppButton, 'Save my seat'));
    await tester.pumpAndSettle();

    expect(find.text('This class is full.'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Save my seat'), findsOneWidget);
  });

  testWidgets('opening one shows what it covers and who teaches it', (tester) async {
    adapter.enqueueJson(_schedule());

    final router = await pumpLive(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reading dignities in real charts'));
    await tester.pumpAndSettle();

    expect(locationOf(router), startsWith('/live/'));
    expect(find.text('What happens'), findsOneWidget);
    expect(find.text('Recap of dignity rules · 10 min'), findsOneWidget);
    expect(find.textContaining('A live walkthrough'), findsOneWidget);
    expect(find.textContaining('40 seats'), findsWidgets);
  });

  testWidgets('a recording with no kept file says what is kept, and offers no way to play it', (
    tester,
  ) async {
    adapter.enqueueJson(_schedule());

    final router = await pumpLive(tester);
    await tester.pumpAndSettle();
    final recorded = tester
        .widgetList<LiveClassCard>(find.byType(LiveClassCard))
        .firstWhere((card) => card.row.liveClass.recording != null);
    router.go(AppRoutes.liveClass(recorded.row.liveClass.id));
    await tester.pumpAndSettle();

    expect(find.textContaining('Recording · '), findsOneWidget);
    expect(find.textContaining('Recording available until'), findsOneWidget);
    expect(find.text('This recording can’t be played here.'), findsOneWidget);
    expect(find.byType(AppVideoPlayer), findsNothing);
  });

  testWidgets('a class that is not in the schedule offers the way back', (tester) async {
    adapter.enqueueJson(_schedule());

    final router = await pumpLive(tester);
    await tester.pumpAndSettle();
    router.go(AppRoutes.liveClass('nope'));
    await tester.pumpAndSettle();

    expect(find.text('This class is not in your schedule.'), findsOneWidget);
  });

  testWidgets('a learner with nothing scheduled is told so', (tester) async {
    adapter.enqueueJson(const <String, Object>{});

    await pumpLive(tester);
    await tester.pumpAndSettle();

    expect(find.text('No live classes scheduled'), findsOneWidget);
  });

  testWidgets('a failed read offers a retry', (tester) async {
    adapter
      ..enqueueJson({'message': 'Server error.'}, status: 500)
      ..enqueueJson(_schedule());

    await pumpLive(tester);
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(LiveClassCard), findsWidgets);
  });

  testWidgets('a class opens its room as the clock reaches it, with nothing asked again', (
    tester,
  ) async {
    adapter.enqueueJson(_schedule(startsIn: const Duration(minutes: 16), meeting: _external));

    await pumpLive(tester);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppButton, 'Join the class'), findsNothing);
    final readsSoFar = adapter.requests.length;

    // Two minutes later — one tick of the live clock is all it takes.
    now = now.add(const Duration(minutes: 2));
    await tester.pump(livePhaseTick);
    await tester.pumpAndSettle();

    expect(
      tester.widget<AppButton>(find.widgetWithText(AppButton, 'Join the class').first).onPressed,
      isNotNull,
      reason: 'the room opens a quarter of an hour before the start',
    );
    expect(
      adapter.requests.length,
      readsSoFar,
      reason: 'the phase moved on from the clock alone — the server was not asked again',
    );
  });

  /// Every read answered by its path, so a test does not depend on how many times the schedule is
  /// read again; [onJoin] answers `POST /live/:id/join` and [onRegister] the seat.
  void serve(
    Map<String, dynamic> Function() schedule, {
    Future<ResponseBody> Function(RequestOptions options)? onJoin,
    Future<ResponseBody> Function(RequestOptions options)? onRegister,
  }) {
    adapter.handler = (options) async {
      if (options.path.endsWith('/join') && onJoin != null) return onJoin(options);
      if (options.path.endsWith('/register') && onRegister != null) return onRegister(options);
      return FakeAdapter.jsonResponse(schedule());
    };
  }

  group('a learner whose classes are all over', () {
    testWidgets('still sees their record, in words that claim no more than the academy knows', (
      tester,
    ) async {
      adapter.enqueueJson({
        'history': [
          _past(id: 'past_joined_1', title: 'Joined in the room', attended: true),
          _past(id: 'past_missed_1', title: 'Never came', attended: false),
          _past(
            id: 'past_link_01',
            title: 'Opened an outside meeting',
            attended: true,
            meeting: _external,
          ),
        ],
      });

      await pumpLive(tester);
      await tester.pumpAndSettle();

      expect(find.text('No live classes scheduled'), findsNothing);
      expect(find.widgetWithText(SectionHeader, 'Your attendance'), findsOneWidget);
      expect(find.text('Joined in the room'), findsOneWidget);
      // Joining the built-in room is what the academy saw — not a verified "Attended".
      expect(find.text('Joined'), findsOneWidget);
      expect(find.text('Attended'), findsNothing);
      expect(find.text('Missed'), findsOneWidget);
      // An outside meeting happens where the academy cannot see.
      expect(find.text('Opened the link'), findsOneWidget);
    });

    testWidgets('a past class with no record shows no badge at all', (tester) async {
      adapter.enqueueJson({
        'history': [_past(id: 'past_none_01', title: 'No record', attended: null)],
      });

      await pumpLive(tester);
      await tester.pumpAndSettle();

      expect(find.text('No record'), findsOneWidget);
      expect(find.text('Missed'), findsNothing, reason: 'no record is not a missed class');
      expect(find.text('Joined'), findsNothing);
    });

    test('is not an empty schedule', () {
      final schedule = LiveSchedule.fromJson({
        'history': [_past(id: 'past_joined_1', title: 'Joined', attended: true)],
      });
      expect(schedule.isEmpty, isFalse);
      expect(const LiveSchedule().isEmpty, isTrue);
    });
  });

  testWidgets('a background read that fails keeps the schedule on screen, and says so', (
    tester,
  ) async {
    // In session, so the screen reads the schedule again every few seconds.
    Map<String, dynamic> inSession() {
      final raw = _schedule(startsIn: const Duration(minutes: -5));
      final cls =
          ((raw['upcoming']! as List<dynamic>).first as Map<String, dynamic>)['liveClass']!
              as Map<String, dynamic>;
      cls['startedAt'] = DateTime.now()
          .toUtc()
          .subtract(const Duration(minutes: 5))
          .toIso8601String();
      return raw;
    }

    adapter.enqueueJson(inSession());
    await pumpLive(tester);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppButton, 'Join the class'), findsOneWidget);

    adapter.enqueueJson({'message': 'Server error.'}, status: 500);
    await tester.pump(hostWaitPoll);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsNothing, reason: 'the Live tab is not replaced');
    expect(find.widgetWithText(AppButton, 'Join the class'), findsOneWidget);
    expect(find.text('Couldn’t refresh. Showing the last update.'), findsOneWidget);

    // It goes on trying, and the note goes once a read succeeds.
    adapter.enqueueJson(inSession());
    await tester.pump(hostWaitPoll);
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t refresh. Showing the last update.'), findsNothing);
    expect(find.widgetWithText(AppButton, 'Join the class'), findsOneWidget);
  });

  group('an outside meeting', () {
    Map<String, dynamic> soon() =>
        _schedule(startsIn: const Duration(minutes: 10), meeting: _external);

    /// Taps Join and agrees to leave. [settle] false when the join stays open behind a second
    /// question — its button spins meanwhile, so the frames never settle.
    Future<void> tapJoinAndAgree(WidgetTester tester, {bool settle = true}) async {
      await tester.tap(find.widgetWithText(AppButton, 'Join the class').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(AppDialog), matching: find.text('Join the class')),
      );
      if (settle) {
        await tester.pumpAndSettle();
        return;
      }
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('that nothing on the phone can open says so', (tester) async {
      serve(
        soon,
        onJoin: (_) async =>
            FakeAdapter.jsonResponse({'kind': 'external', 'link': 'https://meet.example.com/x'}),
      );
      final tried = <Uri>[];
      // The browser's own answer when nothing on the phone took the link.
      Future<bool> nothingTakesIt(Uri link) async {
        tried.add(link);
        return false;
      }

      await pumpLive(tester, openExternalLink: nothingTakesIt);
      await tester.pumpAndSettle();
      await tapJoinAndAgree(tester);

      expect(tried.single.toString(), 'https://meet.example.com/x');
      expect(
        find.text(
          'The meeting link couldn’t be opened on this phone. Check that a browser is installed, '
          'then try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('whose link is on another site than the one named is confirmed again', (
      tester,
    ) async {
      serve(
        soon,
        onJoin: (_) async =>
            FakeAdapter.jsonResponse({'kind': 'external', 'link': 'https://zoom.us/j/123'}),
      );

      await pumpLive(tester);
      await tester.pumpAndSettle();
      await tapJoinAndAgree(tester, settle: false);

      // The learner agreed to meet.example.com; the academy's link is on zoom.us.
      expect(find.text('The meeting is now on zoom.us. This opens it outside the app.'), findsOne);
      expect(opened, isEmpty);
      await tester.tap(find.descendant(of: find.byType(AppDialog), matching: find.text('Cancel')));
      await tester.pumpAndSettle();
      expect(opened, isEmpty, reason: 'declined, so nothing opens');

      // Agreeing to the real site opens it.
      await tapJoinAndAgree(tester, settle: false);
      await tester.tap(
        find.descendant(of: find.byType(AppDialog), matching: find.text('Join the class')),
      );
      await tester.pumpAndSettle();
      expect(opened.single.toString(), 'https://zoom.us/j/123');
    });

    testWidgets('whose answer holds no https link opens nothing, and says so', (tester) async {
      serve(
        soon,
        onJoin: (_) async =>
            FakeAdapter.jsonResponse({'kind': 'external', 'link': 'http://meet.example.com/x'}),
      );

      await pumpLive(tester);
      await tester.pumpAndSettle();
      await tapJoinAndAgree(tester);

      expect(opened, isEmpty);
      expect(
        find.text('This class’s meeting link can’t be opened. Ask your LMS for a new one.'),
        findsOneWidget,
      );
    });

    testWidgets('whose site the academy could not name offers no way in', (tester) async {
      adapter.enqueueJson(
        _schedule(startsIn: const Duration(minutes: 10), meeting: const {'kind': 'external'}),
      );

      await pumpLive(tester);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppButton, 'Join the class'), findsNothing);
      expect(find.textContaining('The class couldn’t open on this phone'), findsOneWidget);
    });
  });

  testWidgets('a seat is asked for, or given up, by saying which — and once at a time', (
    tester,
  ) async {
    final answer = Completer<ResponseBody>();
    var registered = false;
    final sent = <Object?>[];
    serve(
      () => _schedule(registered: registered),
      onRegister: (options) {
        sent.add(options.data);
        return answer.future;
      },
    );

    await pumpLive(tester);
    await tester.pumpAndSettle();

    AppButton seatButton() => tester.widget<AppButton>(
      find.descendant(of: find.byType(RegisterButton), matching: find.byType(AppButton)),
    );

    await tester.tap(find.widgetWithText(AppButton, 'Save my seat'));
    await tester.pump();
    // While the academy is answering, the button is busy and takes no second tap.
    expect(seatButton().onPressed, isNull);
    expect(seatButton().busy, isTrue);

    registered = true;
    answer.complete(FakeAdapter.jsonResponse(const {'registered': true, 'spotsLeft': 39}));
    await tester.pumpAndSettle();
    expect(sent, [
      {'registered': true},
    ]);
    expect(find.widgetWithText(AppButton, 'Give up my seat'), findsOneWidget);

    // Giving it up says so: the same route, the other wish.
    adapter.handler = null;
    registered = false;
    adapter
      ..enqueueJson(const {'registered': false, 'spotsLeft': 40})
      ..enqueueJson(_schedule());
    await tester.tap(find.widgetWithText(AppButton, 'Give up my seat'));
    await tester.pumpAndSettle();
    final giveUp = adapter.requests.lastWhere((r) => r.path.endsWith('/register'));
    expect(giveUp.data, {'registered': false});
    expect(find.widgetWithText(AppButton, 'Save my seat'), findsOneWidget);
  });

  group('the built-in room', () {
    Map<String, dynamic> started() {
      final raw = _schedule(startsIn: const Duration(minutes: -5));
      final cls =
          ((raw['upcoming']! as List<dynamic>).first as Map<String, dynamic>)['liveClass']!
              as Map<String, dynamic>;
      cls['startedAt'] = DateTime.now()
          .toUtc()
          .subtract(const Duration(minutes: 5))
          .toIso8601String();
      return raw;
    }

    Future<ResponseBody> room(RequestOptions _) async => FakeAdapter.jsonResponse({
      'kind': 'room',
      'room': {
        'provider': 'jitsi',
        'domain': 'meet.jit.si',
        'room': 'shubh-abc',
        'subject': 'Reading dignities in real charts',
        'displayName': 'Ananya Rao',
        'email': 'learner@example.test',
        'moderator': false,
        'recording': false,
      },
    });

    testWidgets('that drops the learner says so, and how to get back in', (tester) async {
      serve(started, onJoin: room);

      await pumpLive(
        tester,
        // The video service ends the conference with an error, as it does when the connection drops.
        openLiveRoom: (room, {onClosed}) async {
          rooms.add(room);
          onClosed?.call(connectionLost: true);
        },
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Join the class').first);
      await tester.pumpAndSettle();

      expect(rooms.single.room, 'shubh-abc');
      expect(
        find.text('The class connection was lost. If the class is still on, join again.'),
        findsOneWidget,
      );
    });

    testWidgets('that the learner leaves says nothing', (tester) async {
      serve(started, onJoin: room);

      await pumpLive(
        tester,
        openLiveRoom: (room, {onClosed}) async {
          rooms.add(room);
          onClosed?.call();
        },
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Join the class').first);
      await tester.pumpAndSettle();

      expect(rooms, hasLength(1));
      expect(find.textContaining('connection was lost'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
