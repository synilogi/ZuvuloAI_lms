import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/features/assignments/assignments.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/public_harness.dart';
import '../helpers/test_config.dart';

void main() {
  late FakeAdapter adapter;
  late AssignmentsApi api;

  setUp(() {
    adapter = FakeAdapter();
    api = AssignmentsApi(
      ApiClient(
        config: testConfig(),
        tokenStore: FakeTokenStore('jwt'),
        logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
        adapter: adapter,
        logRequests: false,
      ),
    );
  });

  test('the list is read for whoever is signed in — no student is ever named', () async {
    adapter.enqueueJson(fixture('learning/assignments.json'));

    final rows = await api.assignments();

    expect(adapter.lastRequest.method, 'GET');
    expect(adapter.lastRequest.path, '/learning/assignments');
    expect(adapter.lastRequest.queryParameters, isEmpty);
    expect(rows, isNotEmpty);
  });

  test('one assignment is read by its id, escaped into the path', () async {
    adapter.enqueueJson(fixture('learning/assignment-graded.json'));

    await api.assignment('a b/c');

    expect(adapter.lastRequest.path, '/learning/assignments/a%20b%2Fc');
  });

  test('a draft sends the work and answers with when the server stored it', () async {
    adapter.enqueueJson({'savedAt': '2026-09-29T06:10:00.000Z'});

    final savedAt = await api.saveDraft(
      assignmentId: 'a1',
      work: const AssignmentWork(
        text: 'Jupiter mahadasha.',
        files: [Attachment(id: 'm1', name: 'chart.pdf', sizeMb: 1.2, url: '/media/m1')],
      ),
    );

    expect(adapter.lastRequest.method, 'PUT');
    expect(adapter.lastRequest.path, '/learning/assignments/a1/draft');
    final body = adapter.lastRequest.data! as Map;
    expect(body['text'], 'Jupiter mahadasha.');
    expect(body['files'], [
      {'id': 'm1', 'name': 'chart.pdf', 'sizeMb': 1.2, 'url': '/media/m1'},
    ]);
    expect(body.containsKey('chart'), isFalse, reason: 'a chart is only sent when there is one');
    expect(savedAt, DateTime.utc(2026, 9, 29, 6, 10));
    expect(savedAt.isUtc, isTrue);
  });

  test('a chart hand-in sends the birth details as the route names them', () async {
    adapter.enqueueJson(fixture('learning/assignment-submitted.json'));

    await api.submit(
      assignmentId: 'a1',
      work: const AssignmentWork(
        text: 'Leo ascendant.',
        chart: BirthDetails(
          label: 'A friend',
          date: '1994-03-02',
          time: '05:40',
          place: 'Jaipur',
          lagna: 'Leo',
          moonSign: 'Taurus',
          nakshatra: 'Rohini',
        ),
      ),
    );

    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.path, '/learning/assignments/a1/submit');
    final body = adapter.lastRequest.data! as Map;
    expect(body['chart'], {
      'label': 'A friend',
      'date': '1994-03-02',
      'time': '05:40',
      'place': 'Jaipur',
      'lagna': 'Leo',
      'moonSign': 'Taurus',
      'nakshatra': 'Rohini',
    });
    expect(body['files'], isEmpty);
  });

  test('nothing the learner hands in carries a score, a state or anyone else\'s id', () async {
    adapter.enqueueJson(fixture('learning/assignment-submitted.json'));

    await api.submit(
      assignmentId: 'a1',
      work: const AssignmentWork(text: 'An answer.'),
    );

    final body = adapter.lastRequest.data! as Map;
    expect(body.keys, unorderedEquals(['text', 'files']));
    for (final forbidden in ['score', 'points', 'state', 'studentId', 'late', 'review']) {
      expect(body.keys, isNot(contains(forbidden)));
    }
  });

  test('a file is sent back exactly as the media route returned it', () async {
    adapter.enqueueJson({'savedAt': '2026-09-29T06:10:00.000Z'});

    await api.saveDraft(
      assignmentId: 'a1',
      work: const AssignmentWork(
        files: [
          Attachment(
            id: 'm2',
            name: 'reading.pdf',
            sizeMb: 0.4,
            url: '/media/m2',
            mime: 'application/pdf',
          ),
        ],
      ),
    );

    final files = (adapter.lastRequest.data! as Map)['files']! as List;
    expect(files.single, {
      'id': 'm2',
      'name': 'reading.pdf',
      'sizeMb': 0.4,
      'url': '/media/m2',
      'mime': 'application/pdf',
    });
  });
}
