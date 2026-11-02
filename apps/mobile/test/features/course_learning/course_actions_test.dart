import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/features/course_learning/course_learning.dart';
import 'package:syniastrolms_mobile/features/learner_home/learner_home.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

const _courseId = 'cmudqd8g30035mmgzwtgr0mcl';

void main() {
  late FakeAdapter adapter;
  late ProviderContainer container;

  setUp(() {
    adapter = FakeAdapter();
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: publicScope(
        adapter: adapter,
        signedInAs: learner(),
        child: const SizedBox(),
      ).overrides,
    );
    addTearDown(container.dispose);
  });

  Future<LearnerCourseDetail> loadCourse({bool saved = false}) async {
    adapter.enqueueJson({
      ...fixture('learning/course-detail-not-enrolled.json')! as Map<String, dynamic>,
      'saved': saved,
    });
    // Kept alive for the test, as a screen would.
    container.listen(learnerCourseProvider(_courseId), (_, _) {});
    return container.read(learnerCourseProvider(_courseId).future);
  }

  group('saving', () {
    test('the bookmark moves at once and keeps the server\'s answer', () async {
      final detail = await loadCourse();
      // Kept alive for the test, as a screen would.
      container.listen(courseActionsProvider, (_, _) {});
      adapter.enqueueJson({'saved': true});

      final pending = container.read(courseActionsProvider.notifier).toggleSaved(_courseId);
      expect(
        container.read(courseActionsProvider).savedFor(detail),
        isTrue,
        reason: 'the toggle does not wait for the round trip',
      );
      expect(container.read(courseActionsProvider).savePending, isTrue);

      await pending;
      expect(container.read(courseActionsProvider).savedFor(detail), isTrue);
      expect(container.read(courseActionsProvider).savePending, isFalse);
      expect(adapter.lastRequest.path, '/learning/courses/$_courseId/save');
    });

    test('a refusal puts the bookmark back, with the reason', () async {
      final detail = await loadCourse();
      // Kept alive for the test, as a screen would.
      container.listen(courseActionsProvider, (_, _) {});
      adapter.enqueueJson({'message': 'Course not found.'}, status: 404);

      await container.read(courseActionsProvider.notifier).toggleSaved(_courseId);

      expect(container.read(courseActionsProvider).savedFor(detail), isFalse);
      expect(container.read(courseActionsProvider).failure, isA<NotFoundFailure>());
    });

    test('the server may disagree with the optimistic guess, and it wins', () async {
      final detail = await loadCourse();
      // Kept alive for the test, as a screen would.
      container.listen(courseActionsProvider, (_, _) {});
      // Another device unsaved it first, so the toggle lands on "not saved".
      adapter.enqueueJson({'saved': false});

      await container.read(courseActionsProvider.notifier).toggleSaved(_courseId);

      expect(container.read(courseActionsProvider).savedFor(detail), isFalse);
    });
  });

  group('enrolling', () {
    test('sends no body and re-reads the course and the workspace', () async {
      await loadCourse();
      // Kept alive for the test, as a screen would.
      container.listen(courseActionsProvider, (_, _) {});
      // Kept alive for the test, as a screen would.
      container.listen(learnerCoursesProvider, (_, _) {});
      adapter
        ..enqueueJson(fixture('learning/courses.json'))
        ..enqueueJson(fixture('learning/enroll.json'))
        ..enqueueJson({
          ...fixture('learning/course-detail-not-enrolled.json')! as Map<String, dynamic>,
          'enrolled': true,
        })
        ..enqueueJson(fixture('learning/courses-with-saved.json'));
      await container.read(learnerCoursesProvider.future);

      final done = await container.read(courseActionsProvider.notifier).enroll(_courseId);
      await container.read(learnerCourseProvider(_courseId).future);

      expect(done, isTrue);
      expect(
        adapter.requests.map((r) => r.path),
        containsAllInOrder(['/learning/courses/$_courseId/enroll', '/learning/courses/$_courseId']),
      );
      expect(container.read(learnerCourseProvider(_courseId)).value?.enrolled, isTrue);
    });

    test('the academy\'s policy is carried back in its own words', () async {
      await loadCourse();
      // Kept alive for the test, as a screen would.
      container.listen(courseActionsProvider, (_, _) {});
      adapter.enqueueJson(fixture('errors/enroll-approval.json'), status: 409);

      final done = await container.read(courseActionsProvider.notifier).enroll(_courseId);

      expect(done, isFalse);
      final failure = container.read(courseActionsProvider).failure;
      expect(failure, isA<ConflictFailure>());
      expect(failure?.message, startsWith('Enrolment in this academy needs approval'));
    });

    test('a second tap while one is in flight is ignored', () async {
      await loadCourse();
      // Kept alive for the test, as a screen would.
      container.listen(courseActionsProvider, (_, _) {});
      adapter
        ..enqueueJson(fixture('learning/enroll.json'))
        ..enqueueJson({
          ...fixture('learning/course-detail-not-enrolled.json')! as Map<String, dynamic>,
          'enrolled': true,
        });

      final first = container.read(courseActionsProvider.notifier).enroll(_courseId);
      final second = await container.read(courseActionsProvider.notifier).enroll(_courseId);
      await first;

      expect(second, isFalse);
      expect(adapter.requests.where((r) => r.path.endsWith('/enroll')), hasLength(1));
    });
  });
}
