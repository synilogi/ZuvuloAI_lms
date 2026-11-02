import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/assessments/assessments.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(jsonEncode(fixture(path))) as Map<String, dynamic>;

/// Before the first attempt: the captured standing with nothing open.
Map<String, dynamic> _fresh() {
  final read = _json('learning/quiz-attempts-open.json');
  (read['standing'] as Map<String, dynamic>)
    ..remove('openSession')
    ..['attemptsUsed'] = 0;
  return read;
}

/// The captured hand-in, with its review changed by [edit].
Map<String, dynamic> _handedIn([void Function(Map<String, dynamic> review)? edit]) {
  final body = _json('learning/quiz-session-submitted.json');
  edit?.call(body['review'] as Map<String, dynamic>);
  return body;
}

void main() {
  late FakeAdapter adapter;
  late Duration mono;

  setUp(() {
    adapter = FakeAdapter();
    mono = Duration.zero;
  });

  Future<void> pumpTaker(
    WidgetTester tester, {
    int? best,
    double textScale = 1,
    bool negativeMarking = false,
  }) async {
    final quiz = LearnerQuiz.fromJson({
      ..._json('learning/lesson-quiz-timed.json'),
      'negativeMarking': negativeMarking,
    });
    await pumpPublic(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: QuizTaker(quiz: quiz, courseId: 'c1', lessonId: 'l1', best: best),
              ),
            ),
          ),
        ),
      ),
      adapter: adapter,
      signedInAs: learner(),
      monotonicClock: () => mono,
    );
    await tester.pumpAndSettle();
  }

  Future<void> start(WidgetTester tester) async {
    adapter.enqueueJson(_json('learning/quiz-session-start.json'), status: 201);
    await tester.tap(find.text('Start the quiz'));
    await tester.pumpAndSettle();
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    final button = find.widgetWithText(AppButton, label).last;
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  /// Walks to the last question and on to the review.
  Future<void> goToReview(WidgetTester tester) async {
    while (find.widgetWithText(AppButton, 'Next').evaluate().isNotEmpty) {
      await tapButton(tester, 'Next');
    }
    await tapButton(tester, 'Review answers');
  }

  Future<void> submit(WidgetTester tester) async {
    await tapButton(tester, 'Submit');
    expect(find.text('Submit this attempt?'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, 'Submit').last);
    await tester.pumpAndSettle();
  }

  /// Takes the attempt through to the server's result.
  Future<void> handIn(WidgetTester tester, Map<String, dynamic> response) async {
    adapter.enqueueJson(_fresh());
    await pumpTaker(tester);
    await start(tester);
    await goToReview(tester);
    adapter.enqueueJson(response);
    await submit(tester);
  }

  testWidgets('the introduction says what the quiz asks and where the learner stands', (
    tester,
  ) async {
    adapter.enqueueJson(_fresh());
    await pumpTaker(tester, best: 60);

    expect(find.text('Integers: check your understanding'), findsOneWidget);
    expect(find.text('3 questions · pass 70%'), findsOneWidget);
    expect(find.text('30 marks'), findsOneWidget);
    expect(find.text('15 minute limit'), findsOneWidget);
    expect(find.text('0 of 2 attempts used'), findsOneWidget);
    expect(find.textContaining('The timer starts when you tap Start'), findsOneWidget);
    expect(find.text('Best so far 60%'), findsOneWidget);
    expect(find.text('Start the quiz'), findsOneWidget);
    expect(adapter.requests.single.path, endsWith('/quiz-attempts'), reason: 'nothing started');
    expect(find.textContaining('Wrong answers lose marks'), findsNothing);
  });

  testWidgets('negative marking is said before Start, though the lesson sends no questions', (
    tester,
  ) async {
    adapter.enqueueJson(_fresh());
    await pumpTaker(tester, negativeMarking: true);

    expect(
      find.text('Wrong answers lose marks. Leaving a question blank costs nothing.'),
      findsOneWidget,
    );
    expect(find.text('Start the quiz'), findsOneWidget);
  });

  testWidgets('a time the server names reads on the academy\'s clock', (tester) async {
    final read = _fresh();
    (read['standing'] as Map<String, dynamic>)
      ..['window'] = 'upcoming'
      ..['canStart'] = false
      ..['blockedReason'] = 'This quiz has not opened yet.'
      ..['opensAt'] = '2026-11-01T04:30:00.000Z';
    adapter.enqueueJson(read);
    await pumpTaker(tester);

    expect(find.textContaining('Opens 1 Nov 2026, 10:00 AM'), findsOneWidget);
    expect(find.text('This quiz has not opened yet.'), findsOneWidget);
  });

  testWidgets('a quiz the learner may not take says why, and offers no way in', (tester) async {
    final read = _fresh();
    (read['standing'] as Map<String, dynamic>)
      ..['canStart'] = false
      ..['attemptsUsed'] = 2
      ..['blockedReason'] = 'You have used all 2 attempts for this quiz.';
    adapter.enqueueJson(read);
    await pumpTaker(tester);

    expect(find.text('You have used all 2 attempts for this quiz.'), findsOneWidget);
    expect(find.text('Start the quiz'), findsNothing);
    expect(find.text('Resume the quiz'), findsNothing);
  });

  testWidgets(
    'the attempt shows the server\'s questions, its timer and whether answers are saved',
    (tester) async {
      adapter.enqueueJson(_fresh());
      await pumpTaker(tester);
      await start(tester);

      expect(find.text('What is (−3) × (−4)?'), findsOneWidget);
      expect(find.text('14:59 left'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Time left: 14:59'),
        findsOneWidget,
        reason: 'read as a sentence, not every second',
      );
      expect(find.bySemanticsLabel('Question 1, Not answered, on screen'), findsOneWidget);
      expect(find.bySemanticsLabel('Question 3, Not answered'), findsOneWidget);
      // The palette is a row of numbers, not one question per line (seen stacked on the Infinix).
      final first = tester.getRect(find.bySemanticsLabel('Question 1, Not answered, on screen'));
      final third = tester.getRect(find.bySemanticsLabel('Question 3, Not answered'));
      expect(third.top, first.top);
      expect(first.width, lessThan(120));

      await tester.tap(find.text('12'));
      await tester.pump();
      expect(find.text('Not saved yet'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Question 1, Answered · not saved yet, on screen'),
        findsOneWidget,
      );

      final saved = _json('learning/quiz-session-saved.json')
        ..['answers'] = {
          'q1': ['a'],
        };
      adapter.enqueueJson(saved);
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(find.text('Saved'), findsOneWidget);
      expect(find.bySemanticsLabel('Question 1, Answered, on screen'), findsOneWidget);
      final put = adapter.requests.last;
      expect(put.method, 'PUT');
      expect(put.data, {
        'answers': {
          'q1': ['a'],
        },
        'seq': 1,
      });
    },
  );

  testWidgets('true or false answers with the server\'s own option ids', (tester) async {
    adapter.enqueueJson(_fresh());
    await pumpTaker(tester);
    await start(tester);
    await tester.tap(find.bySemanticsLabel('Question 2, Not answered'));
    await tester.pumpAndSettle();

    adapter.enqueueJson(_json('learning/quiz-session-saved.json'));
    await tester.tap(find.text('False'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect((adapter.requests.last.data! as Map)['answers'], {
      'q2': ['false'],
    });
  });

  testWidgets('the review counts what is unanswered, and the result is the server\'s', (
    tester,
  ) async {
    adapter.enqueueJson(_fresh());
    await pumpTaker(tester);
    await start(tester);
    await goToReview(tester);

    expect(find.text('Your answers'), findsOneWidget);
    expect(find.text('3 questions are unanswered'), findsOneWidget);

    adapter.enqueueJson(_handedIn());
    await submit(tester);

    expect(find.text('Not passed this time'), findsOneWidget);
    expect(find.text('33%'), findsWidgets);
    expect(find.text('10 of 30 marks'), findsOneWidget);
    expect(find.text('Pass mark 70%'), findsOneWidget);
    expect(find.textContaining('Correct answers are shown once you pass'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget, reason: 'the standing allows another attempt');
  });

  testWidgets('a breakdown shows each question as the server marked it, negative marks too', (
    tester,
  ) async {
    await handIn(
      tester,
      _handedIn((review) {
        review
          ..['showResults'] = 'score-and-answers'
          ..['keyWithheld'] = false
          ..['points'] = -2.5
          ..['percent'] = 0
          ..['questions'] = {
            'q1': {
              'state': 'incorrect',
              'points': -2.5,
              'answer': ['b'],
              'correct': ['a'],
              'explanation': 'Two negatives make a positive.',
            },
            'q2': {'state': 'unanswered', 'points': 0},
          };
      }),
    );

    expect(find.text('Question by question'), findsOneWidget);
    expect(find.text('Wrong'), findsOneWidget);
    expect(find.text('−2.5 marks'), findsOneWidget);
    expect(find.text('Your answer: −12'), findsOneWidget);
    expect(find.text('Answer: 12'), findsOneWidget);
    expect(find.text('Two negatives make a positive.'), findsOneWidget);
    expect(find.textContaining('a total can fall below zero'), findsOneWidget);
    expect(find.textContaining('Correct answers are shown once'), findsNothing);
  });

  testWidgets('a result held until the quiz closes says when, and shows no score', (tester) async {
    await handIn(
      tester,
      _handedIn((review) {
        review
          ..['showResults'] = 'hidden'
          ..remove('percent')
          ..remove('points')
          ..remove('max')
          ..remove('keyWithheld')
          ..['resultsAt'] = '2026-11-01T04:30:00.000Z';
      }),
    );

    expect(find.text('Attempt handed in'), findsOneWidget);
    expect(find.textContaining('Results are shown on'), findsOneWidget);
    expect(find.text('33%'), findsNothing);
  });

  testWidgets('at zero the answers lock and the attempt is handed in; the result says so', (
    tester,
  ) async {
    adapter.enqueueJson(_fresh());
    await pumpTaker(tester);
    await start(tester);

    // Five minutes left: said once, out loud.
    mono = const Duration(seconds: 600);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('5 minutes left.'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    adapter.enqueueJson(
      _handedIn((review) => review['finish'] = 'expired')
        ..['session'] = {
          ...(_json('learning/quiz-session-submitted.json')['session'] as Map<String, dynamic>),
          'status': 'expired',
        },
    );
    mono = const Duration(seconds: 900);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Time ran out — your saved answers were marked.'), findsOneWidget);
    expect(adapter.requests.last.path, endsWith('/submit'));
  });

  testWidgets('Back during an attempt asks first, and says the timer keeps running', (
    tester,
  ) async {
    adapter.enqueueJson(_fresh());
    await pumpTaker(tester);
    await start(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Leave the quiz?'), findsOneWidget);
    expect(find.text('Your answers are saved; the timer keeps running.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('What is (−3) × (−4)?'), findsOneWidget);
  });

  testWidgets('the app going to the background saves at once; coming back reads the server again', (
    tester,
  ) async {
    adapter.enqueueJson(_fresh());
    await pumpTaker(tester);
    await start(tester);
    await tester.tap(find.text('12'));
    await tester.pump();

    adapter.enqueueJson(_json('learning/quiz-session-saved.json'));
    // As a phone reports it: one step at a time.
    for (final step in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(step);
    }
    // Well inside the 800 ms the save would otherwise wait.
    await tester.pump(const Duration(milliseconds: 100));
    expect(adapter.requests.last.method, 'PUT', reason: 'sent without waiting for the delay');

    final current = _json('learning/quiz-session-current.json');
    (current['session'] as Map<String, dynamic>)['remainingSec'] = 125;
    adapter.enqueueJson(current);
    for (final step in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(step);
    }
    await tester.pumpAndSettle();

    expect(adapter.requests.last.method, 'GET');
    expect(adapter.requests.last.path, endsWith('/quiz-session'));
    expect(find.text('2:05 left'), findsOneWidget);
  });

  testWidgets('every step reads at twice the text size without overflowing', (tester) async {
    adapter.enqueueJson(_fresh());
    await pumpTaker(tester, textScale: 2);
    expect(tester.takeException(), isNull);

    await start(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('14:59 left'), findsOneWidget);

    await goToReview(tester);
    expect(tester.takeException(), isNull);

    adapter.enqueueJson(_handedIn());
    await submit(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Not passed this time'), findsOneWidget);
  });
}
