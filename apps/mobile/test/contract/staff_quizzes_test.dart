import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/staff_quizzes/staff_quizzes.dart';
import 'package:syniastrolms_mobile/shared/domain/quiz.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

/// Contract tests (§23) for the staff quiz screens, against what the real API returned.
Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

Map<String, dynamic> _map(String path) => _fixture(path)! as Map<String, dynamic>;

void main() {
  group('the academy\'s quizzes', () {
    late StaffQuizPage page;

    setUp(() => page = StaffQuizPage.fromJson(_map('staff/quizzes.json')));

    test('the counts cover every status tab', () {
      expect(page.countOf('all'), 2);
      expect(page.countOf('published'), 2);
      expect(page.countOf('draft'), 0);
      expect(page.countOf('retired'), 0);
      expect(page.isEmpty, isFalse);
    });

    test('every row says where the quiz lives and how big it is', () {
      for (final row in page.rows) {
        expect(row.quiz.id, isNotEmpty);
        expect(row.quiz.title, isNotEmpty);
        expect(row.quiz.status, isNot(StaffQuizStatus.unknown));
        expect(row.courseTitle, isNotEmpty);
        expect(row.points, greaterThan(0));
        expect(
          row.points,
          row.quiz.totalPoints,
          reason: 'the route sums the same points the app would',
        );
      }
    });

    test('a quiz nobody has attempted has no rate at all, rather than a zero', () {
      final attempted = page.rows.where((r) => r.attempts > 0);
      expect(attempted, isNotEmpty);
      for (final row in attempted) {
        expect(row.passRate, isNotNull);
        expect(row.avgScore, isNotNull);
      }
      // The route sends null, and the model keeps it null: a 0% pass rate would read as everyone
      // failing something nobody has taken.
      final none = StaffQuizRow.fromJson({
        'quiz': _map('staff/quiz.json'),
        'courseTitle': 'A course',
        'points': 30,
        'attempts': 0,
        'passRate': null,
        'avgScore': null,
      });
      expect(none.passRate, isNull);
      expect(none.avgScore, isNull);
    });
  });

  group('one quiz in full', () {
    late StaffQuiz quiz;

    setUp(() => quiz = StaffQuiz.fromJson(_map('staff/quiz.json')));

    test('it carries the settings the academy chose', () {
      expect(quiz.settings.passMark, 70);
      expect(quiz.settings.attempts, 3);
      expect(quiz.settings.unlimitedAttempts, isFalse);
      expect(quiz.settings.timeLimitMin, isNull);
      expect(quiz.settings.shuffleQuestions, isFalse);
      expect(quiz.settings.shuffleOptions, isTrue);
      expect(quiz.settings.showResults, ResultsVisibility.scoreAndAnswers);
    });

    test('unlimited attempts are the academy\'s own zero', () {
      expect(const StaffQuizSettings(attempts: 0).unlimitedAttempts, isTrue);
    });

    test('the points are summed from the questions', () {
      expect(quiz.questions, hasLength(3));
      expect(quiz.totalPoints, 30);
    });

    test('staff are served the answer key, question by question', () {
      final single = quiz.questions.first;
      expect(single.type, QuestionType.single);
      expect(single.options, hasLength(4));
      expect(single.correct, ['a']);
      expect(single.correctOptions.single.text, '1st house');
      expect(single.needed, isTrue, reason: '`required` on the wire');

      final trueFalse = quiz.questions[1];
      expect(trueFalse.type, QuestionType.trueFalse);
      expect(trueFalse.correct, isNotEmpty);

      final short = quiz.questions.last;
      expect(short.type, QuestionType.short);
      expect(short.options, isEmpty);
      expect(short.acceptedAnswers, isNotEmpty);
    });

    test('a question type this build does not know decodes to unknown', () {
      final question = StaffQuizQuestion.fromJson(const {
        'id': 'q9',
        'type': 'matching',
        'prompt': 'Pair them up',
        'points': 5,
      });
      expect(question.type, QuestionType.unknown);
      expect(question.needed, isTrue, reason: 'a question is required unless it says otherwise');
    });
  });

  group('how a quiz went', () {
    late QuizStats stats;

    setUp(() => stats = QuizStats.fromJson(_map('staff/quiz-stats.json')));

    test('the figures are the academy\'s, counted over attempts', () {
      expect(stats.attempts, 15);
      expect(stats.learners, 10);
      expect(
        stats.learners,
        lessThanOrEqualTo(stats.attempts),
        reason: 'someone who tries three times is three attempts and one learner',
      );
      expect(stats.passRate, 67);
      expect(stats.avgScore, 68);
      expect(stats.medianMinutes, 5);
      expect(stats.isEmpty, isFalse);
    });

    test('the distribution is ten bands the server names itself, summing to the attempts', () {
      expect(stats.distribution, hasLength(10));
      expect(stats.distribution.first.label, '0–9%');
      expect(stats.distribution.last.label, '90–100%');
      expect(stats.distribution.fold<num>(0, (n, b) => n + b.value), stats.attempts);
    });

    test('each question carries its own rate, and the wrong answer most often picked', () {
      final quiz = StaffQuiz.fromJson(_map('staff/quiz.json'));
      expect(stats.questions, hasLength(quiz.questions.length));
      for (final question in quiz.questions) {
        final stat = stats.statFor(question.id);
        expect(stat, isNotNull, reason: question.id);
        expect(stat!.correctRate, greaterThanOrEqualTo(0));
        expect(stat.correctRate, lessThanOrEqualTo(100));
      }
      // A short-answer question has no options, so there is no wrong option to name.
      expect(stats.statFor(quiz.questions.last.id)!.commonWrongOptionId, isNull);
      // A chosen wrong option is always one of the question's own, and never a correct one.
      final wrong = stats.statFor(quiz.questions.first.id)!.commonWrongOptionId;
      expect(quiz.questions.first.options.map((o) => o.id), contains(wrong));
      expect(quiz.questions.first.correct, isNot(contains(wrong)));
    });

    test('a quiz nobody has taken says so rather than showing zeros', () {
      final quiet = QuizStats.fromJson(_map('staff/quiz-stats-quiet.json'));
      expect(quiet.attempts, greaterThan(0), reason: 'this one has been taken');
      expect(const QuizStats().isEmpty, isTrue);
      expect(QuizStats.fromJson(const {'quizId': 'q', 'attempts': 0}).isEmpty, isTrue);
    });

    test('a stat for a question the quiz does not have is absent, not invented', () {
      expect(stats.statFor('not-a-question'), isNull);
    });
  });

  test('an archived quiz reads as archived, badged as such — not as a draft', () {
    final row =
        (_map('staff/quizzes.json')['rows']! as List<dynamic>).first as Map<String, dynamic>;
    final quiz = Map<String, dynamic>.from(row['quiz']! as Map<String, dynamic>)
      ..['status'] = 'archived';

    final archived = StaffQuiz.fromJson(quiz);

    expect(archived.status, StaffQuizStatus.archived);
    expect(quizStatusKind(archived.status), StatusKind.archived);
    expect(quizStatusKind(StaffQuizStatus.published), StatusKind.published);
    expect(quizStatusKind(StaffQuizStatus.draft), StatusKind.draft);
  });
}
