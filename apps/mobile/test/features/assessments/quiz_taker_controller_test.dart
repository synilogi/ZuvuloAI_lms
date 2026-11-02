import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/platform/clock.dart';
import 'package:syniastrolms_mobile/features/assessments/assessments.dart';
import 'package:syniastrolms_mobile/features/course_learning/course_learning.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

/// A captured response, as a fresh map a test may change.
Map<String, dynamic> _json(String path) =>
    jsonDecode(jsonEncode(fixture(path))) as Map<String, dynamic>;

/// Where a learner stands before their first attempt: the captured standing with nothing open.
Map<String, dynamic> _fresh() {
  final read = _json('learning/quiz-attempts-open.json');
  final standing = read['standing'] as Map<String, dynamic>
    ..remove('openSession')
    ..['attemptsUsed'] = 0;
  return {'attempts': <Object>[], 'standing': standing};
}

/// The captured start, with a different time left.
Map<String, dynamic> _startWith({int? remainingSec, String? serverNow}) {
  final start = _json('learning/quiz-session-start.json');
  final session = start['session'] as Map<String, dynamic>;
  if (remainingSec != null) session['remainingSec'] = remainingSec;
  if (serverNow != null) session['serverNow'] = serverNow;
  return start;
}

/// The captured stored session after a save numbered [seq], with [answers] and the server's clock
/// at [serverNow].
Map<String, dynamic> _saved(int seq, Map<String, Object> answers, {String? serverNow}) {
  final saved = _json('learning/quiz-session-saved.json');
  saved['answersSeq'] = seq;
  saved['answers'] = answers;
  if (serverNow != null) saved['serverNow'] = serverNow;
  return saved;
}

const _target = (courseId: 'c1', lessonId: 'l1');

void main() {
  late FakeAdapter adapter;
  late ProviderContainer container;
  late Duration now;
  late LearnerQuiz quiz;

  ProviderContainer makeContainer({QuizTimings? timings}) {
    final c = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        ...publicScope(adapter: adapter, signedInAs: learner(), child: const SizedBox()).overrides,
        monotonicClockProvider.overrideWithValue(() => now),
        quizTimingsProvider.overrideWithValue(
          timings ??
              const QuizTimings(
                saveDelay: Duration(milliseconds: 15),
                // The countdown is driven by hand through tick().
                tick: Duration(hours: 1),
                retryDelays: [Duration(milliseconds: 10), Duration(milliseconds: 10)],
              ),
        ),
      ],
    );
    addTearDown(c.dispose);
    // Kept alive for the test, as the taker would.
    c.listen(quizTakerProvider(_target), (_, _) {});
    return c;
  }

  setUp(() {
    adapter = FakeAdapter();
    now = Duration.zero;
    quiz = LearnerQuiz.fromJson(_json('learning/lesson-quiz-timed.json'));
    container = makeContainer();
  });

  QuizTakerState read() => container.read(quizTakerProvider(_target));
  QuizTakerController notifier() => container.read(quizTakerProvider(_target).notifier);

  /// Lets the fake network and short timers run.
  Future<void> settle([int rounds = 6]) async {
    for (var i = 0; i < rounds; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
  }

  /// Waits for [done], however busy the machine is.
  Future<void> until(bool Function() done) async {
    for (var i = 0; i < 300 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(done(), isTrue, reason: 'waited 3 s');
  }

  Iterable<RequestOptions> sent(String method, String pathEnd) =>
      adapter.requests.where((r) => r.method == method && r.path.endsWith(pathEnd));

  Future<void> openFresh() async {
    adapter.enqueueJson(_fresh());
    notifier().open(quiz);
    await until(() => read().phase != QuizPhase.loading);
  }

  Future<void> openAndStart({Map<String, dynamic>? start}) async {
    await openFresh();
    adapter.enqueueJson(start ?? _json('learning/quiz-session-start.json'), status: 201);
    await notifier().start();
  }

  group('starting', () {
    test('reads where the learner stands first, and starts nothing on its own', () async {
      await openFresh();

      expect(read().phase, QuizPhase.intro);
      expect(read().standing!.canStart, isTrue);
      expect(adapter.requests.single.path, '/learning/courses/c1/lessons/l1/quiz-attempts');
    });

    test('the questions are the session\'s, in its order — never the lesson\'s', () async {
      // An untimed quiz still lists questions in the lesson for old apps; they are not used.
      quiz = LessonView.fromJson(_json('learning/lesson-quiz.json')).quiz!;
      expect(quiz.questions, hasLength(4));

      await openAndStart();

      final state = read();
      expect(state.phase, QuizPhase.answering);
      expect(state.questions.map((q) => q.id), ['q1', 'q2', 'q3']);
      expect(state.questions.first.prompt, 'What is (−3) × (−4)?');
      expect(state.remaining, const Duration(seconds: 899));
      expect(state.answers, isEmpty);
    });

    test('one key per tap, sent again when that tap is retried after a lost request', () async {
      await openFresh();
      adapter.enqueueError(DioExceptionType.connectionError);
      await notifier().start();
      expect(read().phase, QuizPhase.intro);
      expect(read().failure, isA<NetworkFailure>());
      final first = (sent('POST', '/quiz-session').last.data! as Map)['startKey'] as String;
      expect(first, matches(RegExp(r'^[0-9a-f]{32}$')));

      adapter.enqueueJson(_json('learning/quiz-session-start.json'), status: 201);
      await notifier().start();

      final second = (sent('POST', '/quiz-session').last.data! as Map)['startKey'];
      expect(second, first, reason: 'the server answers a retried start with the same session');
      expect(read().phase, QuizPhase.answering);
    });

    test('a refusal says why in the academy\'s words, and the next tap is a new one', () async {
      await openFresh();
      adapter
        ..enqueueJson(fixture('errors/quiz-retake-wait.json'), status: 409)
        // The standing is read again after a refusal.
        ..enqueueJson(_fresh());
      await notifier().start();
      final first = (sent('POST', '/quiz-session').last.data! as Map)['startKey'];

      expect(read().refusal, 'You can try this quiz again in 24 hours.');
      expect(read().failure, isNull);
      await until(() => adapter.queue.isEmpty);

      adapter.enqueueJson(_json('learning/quiz-session-start.json'), status: 201);
      await notifier().start();
      expect((sent('POST', '/quiz-session').last.data! as Map)['startKey'], isNot(first));
    });

    test('a quiz that has not opened says when it opens', () async {
      await openFresh();
      adapter
        ..enqueueJson({
          'message': 'This quiz has not opened yet.',
          'code': 'TEST_NOT_OPEN',
          'issues': {'opensAt': '2026-11-01T04:30:00.000Z'},
        }, status: 409)
        ..enqueueJson(_fresh());

      await notifier().start();

      expect(read().refusal, 'This quiz has not opened yet.');
      await until(() => adapter.queue.isEmpty);
      expect(read().opensAt, DateTime.utc(2026, 11, 1, 4, 30));
    });
  });

  group('resuming', () {
    test('an open attempt is picked up with the answers the server holds', () async {
      adapter
        ..enqueueJson(_json('learning/quiz-attempts-open.json'))
        ..enqueueJson(_json('learning/quiz-session-current.json'));

      notifier().open(quiz);
      await until(() => read().phase != QuizPhase.loading);

      expect(sent('POST', '/quiz-session'), isEmpty, reason: 'resuming starts nothing');
      final state = read();
      expect(state.phase, QuizPhase.answering);
      expect(state.answers, {
        'q1': ['b'],
      });
      expect(state.savedAnswers, state.answers);
      expect(state.save, QuizSaveStatus.saved);

      // Saves carry on from the server's number.
      adapter.enqueueJson(
        _saved(2, {
          'q1': ['a'],
        }),
      );
      notifier().answerOne('q1', 'a');
      await settle();
      expect((sent('PUT', '/answers').single.data! as Map)['seq'], 2);
    });

    test('an attempt the server will not let the learner back into shows the reason', () async {
      final read0 = _json('learning/quiz-attempts-open.json');
      (read0['standing'] as Map<String, dynamic>)
        ..['canStart'] = false
        ..['blockedReason'] = 'Your access to this course is paused.';
      adapter.enqueueJson(read0);

      notifier().open(quiz);
      await until(() => read().phase != QuizPhase.loading);

      expect(read().phase, QuizPhase.intro);
      expect(read().standing!.blockedReason, 'Your access to this course is paused.');
      expect(sent('GET', '/quiz-session'), isEmpty);
    });
  });

  group('autosave', () {
    test('changes made close together go as one save of the whole sheet', () async {
      await openAndStart();
      adapter.enqueueJson(
        _saved(1, {
          'q1': ['a'],
          'q2': ['false'],
          'q3': '75%',
        }),
      );

      notifier()
        ..answerOne('q1', 'b')
        ..answerOne('q1', 'a')
        ..answerOne('q2', 'false')
        ..writeAnswer('q3', '75%');
      expect(read().save, QuizSaveStatus.unsaved);
      expect(read().savedOnServer(read().questions.first), isFalse);
      await settle();

      final save = sent('PUT', '/answers').single;
      expect(save.data, {
        'answers': {
          'q1': ['a'],
          'q2': ['false'],
          'q3': '75%',
        },
        'seq': 1,
      });
      expect(read().save, QuizSaveStatus.saved);
      expect(read().savedOnServer(read().questions.first), isTrue);
    });

    test('a change made while a save is in flight goes next, numbered higher', () async {
      await openAndStart();
      final held = Completer<ResponseBody>();
      adapter
        ..enqueue((_) => held.future)
        ..enqueueJson(
          _saved(2, {
            'q1': ['a'],
            'q2': ['true'],
          }),
        );

      notifier().answerOne('q1', 'a');
      await settle();
      expect(read().save, QuizSaveStatus.saving);
      notifier().answerOne('q2', 'true');
      await settle();
      expect(sent('PUT', '/answers'), hasLength(1), reason: 'one save in flight at a time');

      held.complete(
        FakeAdapter.jsonResponse(
          _saved(1, {
            'q1': ['a'],
          }),
        ),
      );
      await settle();

      final saves = sent('PUT', '/answers').toList();
      expect(saves.map((r) => (r.data! as Map)['seq']), [1, 2]);
      expect((saves.last.data! as Map)['answers'], {
        'q1': ['a'],
        'q2': ['true'],
      });
      expect(read().save, QuizSaveStatus.saved);
      expect(read().savedAnswers, read().answers);
    });

    test('a sheet the server ignored for a higher number goes again above it', () async {
      await openAndStart();
      adapter
        // Another device already saved number 5: ours (1) was ignored.
        ..enqueueJson(
          _saved(5, {
            'q2': ['true'],
          }),
        )
        ..enqueueJson(
          _saved(6, {
            'q1': ['a'],
          }),
        );

      notifier().answerOne('q1', 'a');
      await settle();

      expect(sent('PUT', '/answers').map((r) => (r.data! as Map)['seq']), [1, 6]);
      expect(read().save, QuizSaveStatus.saved);
      expect(read().savedAnswers, {
        'q1': ['a'],
      });
    });

    test('an older answer from the server never winds the countdown back', () async {
      await openAndStart(start: _startWith(serverNow: '2026-10-26T07:46:40.000Z'));
      adapter.enqueueJson(
        // Answered "later" but stamped before the start — a response that lost the race.
        _saved(1, {
          'q1': ['a'],
        }, serverNow: '2026-10-26T07:46:30.000Z')..['remainingSec'] = 5,
      );
      now = const Duration(seconds: 10);

      notifier().answerOne('q1', 'a');
      await settle();
      notifier().tick();

      expect(read().remaining, const Duration(seconds: 889));
    });

    test(
      'offline or a server error: the save retries on its own, then stops and offers a retry',
      () async {
        await openAndStart();
        adapter
          ..enqueueJson({'message': 'Server error.'}, status: 500)
          ..enqueueError(DioExceptionType.connectionError)
          ..enqueueError(DioExceptionType.connectionError);

        notifier().answerOne('q1', 'a');
        await settle(1);
        expect(read().save, anyOf(QuizSaveStatus.retrying, QuizSaveStatus.saving));
        await until(() => read().save == QuizSaveStatus.failed);

        expect(read().save, QuizSaveStatus.failed);
        expect(sent('PUT', '/answers'), hasLength(3));
        expect(read().savedOnServer(read().questions.first), isFalse);

        adapter.enqueueJson(
          _saved(4, {
            'q1': ['a'],
          }),
        );
        await notifier().retrySave();

        expect(read().save, QuizSaveStatus.saved);
        final numbers = sent('PUT', '/answers').map((r) => (r.data! as Map)['seq']).toList();
        expect(numbers, [1, 2, 3, 4], reason: 'every send numbered above the last');
      },
    );

    test('access paused mid-attempt: the save stops and says why, without retrying', () async {
      await openAndStart();
      adapter.enqueueJson({
        'message': 'Your access to this course is paused.',
        'code': 'ENROLLMENT_PAUSED',
      }, status: 409);

      notifier().answerOne('q1', 'a');
      await until(() => read().save == QuizSaveStatus.failed);
      await settle();

      expect(read().saveFailure, isA<EnrollmentFailure>());
      expect(read().saveFailure!.message, 'Your access to this course is paused.');
      expect(sent('PUT', '/answers'), hasLength(1));
    });

    test('an attempt already handed in stops the saves and shows its result', () async {
      await openAndStart();
      adapter
        ..enqueueJson(fixture('errors/quiz-finished.json'), status: 409)
        ..enqueueJson(_json('learning/quiz-session-submitted-repeat.json'));

      notifier().answerOne('q1', 'a');
      await settle();

      expect(read().phase, QuizPhase.result);
      expect(read().result!.percent, 33);
      expect(sent('POST', '/submit'), hasLength(1));
      notifier().answerOne('q2', 'true');
      await settle();
      expect(sent('PUT', '/answers'), hasLength(1), reason: 'nothing is saved after the end');
    });
  });

  group('time', () {
    test('the countdown is the server\'s time less what the monotonic clock measured', () async {
      await openAndStart();

      now = const Duration(seconds: 60);
      notifier().tick();

      expect(read().remaining, const Duration(seconds: 839));
    });

    test('warnings at five minutes and one minute, each once', () async {
      await openAndStart();

      now = const Duration(seconds: 899 - 299);
      notifier().tick();
      expect(read().warning, TimeWarning.fiveMinutes);
      now = const Duration(seconds: 899 - 59);
      notifier().tick();
      expect(read().warning, TimeWarning.oneMinute);
    });

    test('at zero the answers lock and the attempt is handed in', () async {
      await openAndStart();
      notifier().answerOne('q1', 'a');
      adapter
        ..enqueueJson(
          _saved(1, {
            'q1': ['a'],
          }),
        )
        ..enqueueJson(_json('learning/quiz-session-submitted.json'));
      await settle();

      now = const Duration(seconds: 900);
      notifier().tick();
      expect(read().timeUp, isTrue);
      expect(read().locked, isTrue);
      notifier().answerOne('q2', 'true');
      expect(read().answers.containsKey('q2'), isFalse, reason: 'locked at the deadline');
      await settle();

      expect(read().phase, QuizPhase.result);
      expect(sent('POST', '/submit'), hasLength(1));
    });

    test('time up while offline: the hand-in goes the moment the connection is back', () async {
      // Seen on the Infinix (2026-10-26): reconnecting called flush(), which cancelled the
      // hand-in's pending retry and returned because time was up — nothing was ever sent again.
      container = makeContainer(
        timings: const QuizTimings(
          saveDelay: Duration(milliseconds: 15),
          tick: Duration(hours: 1),
          // So long that only the reconnect can be what sends it.
          retryDelays: [Duration(hours: 1)],
        ),
      );
      await openAndStart();
      adapter.enqueueError(DioExceptionType.connectionError);
      now = const Duration(seconds: 900);
      notifier().tick();
      await until(() => sent('POST', '/submit').length == 1);
      expect(read().phase, QuizPhase.submitting);
      expect(read().failure, isA<NetworkFailure>());

      adapter.enqueueJson(_json('learning/quiz-session-submitted.json'));
      // What the screen does when the network comes back, or the app returns to the front.
      await notifier().flush();
      await until(() => read().phase == QuizPhase.result);
      expect(sent('POST', '/submit'), hasLength(2));
    });

    test('an untimed attempt has no countdown at all', () async {
      final start = _startWith();
      (start['session'] as Map<String, dynamic>)
        ..remove('remainingSec')
        ..remove('deadlineAt');
      await openAndStart(start: start);

      now = const Duration(hours: 5);
      notifier().tick();

      expect(read().remaining, isNull);
      expect(read().timeUp, isFalse);
    });

    test('resumed with no time left, it is handed in at once', () async {
      adapter.enqueueJson(_fresh());
      notifier().open(quiz);
      await until(() => read().phase != QuizPhase.loading);
      adapter
        ..enqueueJson(_startWith(remainingSec: 0), status: 200)
        ..enqueueJson(_json('learning/quiz-session-submitted.json'));

      await notifier().start();
      await settle();

      expect(read().phase, QuizPhase.result);
    });
  });

  group('handing in', () {
    test('sends the final sheet once, however often it is asked, and shows one result', () async {
      await openAndStart();
      notifier().answerOne('q1', 'a');
      final held = Completer<ResponseBody>();
      adapter.enqueue((_) => held.future);

      final first = notifier().submit();
      await notifier().submit();
      held.complete(FakeAdapter.jsonResponse(fixture('learning/quiz-session-submitted.json')));
      await first;
      await notifier().submit();

      final submits = sent('POST', '/submit').toList();
      expect(submits, hasLength(1));
      expect((submits.single.data! as Map)['answers'], {
        'q1': ['a'],
      });
      expect(sent('PUT', '/answers'), isEmpty, reason: 'the pending save went with the hand-in');
      final state = read();
      expect(state.phase, QuizPhase.result);
      expect(state.result!.keyWithheld, isTrue);
      expect(state.history.map((a) => a.attemptId), ['cmvoydpiz000fmmtfbqwn32qd']);
      expect(state.standing!.canStart, isTrue);
    });

    test('a lost hand-in can be sent again: the server answers with the same result', () async {
      await openAndStart();
      adapter.enqueueError(DioExceptionType.connectionError);

      await notifier().submit();
      expect(read().phase, QuizPhase.review);
      expect(read().failure, isA<NetworkFailure>());

      adapter.enqueueJson(_json('learning/quiz-session-submitted-repeat.json'));
      await notifier().submit();

      expect(read().phase, QuizPhase.result);
      expect(read().history, hasLength(1));
    });

    test('a refusal keeps the answers and says why', () async {
      await openAndStart();
      notifier().answerOne('q1', 'a');
      adapter.enqueueJson({'message': 'Your access to this course has ended.'}, status: 409);

      await notifier().submit();

      expect(read().phase, QuizPhase.review);
      expect(read().refusal, 'Your access to this course has ended.');
      expect(read().answers, {
        'q1': ['a'],
      });
    });

    test('another go starts from the introduction, when the server allows one', () async {
      await openAndStart();
      adapter.enqueueJson(_json('learning/quiz-session-submitted.json'));
      await notifier().submit();

      notifier().retake();

      final state = read();
      expect(state.phase, QuizPhase.intro);
      expect(state.answers, isEmpty);
      expect(state.history, hasLength(1));
    });
  });

  group('the app in the background', () {
    test('going to the background sends what is unsaved at once', () async {
      container = makeContainer(
        timings: const QuizTimings(saveDelay: Duration(hours: 1), tick: Duration(hours: 1)),
      );
      await openAndStart();
      adapter.enqueueJson(
        _saved(1, {
          'q1': ['a'],
        }),
      );
      notifier().answerOne('q1', 'a');

      notifier().onAppPaused();
      await until(() => read().save == QuizSaveStatus.saved);

      expect(sent('PUT', '/answers'), hasLength(1));
      expect(read().save, QuizSaveStatus.saved);
    });

    test('coming back reads the server\'s time and answers again', () async {
      await openAndStart();
      final current = _json('learning/quiz-session-current.json');
      (current['session'] as Map<String, dynamic>)
        ..['remainingSec'] = 120
        ..['serverNow'] = '2026-10-26T07:59:37.000Z';
      adapter.enqueueJson(current);
      // The phone slept; its own clock says little time passed.
      now = const Duration(seconds: 5);

      await notifier().onAppResumed();

      expect(read().remaining, const Duration(seconds: 120));
      expect(read().answers, {
        'q1': ['b'],
      }, reason: 'saved on another device meanwhile');
    });

    test('an attempt the server finished meanwhile shows its result', () async {
      await openAndStart();
      final finished = _json('learning/quiz-session-current.json');
      (finished['session'] as Map<String, dynamic>)
        ..['status'] = 'expired'
        ..['attemptId'] = 'cmvoydpiz000fmmtfbqwn32qd';
      finished['questions'] = <Object>[];
      final submitted = _json('learning/quiz-session-submitted.json');
      final review = (submitted['review'] as Map<String, dynamic>)..['finish'] = 'expired';
      adapter
        ..enqueueJson(finished)
        ..enqueueJson({
          'attempts': [review],
          'standing': submitted['standing'],
        });

      await notifier().onAppResumed();
      await until(() => read().result != null);

      expect(read().phase, QuizPhase.result);
      expect(read().expired, isTrue);
      expect(read().result!.attemptId, 'cmvoydpiz000fmmtfbqwn32qd');
    });
  });
}
