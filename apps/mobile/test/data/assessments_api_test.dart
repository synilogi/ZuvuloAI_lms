import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/features/assessments/assessments.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/public_harness.dart';
import '../helpers/test_config.dart';

void main() {
  late FakeAdapter adapter;
  late AssessmentsApi api;

  setUp(() {
    adapter = FakeAdapter();
    api = AssessmentsApi(
      ApiClient(
        config: testConfig(),
        tokenStore: FakeTokenStore('jwt'),
        logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
        adapter: adapter,
        logRequests: false,
        retryDelay: (_) async {},
      ),
    );
  });

  Matcher refusedWith(QuizSessionProblem problem) => throwsA(
    isA<ApiException>().having(
      (e) => e.failure,
      'failure',
      isA<QuizSessionFailure>().having((f) => f.problem, 'problem', problem),
    ),
  );

  test('the assessments list is read for whoever is signed in', () async {
    adapter.enqueueJson(fixture('learning/assessments-open.json'));

    final rows = await api.assessments();

    expect(adapter.lastRequest.path, '/learning/assessments');
    expect(adapter.lastRequest.queryParameters, isEmpty, reason: 'no student id is ever sent');
    expect(rows, hasLength(2));
  });

  test(
    'starting asks the server for a session, with the tap\'s key, and only then has questions',
    () async {
      adapter.enqueueJson(fixture('learning/quiz-session-start.json'), status: 201);

      final begun = await api.startSession(
        courseId: 'course_1',
        lessonId: 'lesson_2',
        startKey: 'tap-key-0001',
      );

      expect(adapter.lastRequest.method, 'POST');
      expect(adapter.lastRequest.path, '/learning/courses/course_1/lessons/lesson_2/quiz-session');
      expect(adapter.lastRequest.data, {'startKey': 'tap-key-0001'});
      expect(begun.resumed, isFalse);
      expect(begun.session.isActive, isTrue);
      expect(begun.session.remainingSec, 899);
      expect(begun.session.answersSeq, 0);
      // The order is the server's for this attempt, options too.
      expect(begun.questions.map((q) => q.id), ['q1', 'q2', 'q3']);
      expect(begun.questions.first.options.map((o) => o.id), ['b', 'a', 'd', 'c']);
    },
  );

  test('the latest session is read without starting anything; none is null', () async {
    adapter
      ..enqueueJson(fixture('learning/quiz-session-current.json'))
      ..enqueueJson({'session': null, 'questions': <Object>[]});

    final open = await api.latestSession(courseId: 'c', lessonId: 'l');
    final none = await api.latestSession(courseId: 'c', lessonId: 'l');

    expect(adapter.requests.first.method, 'GET');
    expect(adapter.requests.first.path, '/learning/courses/c/lessons/l/quiz-session');
    expect(open!.resumed, isTrue);
    expect(open.session.answerSheet, {
      'q1': ['b'],
    });
    expect(open.questions, hasLength(3));
    expect(none, isNull);
  });

  test('a save sends the whole sheet and its number, and never a score', () async {
    adapter.enqueueJson(fixture('learning/quiz-session-saved.json'));

    final stored = await api.saveAnswers(
      courseId: 'c',
      lessonId: 'l',
      sessionId: 'cmvoydpgz000dmmtfl72u5oqz',
      answers: const {
        'q1': ['b'],
        'q3': '75%',
      },
      seq: 1,
    );

    expect(adapter.lastRequest.method, 'PUT');
    expect(
      adapter.lastRequest.path,
      '/learning/courses/c/lessons/l/quiz-session/cmvoydpgz000dmmtfl72u5oqz/answers',
    );
    final body = adapter.lastRequest.data! as Map;
    expect(body, {
      'answers': {
        'q1': ['b'],
        'q3': '75%',
      },
      'seq': 1,
    });
    expect(body.keys, isNot(contains('score')));
    expect(stored.answersSeq, 1);
    expect(stored.savedAt, isNotNull);
  });

  test('handing in sends the final sheet and reads the server\'s review and standing', () async {
    adapter.enqueueJson(fixture('learning/quiz-session-submitted.json'));

    final handedIn = await api.submit(
      courseId: 'c',
      lessonId: 'l',
      sessionId: 's1',
      answers: const {
        'q1': ['a'],
      },
      seq: 2,
    );

    expect(adapter.lastRequest.path, '/learning/courses/c/lessons/l/quiz-session/s1/submit');
    expect(adapter.lastRequest.data, {
      'answers': {
        'q1': ['a'],
      },
      'seq': 2,
    });
    expect(handedIn.session.status, QuizSessionStatus.submitted);
    expect(handedIn.answersAccepted, isTrue);
    expect(handedIn.completion, isNull);
    expect(handedIn.review!.percent, 33);
    expect(handedIn.review!.keyWithheld, isTrue);
    expect(handedIn.review!.finish, AttemptFinish.submitted);
    expect(handedIn.standing.canStart, isTrue);
  });

  test('handing in without a sheet sends an empty body', () async {
    adapter.enqueueJson(fixture('learning/quiz-session-submitted-repeat.json'));

    final again = await api.submit(courseId: 'c', lessonId: 'l', sessionId: 's1');

    expect(adapter.lastRequest.data, isEmpty);
    expect(again.answersAccepted, isFalse);
  });

  test('the attempts read says where the learner stands, the open attempt included', () async {
    adapter.enqueueJson(fixture('learning/quiz-attempts-open.json'));

    final read = await api.attempts(courseId: 'c', lessonId: 'l');

    expect(adapter.lastRequest.path, '/learning/courses/c/lessons/l/quiz-attempts');
    expect(read.attempts, isEmpty);
    expect(read.standing.attemptsAllowed, 2);
    expect(read.standing.attemptsUsed, 1);
    expect(read.standing.openSession?.isActive, isTrue);
    expect(read.standing.attemptsLeft, 1);
  });

  group('the server\'s quiz refusals arrive typed', () {
    test('an attempt already handed in', () async {
      adapter.enqueueJson(fixture('errors/quiz-finished.json'), status: 409);

      await expectLater(
        api.saveAnswers(courseId: 'c', lessonId: 'l', sessionId: 's', answers: const {}, seq: 3),
        refusedWith(QuizSessionProblem.finished),
      );
    });

    test('time up, with the server\'s own sentence', () async {
      adapter.enqueueJson({
        'message': 'Time is up for this attempt. Answers sent after the deadline are not counted.',
        'code': 'QUIZ_TIME_UP',
      }, status: 409);

      await expectLater(
        api.saveAnswers(courseId: 'c', lessonId: 'l', sessionId: 's', answers: const {}, seq: 3),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            isA<QuizSessionFailure>()
                .having((f) => f.attemptOver, 'attemptOver', isTrue)
                .having((f) => f.message, 'message', startsWith('Time is up')),
          ),
        ),
      );
    });

    test('not open yet, with when it opens', () async {
      adapter.enqueueJson({
        'message': 'This quiz has not opened yet.',
        'code': 'TEST_NOT_OPEN',
        'issues': {'opensAt': '2026-11-01T04:30:00.000Z'},
      }, status: 409);

      await expectLater(
        api.startSession(courseId: 'c', lessonId: 'l', startKey: 'k-12345678'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            isA<QuizSessionFailure>()
                .having((f) => f.problem, 'problem', QuizSessionProblem.notOpen)
                .having((f) => f.opensAt, 'opensAt', DateTime.utc(2026, 11, 1, 4, 30)),
          ),
        ),
      );
    });

    test('closed, and the old one-request attempt refused', () async {
      adapter
        ..enqueueJson({'message': 'This quiz has closed.', 'code': 'TEST_CLOSED'}, status: 409)
        ..enqueueJson({
          'message': 'This quiz is timed on the server.',
          'code': 'QUIZ_SESSION_REQUIRED',
        }, status: 409);

      await expectLater(
        api.startSession(courseId: 'c', lessonId: 'l'),
        refusedWith(QuizSessionProblem.closed),
      );
      await expectLater(
        api.startSession(courseId: 'c', lessonId: 'l'),
        refusedWith(QuizSessionProblem.sessionRequired),
      );
    });

    test('paused or ended access arrives typed, with the academy\'s message', () async {
      adapter
        ..enqueueJson({
          'message': 'Your access to this course is paused.',
          'code': 'ENROLLMENT_PAUSED',
        }, status: 409)
        ..enqueueJson({
          'message': 'Your access to this course has ended.',
          'code': 'ENROLLMENT_EXPIRED',
        }, status: 409);

      Matcher enrolment(EnrollmentProblem problem, String message) => throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          isA<EnrollmentFailure>()
              .having((f) => f.problem, 'problem', problem)
              .having((f) => f.message, 'message', message),
        ),
      );
      await expectLater(
        api.startSession(courseId: 'c', lessonId: 'l'),
        enrolment(EnrollmentProblem.paused, 'Your access to this course is paused.'),
      );
      await expectLater(
        api.saveAnswers(courseId: 'c', lessonId: 'l', sessionId: 's', answers: const {}, seq: 2),
        enrolment(EnrollmentProblem.expired, 'Your access to this course has ended.'),
      );
    });

    test('any other refusal carries the academy\'s own reason', () async {
      adapter.enqueueJson(fixture('errors/quiz-retake-wait.json'), status: 409);

      await expectLater(
        api.startSession(courseId: 'c', lessonId: 'l', startKey: 'k-12345678'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            isA<ConflictFailure>()
                .having((f) => f, 'typed', isNot(isA<QuizSessionFailure>()))
                .having((f) => f.message, 'message', 'You can try this quiz again in 24 hours.'),
          ),
        ),
      );
    });
  });
}
