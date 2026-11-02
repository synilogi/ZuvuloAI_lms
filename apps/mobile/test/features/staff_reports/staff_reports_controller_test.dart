import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_reports/staff_reports.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

UserProfile _admin() => UserProfile(
  id: 'u_admin',
  name: 'Kavita Menon',
  email: 'admin@example.test',
  role: UserRole.admin,
  descriptor: 'Academy admin',
  permissions: PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

void main() {
  late FakeAdapter adapter;

  setUp(() {
    adapter = FakeAdapter();
    adapter.handler = (options) async {
      final path = options.path;
      if (path.startsWith('/reports/courses/')) {
        return FakeAdapter.jsonResponse(fixture('staff/reports-course.json'));
      }
      for (final name in ['overview', 'courses', 'learners', 'enrolments', 'instructors']) {
        if (path == '/reports/$name') {
          return FakeAdapter.jsonResponse(fixture('staff/reports-$name.json'));
        }
      }
      return FakeAdapter.jsonResponse(fixture('staff/courses.json'));
    };
  });

  ProviderContainer container() {
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: publicScope(
        adapter: adapter,
        signedInAs: _admin(),
        child: const SizedBox.shrink(),
      ).overrides,
    );
    addTearDown(container.dispose);
    return container;
  }

  group('the shared filters', () {
    test('every tab opens on the academy\'s default period', () async {
      final c = container();
      c.listen(overviewReportProvider, (_, _) {});

      await c.read(overviewReportProvider.future);

      expect(c.read(reportFilterProvider).range, ReportRange.ninetyDays);
      expect(adapter.lastRequest.queryParameters, {'range': '90d'});
      expect(narrowedBy(c.read(reportFilterProvider)), 0);
    });

    test('a period reaches every tab, because they share one filter', () async {
      final c = container();
      c.listen(overviewReportProvider, (_, _) {});
      c.listen(coursesReportProvider, (_, _) {});
      c.read(reportFilterProvider.notifier).overPeriod(ReportRange.twelveMonths);

      await c.read(overviewReportProvider.future);
      await c.read(coursesReportProvider.future);

      // Listening starts each tab at the default, so the period asked for is the *last* one each
      // tab read — and both read the same one.
      String lastRangeOf(String path) =>
          adapter.requests.where((r) => r.path == path).last.queryParameters['range']! as String;
      expect(lastRangeOf('/reports/overview'), '12m');
      expect(lastRangeOf('/reports/courses'), '12m');
    });

    test('a course narrows every tab, and clearing puts them back', () async {
      final c = container();
      c.listen(overviewReportProvider, (_, _) {});
      c.read(reportFilterProvider.notifier).inCourse('c1');
      await c.read(overviewReportProvider.future);
      expect(adapter.lastRequest.queryParameters['courseId'], 'c1');
      expect(narrowedBy(c.read(reportFilterProvider)), 1);

      c.read(reportFilterProvider.notifier).clear();
      await c.read(overviewReportProvider.future);

      expect(adapter.lastRequest.queryParameters.containsKey('courseId'), isFalse);
      expect(narrowedBy(c.read(reportFilterProvider)), 0);
    });

    test('"all learners" is no segment at all, not a segment named all', () async {
      final c = container();
      c.listen(learnersReportProvider, (_, _) {});
      c.read(reportFilterProvider.notifier).forSegment(LearnerSegment.atRisk);
      await c.read(learnersReportProvider.future);
      expect(adapter.lastRequest.queryParameters['segment'], 'at-risk');

      c.read(reportFilterProvider.notifier).forSegment(LearnerSegment.all);
      await c.read(learnersReportProvider.future);

      expect(adapter.lastRequest.queryParameters.containsKey('segment'), isFalse);
    });

    test('the filters count what is narrowing the reports', () {
      const query = ReportQuery(segment: LearnerSegment.active, courseId: 'c1', instructorId: 'i1');
      expect(narrowedBy(query), 3);
      // The period is always set, so it never counts as a filter.
      expect(narrowedBy(const ReportQuery(range: ReportRange.sixMonths)), 0);
    });
  });

  group('the tabs', () {
    test('each reads its own endpoint', () async {
      final c = container();
      for (final provider in [
        overviewReportProvider,
        coursesReportProvider,
        enrolmentsReportProvider,
        instructorsReportProvider,
      ]) {
        c.listen(provider, (_, _) {});
      }

      expect((await c.read(overviewReportProvider.future)).courseCount, greaterThan(0));
      expect((await c.read(coursesReportProvider.future)).rows, isNotEmpty);
      expect((await c.read(enrolmentsReportProvider.future)).sources, isNotEmpty);
      expect((await c.read(instructorsReportProvider.future)).rows, isNotEmpty);
    });

    test('one course reads its own report', () async {
      final c = container();
      c.listen(courseReportProvider('c1'), (_, _) {});

      final report = await c.read(courseReportProvider('c1').future);

      expect(adapter.lastRequest.path, '/reports/courses/c1');
      expect(report.funnel, isNotEmpty);
    });
  });

  group('the learner table', () {
    test('opens on progress, highest first', () async {
      final c = container();
      c.listen(learnersReportProvider, (_, _) {});

      await c.read(learnersReportProvider.future);

      expect(adapter.lastRequest.queryParameters['sortKey'], 'progress');
      expect(adapter.lastRequest.queryParameters['sortDirection'], 'desc');
      expect(adapter.lastRequest.queryParameters['page'], 1);
    });

    test('asking for the column already shown turns the order around', () async {
      final c = container();
      c.listen(learnersReportProvider, (_, _) {});
      c.read(learnerTableProvider.notifier).sortBy(LearnerSortKey.progress);
      await c.read(learnersReportProvider.future);

      expect(adapter.lastRequest.queryParameters['sortDirection'], 'asc');

      c.read(learnerTableProvider.notifier).sortBy(LearnerSortKey.progress);
      await c.read(learnersReportProvider.future);

      expect(adapter.lastRequest.queryParameters['sortDirection'], 'desc');
    });

    test('a name starts A–Z, and a figure starts highest first', () async {
      final c = container();
      c.listen(learnersReportProvider, (_, _) {});

      c.read(learnerTableProvider.notifier).sortBy(LearnerSortKey.name);
      await c.read(learnersReportProvider.future);
      expect(adapter.lastRequest.queryParameters['sortDirection'], 'asc');

      c.read(learnerTableProvider.notifier).sortBy(LearnerSortKey.assignments);
      await c.read(learnersReportProvider.future);
      expect(adapter.lastRequest.queryParameters['sortDirection'], 'desc');
    });

    test('a new search or order starts again at the first page', () async {
      final c = container();
      c.listen(learnersReportProvider, (_, _) {});
      c.read(learnerTableProvider.notifier).showPage(3);
      await c.read(learnersReportProvider.future);
      expect(adapter.lastRequest.queryParameters['page'], 3);

      c.read(learnerTableProvider.notifier).searchFor('ananya');
      await c.read(learnersReportProvider.future);

      expect(adapter.lastRequest.queryParameters['page'], 1);
      expect(adapter.lastRequest.queryParameters['search'], 'ananya');
    });

    test('an empty search is cleared rather than sent blank', () async {
      final c = container();
      c.listen(learnersReportProvider, (_, _) {});
      c.read(learnerTableProvider.notifier)
        ..searchFor('ananya')
        ..searchFor('   ');

      await c.read(learnersReportProvider.future);

      expect(adapter.lastRequest.queryParameters.containsKey('search'), isFalse);
    });

    test('sorting the table does not re-read the other tabs', () async {
      final c = container();
      c.listen(learnersReportProvider, (_, _) {});
      c.listen(overviewReportProvider, (_, _) {});
      await c.read(overviewReportProvider.future);
      final overviewReads = adapter.requests.where((r) => r.path == '/reports/overview').length;

      c.read(learnerTableProvider.notifier).sortBy(LearnerSortKey.name);
      await c.read(learnersReportProvider.future);

      expect(
        adapter.requests.where((r) => r.path == '/reports/overview').length,
        overviewReads,
        reason: 'the table\'s ordering is its own, not the section\'s',
      );
    });
  });
}
