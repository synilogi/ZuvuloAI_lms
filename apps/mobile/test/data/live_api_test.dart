import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/features/live/live.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/public_harness.dart';
import '../helpers/test_config.dart';

void main() {
  late FakeAdapter adapter;
  late LiveApi api;

  setUp(() {
    adapter = FakeAdapter();
    api = LiveApi(
      ApiClient(
        config: testConfig(),
        tokenStore: FakeTokenStore('jwt'),
        logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
        adapter: adapter,
        logRequests: false,
      ),
    );
  });

  test('the schedule is read for whoever is signed in — no student is ever named', () async {
    adapter.enqueueJson(fixture('live/learner.json'));

    final schedule = await api.schedule();

    expect(adapter.lastRequest.method, 'GET');
    expect(adapter.lastRequest.path, '/live/learner');
    expect(adapter.lastRequest.queryParameters, isEmpty);
    expect(schedule.upcoming, isNotEmpty);
  });

  test('registering sends what the learner wants, and nothing else — the academy counts', () async {
    adapter.enqueueJson(const {'registered': true, 'spotsLeft': 39});

    final seat = await api.register('live 1/2', registered: true);

    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.path, '/live/live%201%2F2/register');
    // The wish itself, so a double tap or a retry cannot flip the seat back.
    expect(adapter.lastRequest.data, {'registered': true});
    expect(seat.registered, isTrue);
    expect(seat.spotsLeft, 39);
  });

  test('the same route gives the seat up again, by saying so', () async {
    adapter.enqueueJson(const {'registered': false, 'spotsLeft': 40});

    final seat = await api.register('l1', registered: false);

    expect(adapter.lastRequest.data, {'registered': false});
    expect(seat.registered, isFalse);
    expect(seat.spotsLeft, 40);
  });

  test('joining answers with the room, or with the outside meeting\'s link', () async {
    adapter.enqueueJson(const {'kind': 'external', 'link': 'https://zoom.us/j/1'});

    final answer = await api.join('l1');

    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.path, '/live/l1/join');
    expect(answer.kind, MeetingKind.external);
    expect(answer.link, 'https://zoom.us/j/1');
  });
}
