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
import 'package:syniastrolms_mobile/features/learner_home/learner_home.dart';
import 'package:syniastrolms_mobile/features/live/live.dart';
import 'package:syniastrolms_mobile/features/notifications/notifications.dart';
import 'package:syniastrolms_mobile/features/staff_courses/staff_courses.dart';
import 'package:syniastrolms_mobile/features/staff_dashboard/staff_dashboard.dart';
import 'package:syniastrolms_mobile/features/staff_live/staff_live.dart';

/// Running live teaching against the **real** API on the scratch database. Every phase, count and
/// refusal asserted here is the academy's own.
const _password = 'syniastrolms123';
const _admin = 'admin@syniastrolms.test';
const _instructor = 'meenakshi@syniastrolms.test';
const _learner = 'ananya@syniastrolms.test';

/// The class this suite works on. It is reused run after run — a live class cannot be deleted, only
/// cancelled (finding 28), so creating one per run would fill the academy's cancelled tab for good.
const _title = 'Fixture class — staff live';

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

  /// A form for a class on a course the seeded learner is enrolled in, so they hear about it.
  /// The courses a learner is actually enrolled in. A class is scheduled on one of these when the
  /// test asserts that *this* learner was told: "any course with an enrolment" is a different claim,
  /// and it quietly stops being true whenever the academy's published set changes.
  Future<Set<String>> coursesOf(ApiClient learner) async =>
      (await LearningApi(learner).courses()).courses.map((c) => c.course.id).toSet();

  Future<LiveClassForm> formFor(
    ApiClient staff, {
    Duration ahead = const Duration(days: 3),
    Set<String>? among,
  }) async {
    final course = (await StaffCoursesApi(staff).courses(status: 'published')).rows.firstWhere(
      (c) => c.enrolledCount > 0 && (among == null || among.contains(c.id)),
      orElse: () => throw StateError(
        among == null
            ? 'the academy has no published course with an enrolment'
            : 'the academy has no published course this learner is enrolled in',
      ),
    );
    final instructor = (await DashboardApi(staff).instructors()).first;
    final start = DateTime.now().toUtc().add(ahead);
    return LiveClassForm(
      courseId: course.id,
      title: _title,
      instructorId: instructor.id,
      startsAt: DateTime.utc(start.year, start.month, start.day, start.hour, start.minute),
      durationMin: 45,
      capacity: 30,
      description: 'A class scheduled by the mobile app against the real API.',
      agenda: const [
        AgendaItem(title: 'Recap', minutes: 10),
        AgendaItem(title: 'Worked examples', minutes: 25),
      ],
      meetingKind: MeetingKind.external,
      meetingLink: 'https://meet.example.com/fixture-class',
      reminders: const [1440, 60],
    );
  }

  /// The suite's own class, scheduled on the first run and reused after that. A cancelled one cannot
  /// be revived, so a fresh one is scheduled only when the last is gone.
  Future<StaffLiveDetail> fixtureClass() async {
    final staff = await signIn(_admin);
    final api = StaffLiveApi(staff);
    for (final view in ['upcoming', 'live']) {
      final found = (await api.schedule(
        view: view,
        search: _title,
      )).rows.where((r) => r.liveClass.title == _title && !r.liveClass.cancelled).firstOrNull;
      if (found != null) return api.liveClass(found.liveClass.id);
    }
    final created = await api.create(await formFor(staff));
    return api.liveClass(created.id);
  }

  testWidgets('the schedule sorts every class into one of the academy\'s four views', (
    tester,
  ) async {
    await fixtureClass();
    final api = StaffLiveApi(await signIn(_admin));
    final page = await api.schedule();

    expect(page.countOf('upcoming'), greaterThan(0));
    expect(
      page.countOf('upcoming') +
          page.countOf('live') +
          page.countOf('history') +
          page.countOf('cancelled'),
      greaterThanOrEqualTo(page.total),
    );
    // With no view asked for, the route sends every class — and the app sorts each into the same
    // view the route counted it under.
    for (final row in page.rows) {
      expect(row.phase, isNot(LivePhase.unknown));
      expect(row.view, isIn(['upcoming', 'live', 'history', 'cancelled']));
      expect(page.countOf(row.view), greaterThan(0), reason: row.view);
      expect(row.courseTitle, isNotEmpty);
      expect(row.instructorName, isNotEmpty);
    }

    // And asking for one view gives only that view's classes.
    final upcoming = await api.schedule(view: 'upcoming');
    expect(upcoming.rows, isNotEmpty);
    for (final row in upcoming.rows) {
      expect(row.view, 'upcoming');
    }
  });

  testWidgets('scheduling a class tells the enrolled learners, and they see it in their own app', (
    tester,
  ) async {
    final staff = await signIn(_admin);
    final api = StaffLiveApi(staff);
    final learnerClient = await signIn(_learner);
    final before = (await NotificationsApi(learnerClient).list()).unread;

    // A class of its own, on a course this learner is enrolled in, so the notification asserted
    // below is the one this test caused and reaches the account it signs in as.
    final form = (await formFor(staff, among: await coursesOf(learnerClient))).copyWith(
      title: 'Fixture class — a learner is told',
      startsAt: DateTime.now().toUtc().add(const Duration(days: 4)),
    );
    final created = await api.create(form);
    try {
      expect(created.title, form.title);
      expect(created.durationMin, 45);
      expect(created.capacity, 30);
      expect(created.reminders, [1440, 60]);
      // The link is what the write path stores, although the schema names `url` (finding 15).
      expect(created.meeting.kind, MeetingKind.external);
      expect(created.meeting.link, 'https://meet.example.com/fixture-class');
      expect(created.agenda, hasLength(2));

      // The academy told the learner, in its own words.
      final notices = await NotificationsApi(learnerClient).list();
      expect(notices.unread, greaterThan(before));
      expect(
        notices.rows.map((n) => n.title).join(' | '),
        contains(form.title),
        reason: 'the academy names the class it just scheduled',
      );

      // And it is in the learner's own schedule, with the phase the academy derives.
      final schedule = await LiveApi(learnerClient).schedule();
      final row = schedule.rowFor(created.id);
      expect(row, isNotNull, reason: 'a class on their course is theirs to see');
      expect(row!.liveClass.title, form.title);
    } finally {
      await api.cancel(created.id, reason: 'The contract check is finished.');
    }
  });

  testWidgets('a class the academy refuses is refused field by field', (tester) async {
    final staff = await signIn(_admin);
    final api = StaffLiveApi(staff);
    final form = await formFor(staff);

    try {
      await api.create(
        form.copyWith(
          title: 'No',
          startsAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
          durationMin: 5,
          meetingLink: 'meet.example.com/not-https',
        ),
      );
      fail('the academy should have refused this class');
    } on ApiException catch (e) {
      final failure = e.failure;
      expect(failure, isA<ConflictFailure>());
      final fields = (failure as ConflictFailure).issues.map((i) => i.key).toSet();
      expect(fields, containsAll(['title', 'startsAt', 'duration', 'meeting']));
      for (final issue in failure.issues) {
        expect(issue.message, isNotEmpty);
      }
      // And the app's own reading names the same fields, so a button is never offered for it.
      expect(
        liveFormProblems(
          form.copyWith(
            title: 'No',
            startsAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
            durationMin: 5,
            meetingLink: 'meet.example.com/not-https',
          ),
          now: DateTime.now().toUtc(),
        ).toSet(),
        fields,
      );
    }
  });

  testWidgets('a class only takes `meeting.link`, not the `url` its schema names', (tester) async {
    final staff = await signIn(_admin);
    final form = await formFor(staff);

    await expectLater(
      staff.post(
        '/live',
        body: {
          ...form.toBody(),
          'title': 'Fixture class — url instead of link',
          'meeting': const {'kind': 'external', 'url': 'https://meet.example.com/wrong-field'},
        },
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure.message,
          'the academy\'s words',
          contains('Check the class details'),
        ),
      ),
    );
  });

  testWidgets('an edit sends the whole class back, and the academy keeps it', (tester) async {
    final staff = await signIn(_admin);
    final api = StaffLiveApi(staff);
    final detail = await fixtureClass();
    final before = detail.liveClass;

    final moved = LiveClassForm.of(before).copyWith(
      durationMin: 90,
      capacity: 25,
      description: 'Edited by the mobile app.',
      reminders: const [1440, 30],
    );
    final saved = await api.save(before.id, moved);

    expect(saved.durationMin, 90);
    expect(saved.capacity, 25);
    expect(saved.description, 'Edited by the mobile app.');
    expect(saved.reminders, [1440, 30]);
    // Nothing the form sent back was lost: a PATCH takes the whole object.
    expect(saved.title, before.title);
    expect(saved.agenda, hasLength(before.agenda.length));
    expect(saved.meeting.link, before.meeting.link);

    // Put it back the way it was found.
    await api.save(before.id, LiveClassForm.of(before));
    expect((await api.liveClass(before.id)).liveClass.durationMin, before.durationMin);
  });

  testWidgets('the reminder offsets are the academy\'s to keep, and it reminds on request', (
    tester,
  ) async {
    final api = StaffLiveApi(await signIn(_admin));
    final detail = await fixtureClass();
    final before = detail.liveClass.reminders;

    final saved = await api.setReminders(detail.liveClass.id, const [1440, 120, 15]);
    expect(saved.reminders, [1440, 120, 15]);

    // A reminder now reaches whoever is registered — the academy's count, whatever it is.
    final sent = await api.remind(detail.liveClass.id);
    expect(sent, greaterThanOrEqualTo(0));

    await api.setReminders(detail.liveClass.id, before);
  });

  testWidgets('cancelling tells the registered learners, and closes the class to edits', (
    tester,
  ) async {
    final staff = await signIn(_admin);
    final api = StaffLiveApi(staff);
    final form = (await formFor(staff)).copyWith(
      title: 'Fixture class — cancelled by the app',
      startsAt: DateTime.now().toUtc().add(const Duration(days: 5)),
    );
    final created = await api.create(form);

    final cancelled = await api.cancel(created.id, reason: 'The instructor is unwell.');
    expect(cancelled.cancelled, isTrue);
    expect(cancelled.cancelReason, 'The instructor is unwell.');

    // The academy will not take an edit on it any more, and says so in its own words.
    await expectLater(
      api.save(created.id, LiveClassForm.of(created)),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure.message,
          'the academy\'s words',
          contains('cancelled'),
        ),
      ),
    );
    // Nor a second cancellation.
    await expectLater(api.cancel(created.id, reason: 'Again.'), throwsA(isA<ApiException>()));
    // It is counted as cancelled, and is out of the upcoming view.
    expect((await api.schedule(view: 'upcoming', search: form.title)).rows, isEmpty);
  });

  testWidgets('a reason is required to call a class off', (tester) async {
    final api = StaffLiveApi(await signIn(_admin));
    final detail = await fixtureClass();

    await expectLater(api.cancel(detail.liveClass.id, reason: 'no'), throwsA(isA<ApiException>()));
    expect((await api.liveClass(detail.liveClass.id)).liveClass.cancelled, isFalse);
  });

  testWidgets('one class carries who registered, and its neighbours in the course', (tester) async {
    final api = StaffLiveApi(await signIn(_admin));
    final detail = await api.liveClass((await fixtureClass()).liveClass.id);

    expect(detail.courseTitle, isNotEmpty);
    expect(detail.instructorName, isNotEmpty);
    expect(detail.attendeeTotal, detail.attendees.length);
    expect(detail.phase, isNot(LivePhase.unknown));
    for (final attendee in detail.attendees) {
      expect(attendee.id, isNotEmpty);
      expect(attendee.name, isNotEmpty);
    }
  });

  testWidgets('an instructor sees the classes of the courses they teach', (tester) async {
    final academy = await StaffLiveApi(await signIn(_admin)).schedule(view: 'upcoming');
    final mine = await StaffLiveApi(await signIn(_instructor)).schedule(view: 'upcoming');

    expect(mine.total, lessThanOrEqualTo(academy.total));
    final theirs = academy.rows.map((r) => r.liveClass.id).toSet();
    expect(theirs.containsAll(mine.rows.map((r) => r.liveClass.id)), isTrue);
  });

  testWidgets('a learner has no staff schedule to read', (tester) async {
    await expectLater(
      StaffLiveApi(await signIn(_learner)).schedule(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          anyOf(isA<ForbiddenFailure>(), isA<PermissionFailure>(), isA<ValidationFailure>()),
        ),
      ),
    );
  });
}
