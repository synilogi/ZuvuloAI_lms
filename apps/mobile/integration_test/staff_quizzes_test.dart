import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/core/network/token_store.dart';
import 'package:syniastrolms_mobile/features/staff_quizzes/staff_quizzes.dart';
import 'package:syniastrolms_mobile/shared/domain/quiz.dart';

/// The staff quiz screens against the **real** API on the scratch database. Every figure asserted
/// here is the server's own; nothing is recomputed.
const _password = 'syniastrolms123';
const _admin = 'admin@syniastrolms.test';
const _instructor = 'meenakshi@syniastrolms.test';
const _learner = 'ananya@syniastrolms.test';

class _Token implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppConfig config;
  final clients = <String, ApiClient>{};

  ApiClient clientFor(TokenStore store) => ApiClient(
    config: config,
    tokenStore: store,
    logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
    logRequests: false,
  );

  Future<ApiClient> signIn(String email) async {
    final cached = clients[email];
    if (cached != null) return cached;
    final store = _Token();
    final body = await clientFor(
      _Token(),
    ).post('/auth/login', body: {'email': email, 'password': _password});
    store.token = (body! as Map)['token'] as String;
    return clients[email] = clientFor(store);
  }

  setUpAll(() => config = AppConfig.fromEnvironment(Flavor.dev));

  testWidgets('the list is the academy\'s own quizzes, counted its own way', (tester) async {
    final page = await StaffQuizzesApi(await signIn(_admin)).quizzes();

    expect(page.rows, isNotEmpty);
    expect(page.countOf('all'), page.rows.length);
    expect(page.countOf('draft') + page.countOf('published'), page.countOf('all'));
    for (final row in page.rows) {
      expect(row.quiz.status, isNot(StaffQuizStatus.unknown));
      expect(row.courseTitle, isNotEmpty);
      expect(row.points, row.quiz.totalPoints);
      // A quiz nobody has taken carries no rate at all.
      if (row.attempts == 0) {
        expect(row.passRate, isNull);
        expect(row.avgScore, isNull);
      } else {
        expect(row.passRate, isNotNull);
      }
    }
  });

  testWidgets('a quiz\'s figures are the ones its own stats route sends', (tester) async {
    final api = StaffQuizzesApi(await signIn(_admin));
    final row = (await api.quizzes()).rows.firstWhere((r) => r.attempts > 0);

    final quiz = await api.quiz(row.quiz.id);
    final stats = await api.stats(row.quiz.id);

    expect(stats.quizId, quiz.id);
    expect(stats.attempts, row.attempts);
    expect(stats.passRate, row.passRate);
    expect(stats.avgScore, row.avgScore);
    expect(stats.learners, lessThanOrEqualTo(stats.attempts));
    expect(stats.isEmpty, isFalse);
    // Ten bands that add up to every attempt, labelled by the server.
    expect(stats.distribution, hasLength(10));
    expect(stats.distribution.fold<num>(0, (n, b) => n + b.value), stats.attempts);
    expect(stats.distribution.last.label, '90–100%');
    // One stat per question, each naming a wrong option the question actually has.
    expect(stats.questions, hasLength(quiz.questions.length));
    for (final question in quiz.questions) {
      final stat = stats.statFor(question.id);
      expect(stat, isNotNull, reason: question.id);
      final wrong = stat!.commonWrongOptionId;
      if (wrong != null) {
        expect(question.options.map((o) => o.id), contains(wrong));
        expect(question.correct, isNot(contains(wrong)));
      }
    }
  });

  testWidgets('staff are served the answer key, and the points add up', (tester) async {
    final api = StaffQuizzesApi(await signIn(_admin));
    final quiz = await api.quiz((await api.quizzes()).rows.first.quiz.id);

    expect(quiz.questions, isNotEmpty);
    expect(quiz.totalPoints, quiz.questions.fold<int>(0, (n, q) => n + q.points));
    expect(quiz.settings.passMark, greaterThan(0));
    for (final question in quiz.questions) {
      expect(question.prompt, isNotEmpty);
      expect(question.points, greaterThan(0));
      expect(question.type, isNot(QuestionType.unknown));
      // Every question has an answer the academy marks against, in one form or the other.
      final hasKey = question.correct.isNotEmpty || question.acceptedAnswers.isNotEmpty;
      expect(hasKey, isTrue, reason: question.id);
      for (final id in question.correct) {
        expect(question.options.map((o) => o.id), contains(id));
      }
    }
  });

  testWidgets('an instructor sees only the quizzes of the courses they teach', (tester) async {
    final academy = await StaffQuizzesApi(await signIn(_admin)).quizzes();
    final mine = await StaffQuizzesApi(await signIn(_instructor)).quizzes();

    expect(mine.rows.length, lessThanOrEqualTo(academy.rows.length));
    expect(mine.countOf('all'), mine.rows.length);
    final theirs = academy.rows.map((r) => r.quiz.id).toSet();
    expect(theirs.containsAll(mine.rows.map((r) => r.quiz.id)), isTrue);
  });

  testWidgets('a quiz outside an instructor\'s courses is simply not found', (tester) async {
    final instructor = StaffQuizzesApi(await signIn(_instructor));
    final mine = (await instructor.quizzes()).rows.map((r) => r.quiz.id).toSet();
    final others = (await StaffQuizzesApi(
      await signIn(_admin),
    ).quizzes()).rows.where((r) => !mine.contains(r.quiz.id));

    if (others.isEmpty) {
      // The seed gives this instructor every quiz; there is nothing out of scope to ask for.
      expect(mine, isNotEmpty);
      return;
    }
    await expectLater(
      instructor.quiz(others.first.quiz.id),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
    );
  });

  testWidgets('a learner is refused the quizzes entirely — answer key and all', (tester) async {
    final api = StaffQuizzesApi(await signIn(_learner));

    await expectLater(
      api.quizzes(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          anyOf(isA<ForbiddenFailure>(), isA<PermissionFailure>()),
        ),
      ),
    );
  });
}
