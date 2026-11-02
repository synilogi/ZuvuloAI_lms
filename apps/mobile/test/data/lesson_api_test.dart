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

  test('a lesson is read by course and lesson, both encoded into the path', () async {
    adapter.enqueueJson(fixture('learning/lesson-video.json'));

    final view = await api.lesson(courseId: 'course_1', lessonId: 'lesson_2');

    expect(adapter.lastRequest.method, 'GET');
    expect(adapter.lastRequest.path, '/learning/courses/course_1/lessons/lesson_2');
    expect(view.lesson.type, 'video');
  });

  test('completing sends no body — the rule is the academy\'s, not the app\'s', () async {
    adapter.enqueueJson(fixture('learning/complete-result.json'));

    await api.complete(courseId: 'course_1', lessonId: 'lesson_2');

    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.path, '/learning/courses/course_1/lessons/lesson_2/complete');
    expect(adapter.lastRequest.data, isNull);
  });

  test('a rule not yet met comes back as a conflict with the sentence to show', () async {
    adapter.enqueueJson(fixture('errors/complete-needs-watching.json'), status: 409);

    await expectLater(
      api.complete(courseId: 'course_1', lessonId: 'lesson_2'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          isA<ConflictFailure>().having(
            (f) => f.message,
            'message',
            'Watch at least 90% of the lesson to complete it.',
          ),
        ),
      ),
    );
  });

  test(
    'a position report carries only the two numbers the route reads, and may be retried',
    () async {
      adapter.enqueueStatus(204);

      await api.reportPosition(
        courseId: 'course_1',
        lessonId: 'lesson_2',
        positionSec: 312,
        fraction: 0.62,
      );

      expect(adapter.lastRequest.method, 'PUT');
      expect(adapter.lastRequest.path, '/learning/courses/course_1/lessons/lesson_2/position');
      expect(adapter.lastRequest.data, {'positionSec': 312, 'fraction': 0.62});
      expect(adapter.lastRequest.extra['retry.idempotent'], isTrue);
    },
  );

  test('a fraction outside 0–1 is brought back inside before it is sent', () async {
    adapter
      ..enqueueStatus(204)
      ..enqueueStatus(204);

    await api.reportPosition(courseId: 'c', lessonId: 'l', positionSec: 1, fraction: 1.4);
    expect((adapter.lastRequest.data! as Map)['fraction'], 1.0);

    await api.reportPosition(courseId: 'c', lessonId: 'l', positionSec: 1, fraction: -0.2);
    expect((adapter.lastRequest.data! as Map)['fraction'], 0.0);
  });

  test('a note is sent as text and the server says when it stored it', () async {
    adapter.enqueueJson({'savedAt': '2026-09-23T12:00:00.000Z'});

    final savedAt = await api.saveNote(
      courseId: 'course_1',
      lessonId: 'lesson_2',
      text: 'My working',
    );

    expect(adapter.lastRequest.method, 'PUT');
    expect(adapter.lastRequest.path, '/learning/courses/course_1/lessons/lesson_2/note');
    expect(adapter.lastRequest.data, {'text': 'My working'});
    expect(savedAt, DateTime.utc(2026, 9, 23, 12));
  });

  test('bookmarking is a toggle with no body', () async {
    adapter.enqueueJson({'bookmarked': true});

    final bookmarked = await api.toggleBookmark(courseId: 'course_1', lessonId: 'lesson_2');

    expect(adapter.lastRequest.path, '/learning/courses/course_1/lessons/lesson_2/bookmark');
    expect(adapter.lastRequest.data, isNull);
    expect(bookmarked, isTrue);
  });

  test('a lesson id that could climb a path segment never reaches the network', () async {
    await expectLater(
      api.lesson(courseId: 'course_1', lessonId: '..'),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<ValidationFailure>())),
    );
    expect(adapter.requests, isEmpty);
  });
}
