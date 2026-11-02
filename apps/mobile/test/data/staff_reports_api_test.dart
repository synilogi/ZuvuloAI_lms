import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/features/staff_reports/staff_reports.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/public_harness.dart';
import '../helpers/test_config.dart';

Object? _report(String name) => fixture('staff/reports-$name.json');

void main() {
  late FakeAdapter adapter;
  late StaffReportsApi api;

  setUp(() {
    adapter = FakeAdapter();
    api = StaffReportsApi(
      ApiClient(
        config: testConfig(),
        tokenStore: FakeTokenStore('jwt'),
        logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
        adapter: adapter,
        logRequests: false,
      ),
    );
  });

  test('every tab reads its own path and always names the period', () async {
    adapter
      ..enqueueJson(_report('overview'))
      ..enqueueJson(_report('courses'))
      ..enqueueJson(_report('learners'))
      ..enqueueJson(_report('enrolments'))
      ..enqueueJson(_report('instructors'));

    await api.overview(const ReportQuery());
    expect(adapter.lastRequest.path, '/reports/overview');
    expect(adapter.lastRequest.queryParameters['range'], '90d');

    await api.courses(const ReportQuery());
    expect(adapter.lastRequest.path, '/reports/courses');

    await api.learners(const ReportQuery());
    expect(adapter.lastRequest.path, '/reports/learners');

    await api.enrolments(const ReportQuery());
    expect(adapter.lastRequest.path, '/reports/enrolments');

    await api.instructors(const ReportQuery());
    expect(adapter.lastRequest.path, '/reports/instructors');
  });

  test('the period travels as the route\'s own word', () async {
    for (final (range, word) in [
      (ReportRange.thirtyDays, '30d'),
      (ReportRange.ninetyDays, '90d'),
      (ReportRange.sixMonths, '6m'),
      (ReportRange.twelveMonths, '12m'),
    ]) {
      adapter.enqueueJson(_report('overview'));
      await api.overview(ReportQuery(range: range));
      expect(adapter.lastRequest.queryParameters['range'], word);
    }
  });

  test('every filter travels by the name the route parses', () async {
    adapter.enqueueJson(_report('overview'));

    await api.overview(
      const ReportQuery(
        range: ReportRange.sixMonths,
        segment: LearnerSegment.atRisk,
        categoryId: 'cat1',
        courseId: 'c1',
        instructorId: 'i1',
      ),
    );

    expect(adapter.lastRequest.queryParameters, {
      'range': '6m',
      'segment': 'at-risk',
      'categoryId': 'cat1',
      'courseId': 'c1',
      'instructorId': 'i1',
    });
  });

  test('nothing narrowed sends nothing but the period', () async {
    adapter.enqueueJson(_report('overview'));

    await api.overview(const ReportQuery());

    expect(adapter.lastRequest.queryParameters, {'range': '90d'});
  });

  test('a course id is escaped into the path', () async {
    adapter.enqueueJson(_report('course'));

    await api.course('abc def', const ReportQuery());

    expect(adapter.lastRequest.path, '/reports/courses/abc%20def');
  });

  test('the learner table sends sortKey and sortDirection as two flat strings', () async {
    adapter.enqueueJson(_report('learners'));

    await api.learners(
      const ReportQuery(),
      search: 'ananya',
      sortKey: LearnerSortKey.lastActive,
      descending: false,
      page: 2,
    );

    final query = adapter.lastRequest.queryParameters;
    // The web once sent these as one object and the route silently ignored it.
    expect(query['sortKey'], 'lastActive');
    expect(query['sortDirection'], 'asc');
    expect(query['sortKey'], isA<String>());
    expect(query.containsKey('sort'), isFalse);
    expect(query['search'], 'ananya');
    expect(query['page'], 2);
    expect(query['pageSize'], StaffReportsApi.pageSize);
  });

  test('the table defaults to the academy\'s own order — progress, highest first', () async {
    adapter.enqueueJson(_report('learners'));

    await api.learners(const ReportQuery());

    expect(adapter.lastRequest.queryParameters['sortKey'], 'progress');
    expect(adapter.lastRequest.queryParameters['sortDirection'], 'desc');
  });

  test('every tab decodes into the model the screens read', () async {
    adapter
      ..enqueueJson(_report('overview'))
      ..enqueueJson(_report('course'))
      ..enqueueJson(_report('learners'))
      ..enqueueJson(_report('enrolments'))
      ..enqueueJson(_report('instructors'));

    expect((await api.overview(const ReportQuery())).topCourses, isNotEmpty);
    expect((await api.course('c1', const ReportQuery())).funnel, isNotEmpty);
    expect((await api.learners(const ReportQuery())).rows, isNotEmpty);
    expect((await api.enrolments(const ReportQuery())).cohorts, isNotEmpty);
    expect((await api.instructors(const ReportQuery())).rows, isNotEmpty);
  });
}
