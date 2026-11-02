import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/features/course_learning/course_learning.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/public_harness.dart';
import '../helpers/test_config.dart';

void main() {
  late FakeAdapter adapter;
  late CourseLearningApi api;

  setUp(() {
    adapter = FakeAdapter();
    api = CourseLearningApi(
      ApiClient(
        config: testConfig(),
        tokenStore: FakeTokenStore('jwt'),
        logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
        adapter: adapter,
        logRequests: false,
      ),
    );
  });

  test('the course is read by id, encoded into the path', () async {
    adapter.enqueueJson(fixture('learning/course-detail-enrolled.json'));

    final detail = await api.course('course_1');

    expect(adapter.lastRequest.method, 'GET');
    expect(adapter.lastRequest.path, '/learning/courses/course_1');
    expect(detail.enrolled, isTrue);
  });

  test('saving sends no body — nothing about the course is the app\'s to say', () async {
    adapter.enqueueJson({'saved': true});

    final saved = await api.toggleSaved('course_1');

    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.path, '/learning/courses/course_1/save');
    expect(adapter.lastRequest.data, isNull);
    expect(saved, isTrue);
  });

  test('enrolling sends no body: the price, the source and the status are the server\'s', () async {
    adapter.enqueueJson(fixture('learning/enroll.json'));

    final course = await api.enroll('course_1');

    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.path, '/learning/courses/course_1/enroll');
    expect(adapter.lastRequest.data, isNull);
    expect(adapter.lastRequest.queryParameters, isEmpty);
    expect(course.enrollment.source, 'self');
  });

  test('the enrolment policy comes back as a conflict carrying the academy\'s words', () async {
    adapter.enqueueJson(fixture('errors/enroll-approval.json'), status: 409);

    await expectLater(
      api.enroll('course_1'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          isA<ConflictFailure>().having(
            (f) => f.message,
            'message',
            startsWith('Enrolment in this academy needs approval'),
          ),
        ),
      ),
    );
  });

  test('a course that is private or unpublished is simply not found', () async {
    adapter.enqueueJson(fixture('errors/not-found.json'), status: 404);

    await expectLater(
      api.enroll('course_1'),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
    );
  });

  test('an id that could climb a path segment never reaches the network', () async {
    await expectLater(
      api.course('..'),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<ValidationFailure>())),
    );
    expect(adapter.requests, isEmpty);
  });
}
