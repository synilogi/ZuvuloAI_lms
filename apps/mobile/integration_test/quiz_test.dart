import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/token_store.dart';
import 'package:syniastrolms_mobile/features/assessments/data/assessments_api.dart';
import 'package:syniastrolms_mobile/features/assessments/data/dto/assessment_row.dart';
import 'package:syniastrolms_mobile/features/assessments/data/dto/quiz_attempt.dart';
import 'package:syniastrolms_mobile/features/course_learning/data/course_learning_api.dart';
import 'package:syniastrolms_mobile/shared/domain/progress.dart';

/// Taking a quiz against the **real** API on the scratch database. The answers below come from
/// `apps/api/prisma/academyDemo.ts` (run by `seed.ts`), not from anything the API sent — the payload carries no key.
const _password = 'syniastrolms123';

/// The seed's own answers for the chapter quiz. Choice answers travel as lists of option ids — see `QuizAnswers` in
/// `packages/domain/src/quiz.ts`; only a short answer is a string.
const _correct = <String, Object>{
  'q1': ['a'],
  'q2': ['false'],
  'q3': '75%',
};
const _wrong = <String, Object>{
  'q1': ['d'],
  'q2': ['true'],
  'q3': 'nobody at all',
};

/// One attempt, the way the app takes it: the server starts a session, and the sheet is handed in
/// with it, numbered above what the server holds.
Future<QuizHandIn> _takeAttempt(
  AssessmentsApi api, {
  required String courseId,
  required String lessonId,
  required Map<String, Object> answers,
}) async {
  final begun = await api.startSession(
    courseId: courseId,
    lessonId: lessonId,
    startKey: 'it-${DateTime.now().microsecondsSinceEpoch}',
  );
  return api.submit(
    courseId: courseId,
    lessonId: lessonId,
    sessionId: begun.session.id,
    answers: answers,
    seq: begun.session.answersSeq + 1,
  );
}

class _Token implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppConfig config;

  ApiClient clientFor(TokenStore store) => ApiClient(
    config: config,
    tokenStore: store,
    logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
    logRequests: false,
  );

  setUpAll(() => config = AppConfig.fromEnvironment(Flavor.dev));

  Future<ApiClient> signIn(String email) async {
    final store = _Token();
    final body = await clientFor(
      _Token(),
    ).post('/auth/login', body: {'email': email, 'password': _password});
    store.token = (body! as Map)['token'] as String;
    return clientFor(store);
  }

  /// The academy makes a learner wait before retaking a quiz and caps how many tries they get,
  /// which would make failing and then passing the same quiz impossible in one run — and would
  /// leave the test unrepeatable. Both are relaxed through the real endpoints and put back.
  Future<void> withRetriesAllowed(String quizId, Future<void> Function() body) async {
    final admin = await signIn('admin@syniastrolms.test');
    final instructor = await signIn('meenakshi@syniastrolms.test');
    final settings = (await admin.get('/settings'))! as Map<String, dynamic>;
    final learning = Map<String, dynamic>.from(
      (settings['settings']! as Map<String, dynamic>)['learning']! as Map<String, dynamic>,
    );
    final quiz = (await instructor.get('/quizzes/$quizId'))! as Map<String, dynamic>;
    final quizSettings = Map<String, dynamic>.from(quiz['settings']! as Map<String, dynamic>);

    await admin.put('/settings/learning', body: {...learning, 'retakeWaitHours': 0});
    await instructor.patch(
      '/quizzes/$quizId',
      body: {
        'settings': {...quizSettings, 'attempts': 0},
      },
    );
    try {
      await body();
    } finally {
      await admin.put('/settings/learning', body: learning);
      await instructor.patch('/quizzes/$quizId', body: {'settings': quizSettings});
    }
  }

  testWidgets('the quiz a lesson delivers arrives without its answer key', (tester) async {
    final client = await signIn('ananya@syniastrolms.test');
    final rows = await AssessmentsApi(client).assessments();
    final row = rows.first;

    final view = await CourseLearningApi(
      client,
    ).lesson(courseId: row.courseId, lessonId: row.lessonId);

    expect(view.quiz, isNotNull);
    expect(view.quiz!.questionCount, greaterThan(0));
    // A timed or windowed quiz sends no questions with the lesson — they come with a session. Any
    // it does send carry no key: every field the route sends for a question is one of these.
    for (final question in view.quiz!.questions) {
      expect(
        question.toJson().keys.toSet().difference({
          'id',
          'type',
          'prompt',
          'options',
          'points',
          'required',
          'negativePoints',
        }),
        isEmpty,
      );
    }
  });

  testWidgets('every row says where the learner stands, and a locked one says why', (tester) async {
    final client = await signIn('karan@syniastrolms.test');

    final rows = await AssessmentsApi(client).assessments();

    expect(rows, isNotEmpty);
    expect(rows.every((r) => r.passMark > 0 && r.questions > 0), isTrue);
    for (final locked in rows.where((r) => r.state == AssessmentState.locked)) {
      expect(locked.lockedReason, isNotEmpty);
      expect(locked.isOpen, isFalse);
    }
  });

  testWidgets('a wrong attempt is not passed, and a correct one is — the server scores both', (
    tester,
  ) async {
    // A learner of their own, so the other tests' seeded state is left alone.
    final client = await signIn('arjun@syniastrolms.test');
    final courses = CourseLearningApi(client);
    final assessments = AssessmentsApi(client);
    final catalog = (await client.get('/catalog/courses'))! as List<dynamic>;
    final courseId =
        catalog.cast<Map<String, dynamic>>().firstWhere(
              (c) => c['slug'] == 'maths-foundations',
            )['id']!
            as String;
    await courses.enroll(courseId);

    // Open the chapter's quiz by finishing the lessons before it, as a learner would.
    final course = await courses.course(courseId);
    final chapter = course.learner.course.chapters.first;
    for (final lesson in chapter.lessons.where((l) => l.type != 'assessment')) {
      if (lesson.type == 'video') {
        await courses.reportPosition(
          courseId: courseId,
          lessonId: lesson.id,
          positionSec: lesson.durationMin * 60,
          fraction: 1,
        );
      } else {
        await courses.complete(courseId: courseId, lessonId: lesson.id);
      }
    }
    final quizLesson = chapter.lessons.firstWhere((l) => l.type == 'assessment');
    final row = (await assessments.assessments()).firstWhere((r) => r.lessonId == quizLesson.id);

    await withRetriesAllowed(row.id, () async {
      final wrong = await _takeAttempt(
        assessments,
        courseId: courseId,
        lessonId: quizLesson.id,
        answers: _wrong,
      );
      expect(wrong.completion, isNull, reason: 'not passed completes nothing');
      expect(wrong.review?.passed, isFalse);

      // The row's own state is deliberately not asserted here: once a learner has passed a quiz,
      // the academy keeps their best result, so a later wrong attempt still reads as passed — and
      // the scratch database keeps what an earlier run left. What this test is about is that the
      // server scored the attempt and counted it.
      final afterWrong = (await assessments.assessments()).firstWhere(
        (r) => r.lessonId == quizLesson.id,
      );
      expect(afterWrong.attemptsUsed, greaterThan(0));

      // The same learner, the same quiz, the seed file's answers this time.
      final handedIn = await _takeAttempt(
        assessments,
        courseId: courseId,
        lessonId: quizLesson.id,
        answers: _correct,
      );
      final passed = handedIn.completion;

      expect(passed, isNotNull, reason: 'the server scored it and passed it');
      expect(passed!.snapshot.stateOf(quizLesson.id), ProgressState.completed);
      // The next chapter opens because the server says so, not because the app unlocked it.
      final nextChapter = course.learner.course.chapters[1];
      expect(passed.snapshot.stateOf(nextChapter.lessons.first.id), isNot(ProgressState.locked));

      final passedRow = (await assessments.assessments()).firstWhere(
        (r) => r.lessonId == quizLesson.id,
      );
      expect(passedRow.state, AssessmentState.passed);
      expect(passedRow.score, greaterThanOrEqualTo(passedRow.passMark));
    });
  });

  testWidgets('a quiz the learner may not take yet is refused by the server', (tester) async {
    final client = await signIn('karan@syniastrolms.test');
    final rows = await AssessmentsApi(client).assessments();
    final locked = rows.where((r) => r.state == AssessmentState.locked).firstOrNull;
    if (locked == null) return;

    await expectLater(
      AssessmentsApi(client).startSession(
        courseId: locked.courseId,
        lessonId: locked.lessonId,
        startKey: 'locked-start',
      ),
      throwsA(anything),
    );
  });
}
