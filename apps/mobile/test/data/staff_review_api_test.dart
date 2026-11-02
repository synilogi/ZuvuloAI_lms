import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/features/staff_review/staff_review.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/public_harness.dart';
import '../helpers/test_config.dart';

void main() {
  late FakeAdapter adapter;
  late StaffReviewApi api;

  setUp(() {
    adapter = FakeAdapter();
    api = StaffReviewApi(
      ApiClient(
        config: testConfig(),
        tokenStore: FakeTokenStore('jwt'),
        logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
        adapter: adapter,
        logRequests: false,
      ),
    );
  });

  test('the queue is read for whoever is signed in, with no query at all', () async {
    adapter.enqueueJson(fixture('staff/review-queue.json'));

    await api.queue();

    expect(adapter.lastRequest.method, 'GET');
    expect(adapter.lastRequest.path, '/assignments/review');
    expect(adapter.lastRequest.queryParameters, isEmpty);
  });

  test('the hand-ins ask for one page, and for nothing not narrowed on screen', () async {
    adapter.enqueueJson(fixture('staff/submissions.json'));

    await api.submissions();

    expect(adapter.lastRequest.path, '/assignments/submissions');
    expect(adapter.lastRequest.queryParameters, {'page': 1, 'pageSize': 20});
  });

  test('every filter travels as the route names it', () async {
    adapter.enqueueJson(fixture('staff/submissions.json'));

    await api.submissions(
      courseId: 'c1',
      filter: 'to-review',
      search: 'ananya',
      sort: 'newest',
      page: 2,
    );

    expect(adapter.lastRequest.queryParameters, {
      'courseId': 'c1',
      'filter': 'to-review',
      'search': 'ananya',
      'sort': 'newest',
      'page': 2,
      'pageSize': 20,
    });
  });

  test('one assignment\'s hand-ins go through its own route, which checks access', () async {
    adapter.enqueueJson(fixture('staff/submissions.json'));

    await api.submissions(assignmentId: 'a b/c', filter: 'missing');

    expect(adapter.lastRequest.path, '/assignments/a%20b%2Fc/submissions');
    expect(adapter.lastRequest.queryParameters['filter'], 'missing');
    expect(
      adapter.lastRequest.queryParameters.containsKey('assignmentId'),
      isFalse,
      reason: 'the id is the path, not a query the route would have to trust twice',
    );
  });

  test('one hand-in is read by its own id', () async {
    adapter.enqueueJson(fixture('staff/submission.json'));

    final detail = await api.submission('s1');

    expect(adapter.lastRequest.path, '/assignments/submissions/s1');
    expect(detail.assignment.title, isNotEmpty);
  });

  test('a saved draft is sent as the route\'s own word for it', () async {
    adapter.enqueueJson((fixture('staff/submission.json')! as Map<String, dynamic>)['submission']);

    await api.review('s1', decision: ReviewStatus.inReview, points: 40, feedback: 'Halfway there.');

    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.path, '/assignments/submissions/s1/review');
    expect(adapter.lastRequest.data, {
      'decision': 'draft',
      'scores': <String, num>{},
      'points': 40,
      'feedback': 'Halfway there.',
    });
  });

  test('a grade sends the criteria it scored and nothing it was not given', () async {
    adapter.enqueueJson((fixture('staff/submission.json')! as Map<String, dynamic>)['submission']);

    await api.review(
      's1',
      decision: ReviewStatus.graded,
      scores: const {'lagna': 18, 'moon': 15},
      feedback: 'Well argued throughout.',
      privateNote: 'Second attempt was much stronger.',
    );

    expect(adapter.lastRequest.data, {
      'decision': 'graded',
      'scores': const {'lagna': 18, 'moon': 15},
      'feedback': 'Well argued throughout.',
      'privateNote': 'Second attempt was much stronger.',
    });
    expect(
      (adapter.lastRequest.data! as Map).containsKey('score'),
      isFalse,
      reason: 'the academy works the score out; the app never sends one (§18)',
    );
  });

  test('a return is sent as returned', () async {
    adapter.enqueueJson((fixture('staff/submission.json')! as Map<String, dynamic>)['submission']);

    await api.review('s1', decision: ReviewStatus.returned, feedback: 'Have another go at this.');

    expect((adapter.lastRequest.data! as Map)['decision'], 'returned');
  });

  test('reminding everyone who owes it names nobody', () async {
    adapter.enqueueJson(const {'sent': 4});

    final sent = await api.remind('a1');

    expect(adapter.lastRequest.path, '/assignments/a1/remind');
    expect(adapter.lastRequest.data, {'studentIds': <String>[]});
    expect(sent, 4);
  });

  test('reminding a few names exactly those', () async {
    adapter.enqueueJson(const {'sent': 2});

    await api.remind('a1', studentIds: const ['s1', 's2']);

    expect((adapter.lastRequest.data! as Map)['studentIds'], const ['s1', 's2']);
  });

  test('the assignments are read for the picker', () async {
    adapter.enqueueJson(fixture('staff/assignments.json'));

    final page = await api.assignments(courseId: 'c1', status: 'published');

    expect(adapter.lastRequest.path, '/assignments');
    expect(adapter.lastRequest.queryParameters, {'courseId': 'c1', 'status': 'published'});
    expect(page.rows, isNotEmpty);
  });
}
