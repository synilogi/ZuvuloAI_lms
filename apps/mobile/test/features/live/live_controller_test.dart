import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/platform/live_room.dart';
import 'package:syniastrolms_mobile/features/live/live.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

const _room = {
  'kind': 'room',
  'room': {
    'provider': 'jitsi',
    'domain': 'meet.jit.si',
    'room': 'shubh-abc',
    'displayName': 'Ananya Rao',
    'moderator': false,
  },
};

void main() {
  late FakeAdapter adapter;
  late List<LiveRoomClosed?> closers;

  setUp(() {
    adapter = FakeAdapter();
    closers = [];
  });

  ProviderContainer container() {
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: publicScope(
        adapter: adapter,
        signedInAs: learner(),
        // The room opens and stays open; the test decides when it closes.
        openLiveRoom: (room, {onClosed}) async => closers.add(onClosed),
        child: const SizedBox.shrink(),
      ).overrides,
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Answers every request with [body] once [gate] completes.
  void answerAfter(Future<void> gate, Object body) => adapter.handler = (options) async {
    await gate;
    return FakeAdapter.jsonResponse(body);
  };

  group('a seat request', () {
    test('outlived by its screen ends quietly, without touching what was disposed', () async {
      final gate = Completer<void>();
      answerAfter(gate.future, const {'registered': true, 'spotsLeft': 3});
      final c = container();
      final watching = c.listen(liveRegistrationProvider, (_, _) {});

      final asked = c.read(liveRegistrationProvider.notifier).setRegistered('l1', registered: true);
      // The learner leaves the screen while the academy is answering.
      watching.close();
      await c.pump();
      gate.complete();

      expect(await asked, isTrue);
    });

    test('a refusal outlived by its screen ends quietly too', () async {
      final gate = Completer<void>();
      adapter.handler = (options) async {
        await gate.future;
        return FakeAdapter.jsonResponse({'message': 'This class is full.'}, status: 409);
      };
      final c = container();
      final watching = c.listen(liveRegistrationProvider, (_, _) {});

      final asked = c.read(liveRegistrationProvider.notifier).setRegistered('l1', registered: true);
      watching.close();
      await c.pump();
      gate.complete();

      expect(await asked, isFalse);
    });

    test('sends the wish itself, and takes one at a time', () async {
      final gate = Completer<void>();
      answerAfter(gate.future, const {'registered': false, 'spotsLeft': 4});
      final c = container();
      c.listen(liveRegistrationProvider, (_, _) {});
      final seats = c.read(liveRegistrationProvider.notifier);

      final first = seats.setRegistered('l1', registered: false);
      expect(c.read(liveRegistrationProvider).busyFor, 'l1');
      expect(await seats.setRegistered('l1', registered: false), isFalse, reason: 'one at a time');
      gate.complete();
      expect(await first, isTrue);

      final register = adapter.requests.where((r) => r.path == '/live/l1/register').toList();
      expect(register, hasLength(1));
      expect(register.single.data, {'registered': false});
      expect(c.read(liveRegistrationProvider).seats['l1']?.registered, isFalse);
    });
  });

  group('joining', () {
    test('outlived by its screen opens nothing', () async {
      final gate = Completer<void>();
      answerAfter(gate.future, _room);
      final c = container();
      final watching = c.listen(liveJoinProvider, (_, _) {});

      final joined = c.read(liveJoinProvider.notifier).join('l1');
      watching.close();
      await c.pump();
      gate.complete();

      expect(await joined, isFalse);
      expect(closers, isEmpty, reason: 'no room opens behind a screen that is gone');
    });

    test('a room that closes after its screen has gone is not reported to anyone', () async {
      adapter.handler = (options) async => options.path.endsWith('/join')
          ? FakeAdapter.jsonResponse(_room)
          : FakeAdapter.jsonResponse(const <String, Object>{});
      final c = container();
      final watching = c.listen(liveJoinProvider, (_, _) {});

      expect(await c.read(liveJoinProvider.notifier).join('l1'), isTrue);
      watching.close();
      await c.pump();

      // The SDK's own event, long after: it must not reach a disposed controller.
      expect(() => closers.single?.call(connectionLost: true), returnsNormally);
    });

    test('a room that drops the learner is reported once', () async {
      adapter.handler = (options) async => options.path.endsWith('/join')
          ? FakeAdapter.jsonResponse(_room)
          : FakeAdapter.jsonResponse(const <String, Object>{});
      final c = container();
      final seen = <LiveJoinProblem?>[];
      c.listen(liveJoinProvider, (_, next) => seen.add(next.problem));

      await c.read(liveJoinProvider.notifier).join('l1');
      closers.single?.call(connectionLost: true);

      expect(c.read(liveJoinProvider).problem, LiveJoinProblem.connectionLost);
      expect(seen.where((p) => p == LiveJoinProblem.connectionLost), hasLength(1));
    });

    test('an answer that is neither a room nor an https link opens nothing', () async {
      adapter.handler = (options) async =>
          FakeAdapter.jsonResponse(const {'kind': 'external', 'link': 'javascript:alert(1)'});
      final c = container();
      c.listen(liveJoinProvider, (_, _) {});

      expect(await c.read(liveJoinProvider.notifier).join('l1'), isFalse);
      expect(c.read(liveJoinProvider).problem, LiveJoinProblem.linkUnusable);
    });

    test('a refusal is the academy\'s own words', () async {
      adapter.handler = (options) async => options.path.endsWith('/join')
          ? FakeAdapter.jsonResponse({
              'message':
                  'Your access to this course has ended, so its live classes are closed to you.',
            }, status: 403)
          : FakeAdapter.jsonResponse(const <String, Object>{});
      final c = container();
      c.listen(liveJoinProvider, (_, _) {});

      expect(await c.read(liveJoinProvider.notifier).join('l1'), isFalse);
      expect(
        c.read(liveJoinProvider).failure?.message,
        contains('access to this course has ended'),
      );
    });
  });
}
