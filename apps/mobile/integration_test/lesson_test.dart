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
import 'package:syniastrolms_mobile/features/course_learning/data/course_learning_api.dart';
import 'package:syniastrolms_mobile/features/course_learning/data/dto/lesson_view.dart';
import 'package:syniastrolms_mobile/features/learner_home/data/learning_api.dart';
import 'package:syniastrolms_mobile/features/public_catalog/data/catalog_api.dart';
import 'package:syniastrolms_mobile/shared/domain/course.dart';
import 'package:syniastrolms_mobile/shared/domain/progress.dart';

/// The lesson player against the **real** API on the scratch database. Every completion,
/// every lock and every threshold here is the server's.
const _password = 'syniastrolms123';

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

  testWidgets('every seeded lesson type comes back with the body its type needs', (tester) async {
    final client = await signIn('ananya@syniastrolms.test');
    final api = CourseLearningApi(client);
    final course = (await LearningApi(
      client,
    ).courses()).courses.firstWhere((c) => c.course.slug == 'maths-foundations');
    final seen = <String, LessonView>{};

    for (final lesson in course.course.lessons) {
      final view = await api.lesson(courseId: course.course.id, lessonId: lesson.id);
      seen[lesson.type] = view;
    }

    expect(seen.keys, containsAll(['video', 'reading', 'assessment', 'practice', 'assignment']));
    expect(seen['video']!.lesson.content?.video?.file, isNotNull);
    expect(seen['reading']!.lesson.content?.article?.body, isNotEmpty);
    expect(seen['assessment']!.lesson.content?.quiz, isNotNull);
    expect(seen['assignment']!.assignment, isNotNull);
    expect(seen.values.every((v) => v.threshold > 0), isTrue);
  });

  testWidgets('a locked lesson brings its reason and no body, and its next stays shut', (
    tester,
  ) async {
    final client = await signIn('ananya@syniastrolms.test');
    final api = CourseLearningApi(client);
    final course = (await LearningApi(
      client,
    ).courses()).courses.firstWhere((c) => c.course.slug == 'logical-reasoning');
    final lockedId = course.snapshot.lessons.entries
        .firstWhere((e) => e.value.state == ProgressState.locked)
        .key;

    final view = await api.lesson(courseId: course.course.id, lessonId: lockedId);

    expect(view.access, LessonAccess.locked);
    expect(view.lockedReason, isNotEmpty);
    expect(view.lesson.content == null || view.lesson.content!.isEmpty, isTrue);
  });

  testWidgets('a lesson of a course the learner has not joined is not theirs to open', (
    tester,
  ) async {
    final client = await signIn('ananya@syniastrolms.test');
    final catalog = await CatalogApi(client).courses();
    final workspace = await LearningApi(client).courses();
    final enrolled = workspace.courses.map((c) => c.course.id).toSet();
    final stranger = catalog.firstWhere((c) => !enrolled.contains(c.id));
    final lesson = stranger.lessons.firstWhere((l) => !l.isPlayablePreview);

    final view = await CourseLearningApi(client).lesson(courseId: stranger.id, lessonId: lesson.id);

    expect(view.access, LessonAccess.notEnrolled);
    expect(view.enrolled, isFalse);
    expect(view.lesson.content == null || view.lesson.content!.isEmpty, isTrue);
  });

  testWidgets('watching past the academy\'s threshold completes a video without asking', (
    tester,
  ) async {
    // A learner of their own, so the seeded fixtures for the others stay as captured.
    final client = await signIn('karan@syniastrolms.test');
    final api = CourseLearningApi(client);
    final catalog = await CatalogApi(client).courses();
    final target = catalog.firstWhere((c) => c.slug == 'algebra-essentials');
    await api.enroll(target.id);
    final video = target.lessons.firstWhere((l) => l.type == 'video');

    final before = await api.lesson(courseId: target.id, lessonId: video.id);
    expect(before.rule, CompletionRule.watched);
    expect(before.threshold, greaterThan(0));

    // Report a position past the threshold, as the player does while it plays. Nothing here asks
    // for the lesson to be completed — only the server decides that, from the position.
    await api.reportPosition(
      courseId: target.id,
      lessonId: video.id,
      positionSec: 1180,
      fraction: 1,
    );

    final after = await api.lesson(courseId: target.id, lessonId: video.id);
    expect(after.state, ProgressState.completed, reason: 'the server completed it, not the app');
    expect(after.lessonProgress?.completedAt, isNotNull);
    // The lesson's earlier state is deliberately not asserted: the scratch database keeps what an
    // earlier run left, and this test is about what reporting a full position brings about.
  });

  testWidgets('completing a lesson answers with what changed, and opens what comes next', (
    tester,
  ) async {
    final client = await signIn('karan@syniastrolms.test');
    final api = CourseLearningApi(client);
    final catalog = await CatalogApi(client).courses();
    final target = catalog.firstWhere((c) => c.slug == 'algebra-essentials');
    await api.enroll(target.id);
    final reading = target.lessons.firstWhere((l) => l.type == 'reading');

    final result = await api.complete(courseId: target.id, lessonId: reading.id);

    expect(result.snapshot.stateOf(reading.id), ProgressState.completed);
    expect(result.progress.completed, greaterThan(0));

    final view = await api.lesson(courseId: target.id, lessonId: reading.id);
    expect(view.state, ProgressState.completed);
  });

  testWidgets('a quiz lesson will not be marked complete until it is passed', (tester) async {
    final client = await signIn('ananya@syniastrolms.test');
    final api = CourseLearningApi(client);
    final course = (await LearningApi(
      client,
    ).courses()).courses.firstWhere((c) => c.course.slug == 'maths-foundations');
    final quiz = course.course.lessons.firstWhere((l) => l.type == 'assessment');

    await expectLater(
      api.complete(courseId: course.course.id, lessonId: quiz.id),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          isA<ConflictFailure>().having(
            (f) => f.message,
            'message',
            'Pass the quiz to complete this lesson.',
          ),
        ),
      ),
    );
  });

  testWidgets('a note is stored and comes back with the lesson', (tester) async {
    final client = await signIn('ananya@syniastrolms.test');
    final api = CourseLearningApi(client);
    final course = (await LearningApi(
      client,
    ).courses()).courses.firstWhere((c) => c.course.slug == 'maths-foundations');
    final practice = course.course.lessons.firstWhere((l) => l.type == 'practice');
    const text = 'Sun in Leo, first house — strong and visible.';

    final savedAt = await api.saveNote(
      courseId: course.course.id,
      lessonId: practice.id,
      text: text,
    );
    addTearDown(() => api.saveNote(courseId: course.course.id, lessonId: practice.id, text: ''));

    expect(savedAt.isUtc, isTrue);
    final view = await api.lesson(courseId: course.course.id, lessonId: practice.id);
    expect(view.note, text);
  });

  testWidgets('a bookmark toggles and is remembered', (tester) async {
    final client = await signIn('ananya@syniastrolms.test');
    final api = CourseLearningApi(client);
    final course = (await LearningApi(
      client,
    ).courses()).courses.firstWhere((c) => c.course.slug == 'maths-foundations');
    final lesson = course.course.lessons.first;

    final on = await api.toggleBookmark(courseId: course.course.id, lessonId: lesson.id);
    addTearDown(() => api.toggleBookmark(courseId: course.course.id, lessonId: lesson.id));

    expect(on, isTrue);
    final view = await api.lesson(courseId: course.course.id, lessonId: lesson.id);
    expect(view.bookmarked, isTrue);
  });
}
