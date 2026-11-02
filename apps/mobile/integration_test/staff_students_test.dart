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
import 'package:syniastrolms_mobile/features/notifications/notifications.dart';
import 'package:syniastrolms_mobile/features/staff_courses/staff_courses.dart';
import 'package:syniastrolms_mobile/features/staff_students/staff_students.dart';
import 'package:syniastrolms_mobile/shared/domain/activity.dart';

/// The staff learner screens against the **real** API on the scratch database. Every status and
/// figure asserted here is the academy's own.
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

  testWidgets('the roster is the academy\'s own, counted its own way', (tester) async {
    final page = await StaffStudentsApi(await signIn(_admin)).students();

    expect(page.rows, isNotEmpty);
    expect(page.total, greaterThanOrEqualTo(page.rows.length));
    expect(
      page.countOf('active') +
          page.countOf('at-risk') +
          page.countOf('inactive') +
          page.countOf('suspended'),
      page.countOf('all'),
      reason: 'every learner has exactly one status',
    );
    for (final row in page.rows) {
      expect(row.status, isNot(StudentStatus.unknown));
      expect(row.student.email, isNotEmpty);
      if (row.status == StudentStatus.suspended) expect(row.student.isSuspended, isTrue);
    }
  });

  testWidgets('an instructor is served only the learners on a course they teach', (tester) async {
    final academy = await StaffStudentsApi(await signIn(_admin)).students();
    final mine = await StaffStudentsApi(await signIn(_instructor)).students();

    expect(mine.rows, isNotEmpty);
    expect(mine.countOf('all'), lessThanOrEqualTo(academy.countOf('all')));
    expect(mine.total, lessThanOrEqualTo(academy.total));
  });

  testWidgets('a learner outside an instructor\'s courses is simply not found', (tester) async {
    final instructor = StaffStudentsApi(await signIn(_instructor));
    final mine = (await instructor.students()).rows.map((r) => r.student.id).toSet();
    final others = (await StaffStudentsApi(
      await signIn(_admin),
    ).students(status: 'inactive')).rows.where((r) => !mine.contains(r.student.id));

    if (others.isEmpty) {
      expect(mine, isNotEmpty);
      return;
    }
    await expectLater(
      instructor.student(others.first.student.id),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
    );
  });

  testWidgets('a learner\'s profile, progress and activity agree with one another', (tester) async {
    final api = StaffStudentsApi(await signIn(_admin));
    final row = (await api.students(search: 'ananya')).rows.first;

    final profile = await api.student(row.student.id);
    final progress = await api.progress(row.student.id);
    final activity = await api.activity(row.student.id);

    expect(profile.student.id, row.student.id);
    expect(profile.status, row.status);
    expect(profile.summary.enrolled, profile.enrollments.length);
    expect(profile.rank.title, isNotEmpty);
    // The progress tab covers the same courses the profile lists.
    expect(
      progress.courses.map((c) => c.courseId).toSet(),
      profile.enrollments.map((e) => e.enrollment.courseId).toSet(),
    );
    // Every enrolment shows up in the activity as the day they joined it.
    final enrolled = activity.events.where((e) => e.kind == ActivityKind.enrolled);
    expect(enrolled.length, profile.enrollments.length);
    expect(activity.countOf('all'), activity.total);
  });

  testWidgets('the activity can be narrowed to one kind, and the counts stay the academy\'s', (
    tester,
  ) async {
    final api = StaffStudentsApi(await signIn(_admin));
    final id = (await api.students(search: 'ananya')).rows.first.student.id;

    final all = await api.activity(id);
    final lessons = await api.activity(id, kind: 'lesson-completed');

    expect(lessons.events.every((e) => e.kind == ActivityKind.lessonCompleted), isTrue);
    expect(lessons.total, all.countOf('lesson-completed'));
    // The counts describe everything, whatever the filter is.
    expect(lessons.countOf('all'), all.countOf('all'));
  });

  testWidgets('enrolling a learner puts the course on their profile and in their own app', (
    tester,
  ) async {
    final staff = await signIn(_admin);
    final api = StaffStudentsApi(staff);
    final id = (await api.students(search: 'ananya')).rows.first.student.id;
    final before = await api.student(id);
    final on = before.enrollments.map((e) => e.enrollment.courseId).toSet();
    final course = (await StaffCoursesApi(
      staff,
    ).courses(status: 'published')).rows.firstWhere((c) => !on.contains(c.id));

    final enrollment = await api.enroll(id, courseId: course.id);
    try {
      expect(enrollment.courseId, course.id);
      expect(enrollment.source, EnrollmentSource.admin);
      expect(enrollment.status, EnrollmentStatus.active);

      // It is on their profile, and the academy counts it.
      final after = await api.student(id);
      expect(after.summary.enrolled, before.summary.enrolled + 1);
      expect(after.enrollments.map((e) => e.enrollment.courseId), contains(course.id));

      // Pausing and resuming both go through, and the profile follows.
      final paused = await api.setEnrollmentStatus(enrollment.id, paused: true);
      expect(paused.status, EnrollmentStatus.paused);
      expect(
        (await api.student(
          id,
        )).enrollments.firstWhere((e) => e.enrollment.id == enrollment.id).enrollment.status,
        EnrollmentStatus.paused,
      );
      expect(
        (await api.setEnrollmentStatus(enrollment.id, paused: false)).status,
        EnrollmentStatus.active,
      );
    } finally {
      // The learner is left exactly as they were found.
      await api.removeEnrollment(enrollment.id);
    }

    final restored = await api.student(id);
    expect(restored.summary.enrolled, before.summary.enrolled);
    expect(restored.enrollments.map((e) => e.enrollment.courseId), isNot(contains(course.id)));
  });

  testWidgets('a message reaches the learners it names, and they can read it', (tester) async {
    final api = StaffStudentsApi(await signIn(_admin));
    final id = (await api.students(search: 'ananya')).rows.first.student.id;
    final learner = NotificationsApi(await signIn(_learner));
    final before = (await learner.list()).unread;

    final sent = await api.message(
      studentIds: [id],
      subject: 'A note from your academy',
      body: 'The live class moves to Thursday this week. Bring your geometry box along.',
      channels: const {'app'},
    );

    expect(sent, 1);
    final after = await learner.list();
    expect(after.unread, greaterThan(before));
    expect(
      after.rows.first.title,
      'A note from your academy',
      reason: 'the newest notice is the one just sent',
    );
  });

  testWidgets('a learner out of scope is dropped from a message without a word', (tester) async {
    final api = StaffStudentsApi(await signIn(_admin));
    final id = (await api.students(search: 'ananya')).rows.first.student.id;

    final sent = await api.message(
      studentIds: [id, 'not-a-learner-at-all'],
      subject: 'A note from your academy',
      body: 'The live class moves to Thursday this week. Bring your geometry box along.',
      channels: const {'app'},
    );

    expect(sent, 1, reason: 'the route reports who it reached, not who was asked for');
  });

  testWidgets('suspending a learner stops them, and restoring gives them back', (tester) async {
    final api = StaffStudentsApi(await signIn(_admin));
    // Not the seeded learner other suites sign in as: suspension would stop them mid-run.
    final row = (await api.students(
      status: 'inactive',
    )).rows.firstWhere((r) => !r.student.email.startsWith('ananya'));

    final suspended = await api.setSuspended(
      row.student.id,
      suspended: true,
      reason: 'A test of the academy\'s own suspension.',
    );
    try {
      expect(suspended.isSuspended, isTrue);
      final profile = await api.student(row.student.id);
      expect(profile.status, StudentStatus.suspended);
      expect(
        (await api.students(status: 'suspended')).rows.map((r) => r.student.id),
        contains(row.student.id),
      );
    } finally {
      final restored = await api.setSuspended(row.student.id, suspended: false);
      expect(restored.isSuspended, isFalse);
    }

    expect((await api.student(row.student.id)).status, isNot(StudentStatus.suspended));
  });

  testWidgets('an instructor may not suspend anyone — that is an admin\'s decision', (
    tester,
  ) async {
    final api = StaffStudentsApi(await signIn(_instructor));
    final id = (await api.students()).rows.first.student.id;

    await expectLater(
      api.setSuspended(id, suspended: true),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          anyOf(isA<ForbiddenFailure>(), isA<PermissionFailure>()),
        ),
      ),
    );
  });

  testWidgets('a learner has no roster to read', (tester) async {
    await expectLater(
      StaffStudentsApi(await signIn(_learner)).students(),
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
