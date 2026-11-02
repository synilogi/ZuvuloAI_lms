import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/staff_quizzes/staff_quizzes.dart';

/// What the staff quiz models work out for themselves, at the edges the seeded data never reaches.
/// Every figure a screen shows is the server's; these are only the readings the app does of them.
StaffQuizQuestion question({
  String id = 'q1',
  int points = 10,
  List<String> correct = const ['a'],
  List<String> options = const ['a', 'b', 'c'],
}) => StaffQuizQuestion(
  id: id,
  points: points,
  correct: correct,
  options: [for (final o in options) StaffQuizOption(id: o, text: 'Option $o')],
);

void main() {
  group('a quiz\'s points', () {
    test('are summed from the questions', () {
      final quiz = StaffQuiz(
        id: 'z',
        questions: [
          question(points: 10),
          question(id: 'q2', points: 15),
        ],
      );

      expect(quiz.totalPoints, 25);
    });

    test('are nothing when there are no questions yet', () {
      expect(const StaffQuiz(id: 'z').totalPoints, 0);
    });
  });

  group('the answer marked on a question', () {
    test('is read in the order the options are shown, not the order of the key', () {
      final marked = question(correct: const ['c', 'a']).correctOptions;

      expect(marked.map((o) => o.id), ['a', 'c']);
    });

    test('ignores a key that names an option the question does not have', () {
      expect(question(correct: const ['a', 'zz']).correctOptions.map((o) => o.id), ['a']);
    });

    test('is empty for a short answer, which is marked against accepted text instead', () {
      const short = StaffQuizQuestion(id: 'q3', acceptedAnswers: ['Pushya', 'pushya nakshatra']);

      expect(short.correctOptions, isEmpty);
      expect(short.acceptedAnswers, hasLength(2));
    });
  });

  group('the settings', () {
    test('read zero attempts as as many as they like', () {
      expect(const StaffQuizSettings(attempts: 0).unlimitedAttempts, isTrue);
      expect(const StaffQuizSettings(attempts: 1).unlimitedAttempts, isFalse);
    });

    test('default to the academy\'s own defaults when the route sends none', () {
      final quiz = StaffQuiz.fromJson(const {'id': 'z'});

      expect(quiz.settings.passMark, 70);
      expect(quiz.settings.attempts, 2);
      expect(quiz.settings.shuffleOptions, isTrue);
      expect(quiz.settings.shuffleQuestions, isFalse);
    });
  });

  group('the figures', () {
    test('are empty while nobody has attempted it, whatever else was sent', () {
      const stats = QuizStats(
        attempts: 0,
        distribution: [
          ScoreBand(label: '0–9%'),
          ScoreBand(label: '10–19%'),
        ],
      );

      expect(stats.isEmpty, isTrue, reason: 'bands of zero are not results');
    });

    test('are not empty as soon as there is one attempt', () {
      expect(const QuizStats(attempts: 1).isEmpty, isFalse);
    });

    test('name a question that has one, and nothing for a question that does not', () {
      const stats = QuizStats(
        questions: [
          QuestionStat(questionId: 'q1', correctRate: 40, commonWrongOptionId: 'b'),
          QuestionStat(questionId: 'q2', correctRate: 90),
        ],
      );

      expect(stats.statFor('q1')!.commonWrongOptionId, 'b');
      expect(stats.statFor('q2')!.commonWrongOptionId, isNull);
      expect(stats.statFor('q3'), isNull);
    });

    test('keep the band labels exactly as the server wrote them', () {
      final stats = QuizStats.fromJson(const {
        'attempts': 4,
        'distribution': [
          {'label': '0–9%', 'value': 1},
          {'label': '90–100%', 'value': 3},
        ],
      });

      expect(stats.distribution.map((b) => b.label), ['0–9%', '90–100%']);
      expect(stats.distribution.fold<num>(0, (n, b) => n + b.value), stats.attempts);
    });
  });

  group('the list\'s counts', () {
    test('answer nothing for a status the academy did not send', () {
      const page = StaffQuizPage(counts: {'all': 3, 'published': 3});

      expect(page.countOf('all'), 3);
      expect(page.countOf('draft'), 0);
      expect(page.isEmpty, isTrue, reason: 'counts without rows is still an empty page');
    });
  });
}
