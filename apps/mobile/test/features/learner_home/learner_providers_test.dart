import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/features/learner_home/learner_home.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File('test/fixtures/$path').readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('the My Learning tabs', () {
    late LearnerCourses data;

    setUp(() => data = LearnerCourses.fromJson(_json('learning/courses-with-saved.json')));

    test('partition by the server\'s enrolment status, not by counting lessons', () {
      final inProgress = coursesForTab(data, MyLearningTab.inProgress);
      final completed = coursesForTab(data, MyLearningTab.completed);

      expect(inProgress.every((c) => c.enrollment.status != EnrollmentStatus.completed), isTrue);
      expect(completed.every((c) => c.enrollment.status == EnrollmentStatus.completed), isTrue);
      expect(inProgress.length + completed.length, data.courses.length);
      // Saved is its own list: no enrolled course belongs to that tab.
      expect(coursesForTab(data, MyLearningTab.saved), isEmpty);
      expect(data.saved, hasLength(1));
    });

    test('a paused enrolment stays in progress; a completed one moves across', () {
      final course = data.courses.first;
      final paused = LearnerCourses(
        courses: [
          course.copyWith(enrollment: course.enrollment.copyWith(status: EnrollmentStatus.paused)),
        ],
      );

      expect(coursesForTab(paused, MyLearningTab.inProgress), hasLength(1));
      expect(coursesForTab(paused, MyLearningTab.completed), isEmpty);
    });

    test('an expired enrolment is kept in progress rather than disappearing', () {
      final course = data.courses.first;
      final expired = course.copyWith(
        enrollment: course.enrollment.copyWith(status: EnrollmentStatus.expired),
      );

      expect(showsInProgress(expired), isTrue);
      expect(coursesForTab(LearnerCourses(courses: [expired]), MyLearningTab.inProgress), [
        expired,
      ]);
    });

    test('a status this build does not know is not silently counted as in progress', () {
      final course = data.courses.first;
      final unknown = course.copyWith(
        enrollment: course.enrollment.copyWith(status: EnrollmentStatus.unknown),
      );

      expect(showsInProgress(unknown), isFalse);
    });
  });

  group('reading the workspace', () {
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

    test('home comes back parsed from what the API sent', () async {
      adapter.enqueueJson(fixture('learning/home.json'));

      final home = await container.read(learnerHomeProvider.future);

      expect(adapter.lastRequest.path, '/learning/home');
      expect(home.firstName, 'Ananya');
      expect(home.courses, hasLength(3));
    });

    test("a staff account's 400 becomes a not-found, never a developer message", () async {
      // `GET /learning/home` answers 400 "Only learners have a learning workspace." for staff.
      adapter.enqueueJson(fixture('errors/learning-not-a-learner.json'), status: 400);

      await expectLater(
        container.read(learnerHomeProvider.future),
        throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
      );
    });

    test('any other 400 keeps the server\'s own failure', () async {
      adapter.enqueueJson({'message': 'Something else entirely.'}, status: 400);

      await expectLater(
        container.read(learnerCoursesProvider.future),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            isA<ValidationFailure>().having(
              (f) => f.message,
              'message',
              'Something else entirely.',
            ),
          ),
        ),
      );
    });

    test('a suspended learner is refused by the server and the app does not soften it', () async {
      adapter.enqueueJson({'message': 'This account is suspended.'}, status: 403);

      await expectLater(container.read(learnerHomeProvider.future), throwsA(isA<ApiException>()));
    });
  });
}
