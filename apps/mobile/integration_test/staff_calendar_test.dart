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
import 'package:syniastrolms_mobile/features/staff_calendar/staff_calendar.dart';
import 'package:syniastrolms_mobile/features/staff_courses/staff_courses.dart';
import 'package:syniastrolms_mobile/features/staff_live/staff_live.dart';

/// The staff calendar against the **real** API on the scratch database. Its own events are created
/// and removed by each run, so nothing accumulates: a calendar event, unlike a course or a live
/// class, can be deleted.
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

  /// A wide range around today, so whatever the academy has is in it.
  (DateTime, DateTime) wideRange() {
    final today = istDayOf(DateTime.now().toUtc());
    return (today.subtract(const Duration(days: 45)), today.add(const Duration(days: 45)));
  }

  testWidgets('the range is read in IST days, and every event falls inside it', (tester) async {
    final api = StaffCalendarApi(await signIn(_admin));
    final (from, to) = wideRange();

    final page = await api.range(fromIstDay: from, toIstDay: to);

    expect(page.rows, isNotEmpty);
    expect(page.rows, hasLength(page.total));
    for (final row in page.rows) {
      expect(row.event.type, isNot(CalendarEventType.unknown));
      expect(row.event.timing, isNot(CalendarTiming.unknown));
      expect(row.event.title, isNotEmpty);
      // Every event is filed on an IST day inside the range asked for.
      expect(row.event.istDay.isBefore(from), isFalse, reason: row.event.title);
      expect(row.event.istDay.isAfter(to), isFalse, reason: row.event.title);
    }
    // The counts cover the whole range and add up to it.
    expect(
      CalendarEventType.values
          .where((t) => t != CalendarEventType.unknown)
          .fold<int>(0, (n, t) => n + page.countOf(t)),
      page.total,
    );
  });

  testWidgets('a live class appears as a derived event, with the academy\'s own phase', (
    tester,
  ) async {
    final staff = await signIn(_admin);
    final api = StaffCalendarApi(staff);
    final (from, to) = wideRange();
    final upcoming = (await StaffLiveApi(staff).schedule(view: 'upcoming')).rows.first;

    final page = await api.range(
      fromIstDay: from,
      toIstDay: to,
      types: const [CalendarEventType.live],
    );
    final row = page.rows.where((r) => r.event.source?.id == upcoming.liveClass.id).singleOrNull;

    expect(row, isNotNull, reason: 'a class in the range is on the calendar');
    expect(row!.event.id, 'live-${upcoming.liveClass.id}');
    expect(row.event.isDerived, isTrue);
    expect(row.phase, isNot(LivePhase.unknown));
    expect(row.courseTitle, upcoming.courseTitle);

    // And the calendar's own detail says it is not the calendar's to change.
    final detail = await api.event(row.event.id);
    expect(detail.editable, isFalse);
    expect(detail.event.source!.kind, 'live-class');
    expect(detail.live, isNotNull);
    expect(detail.audienceSize, isNotNull);
  });

  testWidgets('a reminder of one\'s own is added, read, ticked off and removed', (tester) async {
    final api = StaffCalendarApi(await signIn(_admin));
    final start = DateTime.now().toUtc().add(const Duration(days: 2));
    final form = CalendarEventForm(
      title: 'Contract check — a private reminder',
      description: 'Added by the mobile app against the real API.',
      startsAt: DateTime.utc(start.year, start.month, start.day, start.hour),
      durationMin: 30,
      notifyMin: 60,
    );

    final created = await api.create(form);
    try {
      expect(created.type, CalendarEventType.reminder);
      expect(created.title, form.title);
      expect(created.audience, ReminderAudience.me);
      expect(created.notifyMin, 60);
      expect(created.ownerId, isNotEmpty);
      expect(created.done, isFalse);

      // It is on the calendar, on the IST day it falls on.
      final (from, to) = wideRange();
      final page = await api.range(fromIstDay: from, toIstDay: to);
      final row = page.rows.where((r) => r.event.id == created.id).singleOrNull;
      expect(row, isNotNull);
      expect(row!.event.istDay, created.istDay);
      expect(page.on(created.istDay).map((r) => r.event.id), contains(created.id));

      // Its own detail says it is this account's to change.
      final detail = await api.event(created.id);
      expect(detail.editable, isTrue);
      expect(detail.event.description, form.description);

      // Ticking it off, and back again.
      expect((await api.setDone(created.id, done: true)).done, isTrue);
      expect((await api.event(created.id)).event.done, isTrue);
      expect((await api.setDone(created.id, done: false)).done, isFalse);

      // Saving sends the event bare, and the academy keeps the change.
      final saved = await api.save(
        created.id,
        CalendarEventForm.of(created).copyWith(title: 'Contract check — renamed', durationMin: 45),
      );
      expect(saved.title, 'Contract check — renamed');
      expect(saved.durationMin, 45);
    } finally {
      await api.remove(created.id);
    }

    // And it is gone for good — a calendar event, unlike a class, can be deleted.
    await expectLater(
      api.event(created.id),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
    );
  });

  testWidgets('an all-day event belongs to the IST day it reads as', (tester) async {
    final staff = await signIn(_admin);
    final api = StaffCalendarApi(staff);
    final course = (await StaffCoursesApi(staff).courses(status: 'published')).rows.first;
    // Stored late in UTC on purpose: 19:00 UTC is 00:30 IST the next morning, so the IST day the
    // event belongs to is the one after the UTC date it is stored on.
    final day = istDayOf(DateTime.now().toUtc()).add(const Duration(days: 3));
    final lateInUtc = day.add(const Duration(hours: 19));

    final created = await api.create(
      CalendarEventForm(
        type: CalendarEventType.milestone,
        title: 'Contract check — an all-day milestone',
        timing: CalendarTiming.allDay,
        startsAt: lateInUtc,
        courseId: course.id,
        milestone: MilestoneKind.cohortStarts,
      ),
    );
    try {
      expect(created.timing, CalendarTiming.allDay);
      // The instant is late in UTC, so the IST day it belongs to is the following one.
      expect(created.istDay, day.add(const Duration(days: 1)));

      final (from, to) = wideRange();
      final page = await api.range(fromIstDay: from, toIstDay: to);
      expect(
        page.on(created.istDay).map((r) => r.event.id),
        contains(created.id),
        reason: 'the agenda files it under the IST day, not the UTC one',
      );
    } finally {
      await api.remove(created.id);
    }
  });

  testWidgets('the academy refuses an event it will not take, field by field', (tester) async {
    final staff = await signIn(_admin);
    final api = StaffCalendarApi(staff);
    final now = DateTime.now().toUtc();
    final bad = CalendarEventForm(
      type: CalendarEventType.quiz,
      title: 'No',
      timing: CalendarTiming.moment,
      startsAt: now.subtract(const Duration(hours: 1)),
    );

    try {
      await api.create(bad);
      fail('the academy should have refused this event');
    } on ApiException catch (e) {
      final failure = e.failure;
      expect(failure, isA<ConflictFailure>());
      final fields = (failure as ConflictFailure).issues.map((i) => i.key).toSet();
      expect(fields, containsAll(['title', 'course', 'quiz', 'startsAt']));
      for (final issue in failure.issues) {
        expect(issue.message, isNotEmpty);
      }
      // The app's own reading names the same fields, so a button is never offered for it.
      expect(calendarFormProblems(bad, now: now).toSet(), fields);
    }
  });

  testWidgets('a live class is never written through the calendar', (tester) async {
    final api = StaffCalendarApi(await signIn(_admin));

    await expectLater(
      api.create(
        CalendarEventForm(
          type: CalendarEventType.live,
          title: 'Contract check — not here',
          startsAt: DateTime.now().toUtc().add(const Duration(days: 2)),
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => (e.failure as ConflictFailure).issues.map((i) => i.key),
          'the field refused',
          contains('type'),
        ),
      ),
    );
  });

  testWidgets('an instructor sees their own calendar, and not another\'s private reminder', (
    tester,
  ) async {
    final adminApi = StaffCalendarApi(await signIn(_admin));
    final mineApi = StaffCalendarApi(await signIn(_instructor));
    final (from, to) = wideRange();
    final start = DateTime.now().toUtc().add(const Duration(days: 2));

    final privateToAdmin = await adminApi.create(
      CalendarEventForm(
        title: 'Contract check — only the admin sees this',
        startsAt: DateTime.utc(start.year, start.month, start.day, start.hour),
        durationMin: 15,
      ),
    );
    try {
      expect(
        (await adminApi.range(fromIstDay: from, toIstDay: to)).rows.map((r) => r.event.id),
        contains(privateToAdmin.id),
      );
      // A private reminder is the owner's alone (`audience: me`).
      expect(
        (await mineApi.range(fromIstDay: from, toIstDay: to)).rows.map((r) => r.event.id),
        isNot(contains(privateToAdmin.id)),
      );
      await expectLater(
        mineApi.event(privateToAdmin.id),
        throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
      );
    } finally {
      await adminApi.remove(privateToAdmin.id);
    }
  });

  testWidgets('a learner has no calendar of this kind', (tester) async {
    final (from, to) = wideRange();

    await expectLater(
      StaffCalendarApi(await signIn(_learner)).range(fromIstDay: from, toIstDay: to),
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
