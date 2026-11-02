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
import 'package:syniastrolms_mobile/features/staff_courses/staff_courses.dart';
import 'package:syniastrolms_mobile/shared/domain/course.dart';

/// The staff catalogue against the **real** API on the scratch database. Every refusal asserted
/// here is the server's own; nothing is recomputed and nothing is stubbed.
const _password = 'syniastrolms123';
const _admin = 'admin@syniastrolms.test';
const _instructor = 'meenakshi@syniastrolms.test';

/// The draft this suite works on. It is created once and reused, so repeated runs neither pile up
/// courses nor disturb the seeded catalogue.
const _draftTitle = 'Fixture draft course';

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

  /// The academy's incomplete draft, created on the first run and reused after that. It is left
  /// exactly as it was found, so the checklist it fails is always the same one.
  Future<Course> incompleteDraft(ApiClient client) async {
    final api = StaffCoursesApi(client);
    final existing = await api.courses(status: 'draft', search: _draftTitle);
    final found = existing.rows.where((c) => c.title == _draftTitle).firstOrNull;
    if (found != null) return found;

    final levels = await client.get('/catalog/levels');
    final categories = await api.categories();
    final created = await client.post(
      '/courses',
      body: {
        'title': _draftTitle,
        'subtitle': '',
        'description': '',
        'levelId': ((levels! as List).first as Map)['id'],
        'categoryId': categories.rows.first.category.id,
        'instructorIds': const <String>[],
        'format': 'self-paced',
        'language': 'en',
        'outcomes': const <String>[],
        'tags': const <String>[],
        'visibility': 'public',
        'liveSessions': 0,
      },
    );
    return Course.fromJson(created! as Map<String, dynamic>);
  }

  testWidgets('an instructor is served only the courses they teach', (tester) async {
    final mine = await StaffCoursesApi(await signIn(_instructor)).courses();
    final all = await StaffCoursesApi(await signIn(_admin)).courses();

    expect(mine.rows, isNotEmpty);
    expect(mine.total, lessThan(all.total), reason: 'one instructor teaches part of the catalogue');
    // The counts are the instructor's own too — the tabs never promise more than they can open.
    expect(mine.countOf('all'), mine.total);
  });

  testWidgets('another instructor\'s course is simply not found', (tester) async {
    final instructor = StaffCoursesApi(await signIn(_instructor));
    final mine = (await instructor.courses()).rows.map((c) => c.id).toSet();
    final all = (await StaffCoursesApi(await signIn(_admin)).courses()).rows;
    final theirs = all.firstWhere((c) => !mine.contains(c.id));

    await expectLater(
      instructor.course(theirs.id),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
    );
  });

  testWidgets('publishing an incomplete draft answers with the academy\'s checklist', (
    tester,
  ) async {
    final client = await signIn(_admin);
    final api = StaffCoursesApi(client);
    final draft = await incompleteDraft(client);

    try {
      await api.publish(draft.id);
      fail('the academy should have refused an empty draft');
    } on ApiException catch (e) {
      final failure = e.failure;
      expect(failure, isA<ConflictFailure>());
      final checklist = publishChecklistOf((failure as ConflictFailure).rawIssues);
      expect(checklist, hasLength(6));
      expect(checklist.where((c) => !c.met), isNotEmpty);
      expect(checklist.map((c) => c.id), contains('lessons'));
      // Every line carries words to show — the app writes none of them itself.
      for (final check in checklist) {
        expect(check.label, isNotEmpty);
      }
    }

    // The refusal left the course where it was.
    expect((await api.course(draft.id)).status, CourseStatus.draft);
  });

  testWidgets('a complete course goes out of the catalogue and back into it, counts and all', (
    tester,
  ) async {
    final api = StaffCoursesApi(await signIn(_admin));
    final before = await api.courses();
    // Not every published course in this academy still meets today's publish checklist (finding
    // 24), and unpublishing one that does not would be a one-way door. The round trip is made with
    // the fullest course, which the academy will take back.
    final live = before.rows
        .where((c) => c.status == CourseStatus.published)
        .reduce((a, b) => a.lessons.length >= b.lessons.length ? a : b);
    expect(live.lessons.length, greaterThanOrEqualTo(5));

    final unpublished = await api.unpublish(live.id);
    try {
      expect(unpublished.status, CourseStatus.draft);
      final middle = await api.courses();
      expect(middle.countOf('published'), before.countOf('published') - 1);
      expect(middle.countOf('draft'), before.countOf('draft') + 1);
      expect(
        (await api.courses(status: 'published')).rows.map((c) => c.id),
        isNot(contains(live.id)),
      );
    } finally {
      final republished = await api.publish(live.id);
      expect(republished.status, CourseStatus.published);
    }

    final after = await api.courses();
    expect(after.countOf('published'), before.countOf('published'));
    expect(after.countOf('draft'), before.countOf('draft'));
  });

  testWidgets('archiving takes a course out of the lists, and restoring brings it back', (
    tester,
  ) async {
    final client = await signIn(_admin);
    final api = StaffCoursesApi(client);
    final draft = await incompleteDraft(client);
    final before = await api.courses();

    final archived = await api.archive(draft.id);
    expect(archived.status, CourseStatus.archived);
    final middle = await api.courses(status: 'draft');
    expect(middle.rows.map((c) => c.id), isNot(contains(draft.id)));
    expect(middle.countOf('archived'), before.countOf('archived') + 1);

    final restored = await api.restore(draft.id);
    expect(restored.status, CourseStatus.draft);
    expect(
      (await api.courses(status: 'draft')).rows.map((c) => c.id),
      contains(draft.id),
      reason: 'a restored course comes back as a draft',
    );
  });

  testWidgets('a course\'s figures and its curriculum are read from its own routes', (
    tester,
  ) async {
    final api = StaffCoursesApi(await signIn(_admin));
    final course = (await api.courses(status: 'published', sort: 'learners')).rows.first;

    final stats = await api.stats(course.id);
    final curriculum = await api.curriculumStats(course.id);
    final lessons = await api.lessons(course.id);

    expect(stats.courseId, course.id);
    expect(stats.weekly, hasLength(12));
    expect(stats.progressBuckets, hasLength(5));
    expect(stats.recent.length, lessThanOrEqualTo(8));
    expect(stats.enrolled, course.enrolledCount);
    expect(curriculum.enrolled, stats.enrolled);
    expect(lessons.rows.map((r) => r.lesson.id), containsAll(course.lessons.map((l) => l.id)));
    // Every chapter the outline holds has a figure of its own.
    for (final chapter in course.chapters) {
      expect(curriculum.chapters[chapter.id], isNotNull, reason: chapter.id);
    }
  });

  testWidgets('one lesson comes back with its chapter and its neighbours', (tester) async {
    final api = StaffCoursesApi(await signIn(_admin));
    final course = (await api.courses(
      status: 'published',
    )).rows.firstWhere((c) => c.lessons.length > 1);
    final lessons = await api.lessons(course.id);

    final first = await api.lesson(course.id, lessons.rows.first.lesson.id);
    final second = await api.lesson(course.id, lessons.rows[1].lesson.id);

    expect(first.previous, isNull, reason: 'nothing comes before the first lesson');
    expect(first.next!.id, lessons.rows[1].lesson.id);
    expect(second.previous!.id, lessons.rows.first.lesson.id);
    expect(second.chapterTitle, isNotEmpty);
    expect(second.chapter, isNotNull);
  });

  testWidgets('a learner has no catalogue to steer', (tester) async {
    final store = _Token();
    final body = await clientFor(
      _Token(),
    ).post('/auth/login', body: {'email': 'ananya@syniastrolms.test', 'password': _password});
    store.token = (body! as Map)['token'] as String;

    await expectLater(
      StaffCoursesApi(clientFor(store)).courses(),
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
