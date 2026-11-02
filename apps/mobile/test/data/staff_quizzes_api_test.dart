import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/features/staff_quizzes/staff_quizzes.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/public_harness.dart';
import '../helpers/test_config.dart';

void main() {
  late FakeAdapter adapter;
  late StaffQuizzesApi api;

  setUp(() {
    adapter = FakeAdapter();
    api = StaffQuizzesApi(
      ApiClient(
        config: testConfig(),
        tokenStore: FakeTokenStore('jwt'),
        logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
        adapter: adapter,
        logRequests: false,
      ),
    );
  });

  test('the list asks for nothing the screen did not narrow by', () async {
    adapter.enqueueJson(fixture('staff/quizzes.json'));

    await api.quizzes();

    expect(adapter.lastRequest.method, 'GET');
    expect(adapter.lastRequest.path, '/quizzes');
    expect(adapter.lastRequest.queryParameters, isEmpty);
  });

  test('every filter travels as the route names it', () async {
    adapter.enqueueJson(fixture('staff/quizzes.json'));

    await api.quizzes(search: 'nakshatra', courseId: 'c1', status: 'published');

    expect(adapter.lastRequest.queryParameters, {
      'search': 'nakshatra',
      'courseId': 'c1',
      'status': 'published',
    });
  });

  test('a quiz id is escaped into the path', () async {
    adapter.enqueueJson(fixture('staff/quiz.json'));

    await api.quiz('a b/c');

    expect(adapter.lastRequest.path, '/quizzes/a%20b%2Fc');
  });

  test('the stats have a path of their own', () async {
    adapter.enqueueJson(fixture('staff/quiz-stats.json'));

    final stats = await api.stats('q1');

    expect(adapter.lastRequest.path, '/quizzes/q1/stats');
    expect(stats.distribution, hasLength(10));
  });

  test('nothing here ever writes', () async {
    adapter
      ..enqueueJson(fixture('staff/quizzes.json'))
      ..enqueueJson(fixture('staff/quiz.json'))
      ..enqueueJson(fixture('staff/quiz-stats.json'));

    await api.quizzes();
    await api.quiz('q1');
    await api.stats('q1');

    expect(adapter.requests.map((r) => r.method), everyElement('GET'));
  });
}
