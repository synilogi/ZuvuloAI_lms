import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/features/staff_live/staff_live.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/public_harness.dart';
import '../helpers/test_config.dart';

Map<String, dynamic> _liveClass() =>
    (fixture('staff/live-class.json')! as Map<String, dynamic>)['liveClass']!
        as Map<String, dynamic>;

void main() {
  late FakeAdapter adapter;
  late StaffLiveApi api;

  setUp(() {
    adapter = FakeAdapter();
    api = StaffLiveApi(
      ApiClient(
        config: testConfig(),
        tokenStore: FakeTokenStore('jwt'),
        logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
        adapter: adapter,
        logRequests: false,
      ),
    );
  });

  LiveClassForm form() => LiveClassForm(
    courseId: 'c1',
    title: 'Reading dignities',
    instructorId: 'i1',
    startsAt: DateTime.utc(2026, 10, 5, 12, 30),
    durationMin: 60,
    capacity: 40,
    description: 'What it covers.',
    agenda: const [AgendaItem(title: 'Recap', minutes: 10)],
    meetingKind: MeetingKind.external,
    meetingLink: 'https://meet.example.com/x',
    reminders: const [1440, 60],
  );

  test('the schedule asks for one page and the view on screen', () async {
    adapter.enqueueJson(fixture('staff/live-schedule.json'));

    await api.schedule(view: 'upcoming');

    expect(adapter.lastRequest.method, 'GET');
    expect(adapter.lastRequest.path, '/live');
    expect(adapter.lastRequest.queryParameters, {'view': 'upcoming', 'page': 1, 'pageSize': 20});
  });

  test('every filter travels as the route names it', () async {
    adapter.enqueueJson(fixture('staff/live-schedule.json'));

    await api.schedule(
      view: 'history',
      search: 'dignities',
      courseId: 'c1',
      instructorId: 'i1',
      page: 2,
    );

    expect(adapter.lastRequest.queryParameters, {
      'view': 'history',
      'search': 'dignities',
      'courseId': 'c1',
      'instructorId': 'i1',
      'page': 2,
      'pageSize': 20,
    });
  });

  test('a class id is escaped into the path', () async {
    adapter.enqueueJson(fixture('staff/live-class.json'));

    await api.liveClass('a b/c');

    expect(adapter.lastRequest.path, '/live/a%20b%2Fc');
  });

  test('scheduling sends the whole class, with the link field the write path stores', () async {
    adapter.enqueueJson(_liveClass());

    await api.create(form());

    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.path, '/live');
    final body = adapter.lastRequest.data! as Map<String, Object?>;
    expect(body['courseId'], 'c1');
    expect(body['title'], 'Reading dignities');
    expect(body['startsAt'], '2026-10-05T12:30:00.000Z');
    expect(body['durationMin'], 60);
    expect(body['capacity'], 40);
    expect(body['reminders'], const [1440, 60]);
    expect((body['meeting']! as Map)['link'], 'https://meet.example.com/x');
    expect((body['agenda']! as List).single, {'title': 'Recap', 'minutes': 10});
    // The academy works the rest out: the app sends no phase, no registered count and no id.
    for (final field in ['phase', 'registered', 'id', 'cancelled']) {
      expect(body.containsKey(field), isFalse, reason: field);
    }
  });

  test('saving sends the whole object, because a PATCH takes nothing less', () async {
    adapter.enqueueJson(_liveClass());

    await api.save('l1', form());

    expect(adapter.lastRequest.method, 'PATCH');
    expect(adapter.lastRequest.path, '/live/l1');
    expect(
      (adapter.lastRequest.data! as Map).keys,
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
  });

  test('cancelling carries the reason the learners will read', () async {
    adapter.enqueueJson(_liveClass());

    await api.cancel('l1', reason: 'The instructor is unwell.');

    expect(adapter.lastRequest.path, '/live/l1/cancel');
    expect(adapter.lastRequest.data, {'reason': 'The instructor is unwell.'});
  });

  test('a reminder now asks for nothing and reports the academy\'s count', () async {
    adapter.enqueueJson(const {'sent': 7});

    final sent = await api.remind('l1');

    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.path, '/live/l1/remind');
    expect(adapter.lastRequest.data, isNull);
    expect(sent, 7);
  });

  test('the reminder offsets are set on their own path', () async {
    adapter.enqueueJson(_liveClass());

    await api.setReminders('l1', const [1440, 30]);

    expect(adapter.lastRequest.method, 'PATCH');
    expect(adapter.lastRequest.path, '/live/l1/reminders');
    expect(adapter.lastRequest.data, {
      'reminders': const [1440, 30],
    });
  });
}
