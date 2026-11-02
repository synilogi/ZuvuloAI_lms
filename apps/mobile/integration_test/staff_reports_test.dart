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
import 'package:syniastrolms_mobile/features/staff_reports/staff_reports.dart';

/// The academy's analytics against the **real** API on the scratch database (FLUTTER-026). Every
/// figure asserted here is the route's own arithmetic; the app's only sum is the gap between a figure
/// and its previous period, and even that is checked against the two figures the academy sent.
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

  testWidgets('every tab covers the period it says, at 90 days and at 12 months', (tester) async {
    final api = StaffReportsApi(await signIn(_admin));

    for (final range in [ReportRange.ninetyDays, ReportRange.twelveMonths]) {
      final query = ReportQuery(range: range);
      final overview = await api.overview(query);
      final courses = await api.courses(query);
      final learners = await api.learners(query);
      final enrolments = await api.enrolments(query);

      for (final window in [overview.window, courses.window, learners.window, enrolments.window]) {
        // The previous period is the same length, ending where this one starts.
        expect(window.previousTo, window.from, reason: range.wireName);
        expect(
          window.to.difference(window.from),
          window.previousTo.difference(window.previousFrom),
          reason: range.wireName,
        );
      }
      // Every tab says it covers the same academy.
      expect(courses.courseCount, overview.courseCount, reason: range.wireName);
      expect(learners.courseCount, overview.courseCount, reason: range.wireName);
      expect(enrolments.courseCount, overview.courseCount, reason: range.wireName);
    }
  });

  testWidgets('a longer period covers at least as much as a shorter one', (tester) async {
    final api = StaffReportsApi(await signIn(_admin));

    final ninety = await api.overview(const ReportQuery());
    final year = await api.overview(const ReportQuery(range: ReportRange.twelveMonths));

    expect(year.window.from.isBefore(ninety.window.from), isTrue);
    expect(
      year.kpis.enrollments.value,
      greaterThanOrEqualTo(ninety.kpis.enrollments.value),
      reason: 'a year cannot hold fewer enrolments than the ninety days inside it',
    );
  });

  testWidgets('the overview\'s own figures hold together', (tester) async {
    final overview = await StaffReportsApi(await signIn(_admin)).overview(const ReportQuery());

    expect(overview.kpis.enrollments.value, greaterThan(0));
    expect(overview.kpis.completionRate.unit, KpiUnit.percent);
    expect(overview.kpis.enrollments.unit, KpiUnit.count);
    // A rate moves in points; a count moves in percent. Both come from the academy's two figures.
    expect(kpiChange(overview.kpis.completionRate).isPoints, isTrue);
    expect(kpiChange(overview.kpis.enrollments).isPoints, isFalse);
    expect(overview.progressBands, hasLength(5));
    expect(overview.series.enrollments, isNotEmpty);

    // The busiest courses are ranked by the academy, highest first.
    final counts = [for (final row in overview.topCourses) row.enrollments];
    final descending = [...counts]..sort((a, b) => b.compareTo(a));
    expect(counts, orderedEquals(descending));
  });

  testWidgets('one course\'s report matches its row in the list', (tester) async {
    final api = StaffReportsApi(await signIn(_admin));
    final row = (await api.courses(
      const ReportQuery(),
    )).rows.firstWhere((r) => r.status == 'published');

    final detail = await api.course(row.courseId, const ReportQuery());

    expect(detail.row.courseId, row.courseId);
    expect(detail.row.enrollments, row.enrollments);
    expect(detail.row.completions, row.completions);
    expect(detail.row.completionRate, row.completionRate);
    expect(detail.courseCount, 1);
    // The funnel narrows from the intake down.
    for (var i = 1; i < detail.funnel.length; i++) {
      expect(detail.funnel[i].value, lessThanOrEqualTo(detail.funnel[i - 1].value));
    }
  });

  testWidgets('a course with no report says so, rather than answering with an empty one', (
    tester,
  ) async {
    final staff = await signIn(_admin);
    final draft = (await StaffCoursesApi(staff).courses(status: 'draft')).rows.firstOrNull;
    if (draft == null) return;

    await expectLater(
      StaffReportsApi(staff).course(draft.id, const ReportQuery()),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
    );
  });

  testWidgets('a course filter narrows every tab to that course', (tester) async {
    final api = StaffReportsApi(await signIn(_admin));
    final courseId = (await api.courses(const ReportQuery())).rows.first.courseId;

    final narrowed = await api.courses(ReportQuery(courseId: courseId));

    expect(narrowed.rows, hasLength(1));
    expect(narrowed.rows.single.courseId, courseId);
    expect(narrowed.courseCount, 1);
  });

  testWidgets('the learner table comes back in the order it was asked for', (tester) async {
    final api = StaffReportsApi(await signIn(_admin));

    final byProgress = await api.learners(const ReportQuery());
    final progress = [for (final row in byProgress.rows) row.avgProgress ?? 0];
    final descending = [...progress]..sort((a, b) => b.compareTo(a));
    expect(progress, orderedEquals(descending));

    final byName = await api.learners(
      const ReportQuery(),
      sortKey: LearnerSortKey.name,
      descending: false,
    );
    final names = [for (final row in byName.rows) row.name.toLowerCase()];
    final alphabetical = [...names]..sort();
    expect(names, orderedEquals(alphabetical), reason: 'sortKey and sortDirection round-trip');

    // Turning it around really turns it around. It is the *whole* list the academy reverses, so the
    // first page of it is not the last page of the other one — only the order is comparable.
    final reversed = await api.learners(
      const ReportQuery(),
      sortKey: LearnerSortKey.name,
      descending: true,
    );
    final reversedNames = [for (final row in reversed.rows) row.name.toLowerCase()];
    final reverseAlphabetical = [...reversedNames]..sort((a, b) => b.compareTo(a));
    expect(reversedNames, orderedEquals(reverseAlphabetical));
    expect(
      reversedNames.first.compareTo(names.first),
      greaterThan(0),
      reason: 'the other end of the alphabet',
    );
  });

  testWidgets('the learner table pages, and the total describes the whole answer', (tester) async {
    final api = StaffReportsApi(await signIn(_admin));

    final first = await api.learners(const ReportQuery());
    expect(first.rows.length, lessThanOrEqualTo(learnerReportPageSize));
    expect(first.total, greaterThanOrEqualTo(first.rows.length));

    if (first.total > learnerReportPageSize) {
      final second = await api.learners(const ReportQuery(), page: 2);
      expect(second.total, first.total, reason: 'the total is the answer, not the page');
      expect(
        second.rows
            .map((r) => r.studentId)
            .toSet()
            .intersection(first.rows.map((r) => r.studentId).toSet()),
        isEmpty,
        reason: 'a second page is different learners',
      );
    }
  });

  testWidgets('a search narrows the learner table to who it names', (tester) async {
    final report = await StaffReportsApi(
      await signIn(_admin),
    ).learners(const ReportQuery(), search: 'ananya');

    expect(report.rows, isNotEmpty);
    expect(report.rows.every((r) => r.name.toLowerCase().contains('ananya')), isTrue);
  });

  testWidgets('the learner segments and statuses are the academy\'s own counts', (tester) async {
    final report = await StaffReportsApi(await signIn(_admin)).learners(const ReportQuery());

    expect(report.countOf(LearnerSegment.all), greaterThan(0));
    expect(
      [
        'active',
        'at-risk',
        'inactive',
        'suspended',
      ].fold<int>(0, (n, s) => n + report.statusCount(s)),
      report.countOf(LearnerSegment.all),
    );
    for (final segment in LearnerSegment.values) {
      if (segment == LearnerSegment.unknown) continue;
      expect(report.segments.containsKey(segment.wireName), isTrue, reason: segment.name);
    }
  });

  testWidgets('a segment narrows the learners a tab counts', (tester) async {
    final api = StaffReportsApi(await signIn(_admin));
    final all = await api.learners(const ReportQuery());

    final active = await api.learners(const ReportQuery(segment: LearnerSegment.active));

    expect(active.total, lessThanOrEqualTo(all.total));
    expect(active.total, all.countOf(LearnerSegment.active));
  });

  testWidgets('the enrolments tab accounts for where every enrolment came from', (tester) async {
    final report = await StaffReportsApi(await signIn(_admin)).enrolments(const ReportQuery());

    expect(report.sources, isNotEmpty);
    expect(report.sources.fold<int>(0, (n, s) => n + (s.share ?? 0)), inInclusiveRange(98, 102));
    expect(report.kpis.selfShare.unit, KpiUnit.percent);
    expect(report.cohorts, isNotEmpty);
    // A month too recent for a 90-day figure has none, rather than a nought.
    expect(report.cohorts.any((c) => c.within90 == null), isTrue);
  });

  testWidgets('the instructor report is an admin\'s, and an instructor is refused it', (
    tester,
  ) async {
    final report = await StaffReportsApi(await signIn(_admin)).instructors(const ReportQuery());

    expect(report.rows, isNotEmpty);
    expect(report.figures.onTime.unit, KpiUnit.percent);
    for (final row in report.rows) {
      expect(row.name, isNotEmpty);
      expect(row.courses, greaterThanOrEqualTo(0));
    }

    await expectLater(
      StaffReportsApi(await signIn(_instructor)).instructors(const ReportQuery()),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          anyOf(isA<ForbiddenFailure>(), isA<PermissionFailure>(), isA<EntitlementFailure>()),
        ),
      ),
    );
  });

  testWidgets('an instructor reports on their own courses and no more', (tester) async {
    final staff = await signIn(_instructor);
    final theirs = await StaffReportsApi(staff).courses(const ReportQuery());
    final all = await StaffReportsApi(await signIn(_admin)).courses(const ReportQuery());

    expect(theirs.rows, isNotEmpty);
    expect(
      theirs.rows.length,
      lessThanOrEqualTo(all.rows.length),
      reason: 'the token decides the scope, never the query (§7)',
    );
  });

  testWidgets('a learner has no reports at all', (tester) async {
    await expectLater(
      StaffReportsApi(await signIn(_learner)).overview(const ReportQuery()),
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
