import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/features/staff_calendar/staff_calendar.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/public_harness.dart';
import '../helpers/test_config.dart';

Map<String, dynamic> _event() =>
    (fixture('staff/calendar-reminder.json')! as Map<String, dynamic>)['event']!
        as Map<String, dynamic>;

void main() {
  late FakeAdapter adapter;
  late StaffCalendarApi api;

  setUp(() {
    adapter = FakeAdapter();
    api = StaffCalendarApi(
      ApiClient(
        config: testConfig(),
        tokenStore: FakeTokenStore('jwt'),
        logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
        adapter: adapter,
        logRequests: false,
      ),
    );
  });

  test('the range is asked for as IST calendar dates', () async {
    adapter.enqueueJson(fixture('staff/calendar-month.json'));

    await api.range(fromIstDay: DateTime.utc(2026, 9, 28), toIstDay: DateTime.utc(2026, 10, 4));

    expect(adapter.lastRequest.method, 'GET');
    expect(adapter.lastRequest.path, '/calendar');
    expect(adapter.lastRequest.queryParameters, {'from': '2026-09-28', 'to': '2026-10-04'});
  });

  test('the types travel as a list of the route\'s own words', () async {
    adapter.enqueueJson(fixture('staff/calendar-month.json'));

    await api.range(
      fromIstDay: DateTime.utc(2026, 10),
      toIstDay: DateTime.utc(2026, 10, 31),
      types: const [CalendarEventType.reminder, CalendarEventType.milestone],
      courseId: 'c1',
      instructorId: 'i1',
    );

    expect(adapter.lastRequest.queryParameters, {
      'from': '2026-10-01',
      'to': '2026-10-31',
      'types': const ['reminder', 'milestone'],
      'courseId': 'c1',
      'instructorId': 'i1',
    });
  });

  test('no type asked for sends none at all', () async {
    adapter.enqueueJson(fixture('staff/calendar-month.json'));

    await api.range(fromIstDay: DateTime.utc(2026, 10), toIstDay: DateTime.utc(2026, 10, 7));

    expect(adapter.lastRequest.queryParameters.containsKey('types'), isFalse);
  });

  test('a derived event id is escaped into the path, prefix and all', () async {
    adapter.enqueueJson(fixture('staff/calendar-live.json'));

    await api.event('live-abc def');

    expect(adapter.lastRequest.path, '/calendar/live-abc%20def');
  });

  test('adding wraps the event, as the route asks', () async {
    adapter.enqueueJson(_event());

    await api.create(
      CalendarEventForm(title: 'A reminder', startsAt: DateTime.utc(2026, 10, 8, 9, 30)),
    );

    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.path, '/calendar');
    final body = adapter.lastRequest.data! as Map<String, Object?>;
    expect(body.keys, ['input'], reason: 'the create route takes {input: …}');
    expect((body['input']! as Map)['title'], 'A reminder');
  });

  test('saving sends the event bare, as that route asks instead', () async {
    adapter.enqueueJson(_event());

    await api.save(
      'e1',
      CalendarEventForm(title: 'A reminder', startsAt: DateTime.utc(2026, 10, 8, 9, 30)),
    );

    expect(adapter.lastRequest.method, 'PATCH');
    expect(adapter.lastRequest.path, '/calendar/e1');
    final body = adapter.lastRequest.data! as Map<String, Object?>;
    expect(body.containsKey('input'), isFalse, reason: 'the save route takes it unwrapped');
    expect(body['title'], 'A reminder');
  });

  test('removing is a delete with no body', () async {
    adapter.enqueue((_) async => FakeAdapter.noContent());

    await api.remove('e1');

    expect(adapter.lastRequest.method, 'DELETE');
    expect(adapter.lastRequest.path, '/calendar/e1');
    expect(adapter.lastRequest.data, isNull);
  });

  test('ticking one off says which way', () async {
    adapter
      ..enqueueJson({..._event(), 'done': true})
      ..enqueueJson(_event());

    final done = await api.setDone('e1', done: true);
    expect(adapter.lastRequest.path, '/calendar/e1/done');
    expect(adapter.lastRequest.data, {'done': true});
    expect(done.done, isTrue);

    final undone = await api.setDone('e1', done: false);
    expect(adapter.lastRequest.data, {'done': false});
    expect(undone.done, isFalse);
  });
}
