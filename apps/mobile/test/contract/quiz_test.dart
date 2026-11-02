import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/assessments/assessments.dart';
import 'package:syniastrolms_mobile/features/course_learning/course_learning.dart';

/// Contract tests (§23) for the learner's quizzes, against what the real API returned.
Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

void main() {
  test('GET /learning/assessments — one row open, one still locked', () {
    final rows = [
      for (final row in _fixture('learning/assessments-open.json')! as List<dynamic>)
        AssessmentRow.fromJson(row as Map<String, dynamic>),
    ];

    final open = rows.firstWhere((r) => r.state == AssessmentState.available);
    expect(open.questions, 4);
    expect(open.passMark, 70);
    expect(open.attemptsAllowed, 3);
    expect(open.attemptsUsed, 0);
    expect(open.attemptsLeft, 3);
    expect(open.isOpen, isTrue);

    final locked = rows.firstWhere((r) => r.state == AssessmentState.locked);
    expect(locked.lockedReason, isNotEmpty);
    expect(locked.isOpen, isFalse);
  });

  test('an academy that sets no attempt limit leaves the count open', () {
    const unlimited = AssessmentRow(id: 'q', lessonId: 'l', courseId: 'c');

    expect(unlimited.attemptsLeft, isNull);
  });

  group('the quiz a lesson delivers', () {
    late LessonView view;

    setUp(
      () => view = LessonView.fromJson(
        _fixture('learning/lesson-quiz.json')! as Map<String, dynamic>,
      ),
    );

    test('carries every question type the app renders', () {
      final quiz = view.quiz!;

      expect(quiz.questions.map((q) => q.type), [
        QuestionType.single,
        QuestionType.trueFalse,
        QuestionType.short,
        QuestionType.multiple,
      ]);
      expect(quiz.settings.passMark, 70);
      expect(quiz.settings.attempts, 3);
      expect(quiz.totalPoints, 40);
    });

    test('a chosen question brings its options and nothing about the answer', () {
      final single = view.quiz!.questions.first;
      final raw =
          ((_fixture('learning/lesson-quiz.json')! as Map<String, dynamic>)['quiz']!
                  as Map<String, dynamic>)['questions']!
              as List<dynamic>;

      expect(single.options.map((o) => o.id), ['a', 'b', 'c', 'd']);
      expect(single.points, 10);
      expect(single.required, isTrue);
      // The route strips the key before it leaves the server.
      expect((raw.first as Map<String, dynamic>).containsKey('correct'), isFalse);
      expect((raw.first as Map<String, dynamic>).containsKey('acceptedAnswers'), isFalse);
    });

    test('the model has nowhere to put an answer key, even if one arrived', () {
      final question = LearnerQuizQuestion.fromJson(const {
        'id': 'q1',
        'type': 'single',
        'prompt': 'Which house is a kendra?',
        'options': [
          {'id': 'a', 'text': '1st'},
        ],
        'points': 10,
        'required': true,
        'correct': ['a'],
        'acceptedAnswers': ['the first'],
        'explanation': 'Kendras are 1, 4, 7 and 10.',
      });

      final round = question.toJson();
      expect(round.containsKey('correct'), isFalse);
      expect(round.containsKey('acceptedAnswers'), isFalse);
      expect(round.containsKey('explanation'), isFalse);
      expect(jsonEncode(round), isNot(contains('Kendras are 1, 4, 7 and 10.')));
      expect(round.keys, ['id', 'type', 'prompt', 'options', 'points', 'required']);
    });

    test('a short-answer question has no options to choose from', () {
      final short = view.quiz!.questions.firstWhere((q) => q.type == QuestionType.short);

      expect(short.options, isEmpty);
      expect(short.isWritten, isTrue);
      expect(short.isMultiple, isFalse);
    });

    test('a question type this build does not know is not guessed at', () {
      final unknown = LearnerQuizQuestion.fromJson(const {
        'id': 'q9',
        'type': 'matching',
        'prompt': 'Pair them up',
      });

      expect(unknown.type, QuestionType.unknown);
    });
  });

  group('an attempt', () {
    test('a literal null is the route\'s way of saying "not passed"', () {
      expect(_fixture('learning/quiz-attempt-not-passed.json'), isNull);
    });

    test('passing answers with the same completion that finishing a lesson gives', () {
      final result = CompleteResult.fromJson(
        _fixture('learning/quiz-attempt-passed.json')! as Map<String, dynamic>,
      );

      expect(result.progress.percent, 100);
      expect(result.chapterCompleted, 'Magha to Moola');
      expect(result.courseCompleted, isTrue);
    });

    test('the academy may refuse the attempt outright, in its own words', () {
      expect(
        (_fixture('errors/quiz-retake-wait.json')! as Map<String, dynamic>)['message'],
        'You can try this quiz again in 24 hours.',
      );
    });
  });

  group('quiz sessions', () {
    Map<String, dynamic> map(String path) => _fixture(path)! as Map<String, dynamic>;

    test('a timed quiz\'s lesson carries no questions — only what the attempt will hold', () {
      final quiz = LearnerQuiz.fromJson(map('learning/lesson-quiz-timed.json'));

      expect(quiz.questions, isEmpty);
      expect(quiz.questionCount, 3);
      expect(quiz.totalPoints, 30);
      expect(quiz.attemptsUsed, 0);
      expect(quiz.window, QuizWindow.open);
      expect(quiz.openSession, isNull);
      expect(quiz.settings.timeLimitMin, 15);
      expect(quiz.settings.resultsRelease, ResultsRelease.onSubmit);
      expect(quiz.negativeMarking, isFalse);
      expect(
        LearnerQuiz.fromJson({
          ...map('learning/lesson-quiz-timed.json'),
          'negativeMarking': true,
        }).negativeMarking,
        isTrue,
        reason: 'said before an attempt starts, though the lesson sends no questions',
      );
    });

    test('a started session brings the server\'s clock, its deadline and the questions', () {
      final begun = QuizSessionStart.fromJson(map('learning/quiz-session-start.json'));

      expect(begun.session.status, QuizSessionStatus.active);
      expect(begun.session.remainingSec, 899);
      expect(begun.session.deadlineAt, DateTime.utc(2026, 10, 26, 8, 1, 37, 229));
      expect(begun.session.serverNow, isNotNull);
      expect(begun.session.answersSeq, 0);
      expect(begun.questions.map((q) => q.type), [
        QuestionType.single,
        QuestionType.trueFalse,
        QuestionType.short,
      ]);
      expect(begun.questions[1].options.map((o) => o.id), ['true', 'false']);
    });

    test('a stale save answers with the stored session, its number unchanged', () {
      final kept = QuizSessionView.fromJson(map('learning/quiz-session-saved.json'));
      final stale = QuizSessionView.fromJson(map('learning/quiz-session-saved-stale.json'));

      expect(kept.answersSeq, 1);
      expect(stale.answersSeq, kept.answersSeq);
      expect(stale.answerSheet, kept.answerSheet);
    });

    test('the standing names the open attempt and the attempts used', () {
      final read = QuizAttempts.fromJson(map('learning/quiz-attempts-open.json'));

      expect(read.standing.openSession!.id, 'cmvoydpgz000dmmtfl72u5oqz');
      expect(read.standing.canStart, isTrue);
      expect(read.standing.attemptsLeft, 1);
      expect(read.standing.blockedReason, isNull);
    });

    test('handing in answers with the review cut to the score while the key is withheld', () {
      final handedIn = QuizHandIn.fromJson(map('learning/quiz-session-submitted.json'));
      final again = QuizHandIn.fromJson(map('learning/quiz-session-submitted-repeat.json'));

      final review = handedIn.review!;
      expect(review.showResults, ResultsVisibility.scoreOnly);
      expect(review.keyWithheld, isTrue);
      expect(review.questions, isNull);
      expect(review.percent, 33);
      expect(review.points, 10);
      expect(review.max, 30);
      expect(review.attemptNo, 1);
      expect(review.finish, AttemptFinish.submitted);
      expect(review.held, isFalse);
      expect(handedIn.session.attemptId, review.attemptId);
      expect(handedIn.answersAccepted, isTrue);
      // Handing in again changes nothing: the same result, and the sheet not taken twice.
      expect(again.review, review);
      expect(again.answersAccepted, isFalse);
    });

    test('a later review may carry negative marks, the key, and an expiry', () {
      final review = AttemptReview.fromJson({
        ...map('learning/quiz-session-submitted.json')['review']! as Map<String, dynamic>,
        'showResults': 'score-and-answers',
        'points': -2.5,
        'percent': 0,
        'finish': 'expired',
        'keyWithheld': false,
        'questions': {
          'q1': {
            'state': 'incorrect',
            'points': -2.5,
            'answer': ['b'],
            'correct': ['a'],
            'explanation': 'Two negatives make a positive.',
          },
          'q3': {'state': 'unanswered', 'points': 0},
          'q9': {'state': 'something-new', 'points': 1},
        },
      });

      expect(review.points, -2.5);
      expect(review.expired, isTrue);
      expect(review.questions!['q1']!.state, AnswerState.incorrect);
      expect(review.questions!['q1']!.correct, ['a']);
      expect(review.questions!['q9']!.state, AnswerState.unknown);
    });

    test('a question with negative marks says so; one without keeps its old shape', () {
      final marked = LearnerQuizQuestion.fromJson(const {
        'id': 'q1',
        'type': 'single',
        'prompt': 'P',
        'points': 4,
        'negativePoints': 1,
      });

      expect(marked.losesMarks, isTrue);
      expect(marked.negativePoints, 1.0);
    });

    test('the assessment row says the window, and holds back no score it does not have', () {
      final row = AssessmentRow.fromJson(
        (_fixture('learning/assessment-row-quiz.json')! as List<dynamic>).single
            as Map<String, dynamic>,
      );

      expect(row.state, AssessmentState.failed);
      expect(row.window, QuizWindow.open);
      expect(row.score, 33);
      expect(row.resultsHeld, isFalse);
      expect(row.negativeMarking, isFalse);

      final held = AssessmentRow.fromJson({
        ...row.toJson(),
        'score': null,
        'resultsAt': '2026-11-01T04:30:00.000Z',
      });
      expect(held.resultsHeld, isTrue);
      expect(held.resultsAt, DateTime.utc(2026, 11, 1, 4, 30));
      expect(row.isOpen, isTrue);

      final inProgress = AssessmentRow.fromJson({
        ...row.toJson(),
        'state': 'in-progress',
        'deadlineAt': '2026-10-26T08:01:37.229Z',
      });
      expect(inProgress.inProgress, isTrue);
      expect(inProgress.isOpen, isTrue);
      expect(inProgress.deadlineAt, DateTime.utc(2026, 10, 26, 8, 1, 37, 229));

      final upcoming = AssessmentRow.fromJson({
        ...row.toJson(),
        'state': 'available',
        'window': 'upcoming',
        'opensAt': '2026-11-01T04:30:00.000Z',
      });
      expect(upcoming.isOpen, isFalse, reason: 'nothing to start until it opens');
    });
  });
}
