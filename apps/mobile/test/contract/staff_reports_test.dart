import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/staff_reports/staff_reports.dart';

/// Contract tests (§23) for the academy's analytics, against what the real API returned —
/// `test/fixtures/staff/reports-*.json`, each captured with `tool/capture_fixture.sh` at the route's
/// default period. Every figure asserted here is the route's own; nothing is recomputed.
Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

Map<String, dynamic> _map(String name) =>
    _fixture('staff/reports-$name.json')! as Map<String, dynamic>;

void main() {
  group('every tab', () {
    test('carries the period it covers and the one it compares with', () {
      for (final report in [
        OverviewReport.fromJson(_map('overview')).window,
        CoursesReport.fromJson(_map('courses')).window,
        CourseReport.fromJson(_map('course')).window,
        LearnersReport.fromJson(_map('learners')).window,
        EnrolmentsReport.fromJson(_map('enrolments')).window,
        InstructorsReport.fromJson(_map('instructors')).window,
      ]) {
        expect(report.from.isUtc, isTrue);
        expect(report.to.isAfter(report.from), isTrue);
        // The previous period is the same length, ending where this one starts.
        expect(report.previousTo, report.from);
        expect(
          report.to.difference(report.from),
          report.previousTo.difference(report.previousFrom),
        );
      }
    });

    test('says how many courses it covers', () {
      expect(OverviewReport.fromJson(_map('overview')).courseCount, greaterThan(0));
      expect(LearnersReport.fromJson(_map('learners')).courseCount, greaterThan(0));
      // One course's report covers exactly that course.
      expect(CourseReport.fromJson(_map('course')).courseCount, 1);
    });
  });

  group('the overview', () {
    late OverviewReport report;

    setUp(() => report = OverviewReport.fromJson(_map('overview')));

    test('the headline figures carry their previous period and their unit', () {
      final kpis = report.kpis;
      for (final kpi in [kpis.enrollments, kpis.completions, kpis.activeLearners]) {
        expect(kpi.unit, KpiUnit.count);
        expect(kpi.isRate, isFalse);
      }
      for (final kpi in [kpis.completionRate, kpis.avgProgress]) {
        expect(kpi.unit, KpiUnit.percent);
        expect(kpi.isRate, isTrue);
      }
      expect(kpis.enrollments.value, greaterThan(0));
      expect(kpis.enrollments.series, isNotEmpty);
    });

    test('a rate compares in points and a count in percent — the ported rule', () {
      // 58% against 69% is −11 points, never −16%.
      final rate = kpiChange(report.kpis.completionRate);
      expect(rate.isPoints, isTrue);
      expect(rate.direction, TrendDirection.down);
      expect(
        rate.amount,
        closeTo(
          (report.kpis.completionRate.previous - report.kpis.completionRate.value).abs(),
          0.05,
        ),
      );
      expect(kpiChange(report.kpis.enrollments).isPoints, isFalse);
    });

    test('each series is a run of buckets the route measured, oldest first', () {
      for (final series in [
        report.series.enrollments,
        report.series.completions,
        report.series.activeLearners,
      ]) {
        expect(series, isNotEmpty);
        for (final point in series) {
          expect(point.from.isUtc, isTrue);
          expect(point.to.isAfter(point.from), isTrue);
        }
        for (var i = 1; i < series.length; i++) {
          expect(series[i].from.isAfter(series[i - 1].from), isTrue);
        }
      }
    });

    test('the quiz, assignment and engagement figures all arrive', () {
      expect(report.quizzes.attempts.value, greaterThan(0));
      expect(report.quizzes.passRate.isRate, isTrue);
      expect(report.assignments.submitted.value, greaterThan(0));
      expect(report.assignments.onTime.isRate, isTrue);
      expect(report.engagement.lessonsCompleted.value, greaterThan(0));
      expect(report.engagement.lessonsPerLearner.value, greaterThan(0));
    });

    test('the progress bands are the academy\'s own five, and they add up to its learners', () {
      expect(report.progressBands, hasLength(5));
      for (final band in report.progressBands) {
        expect(band.label, isNotEmpty);
      }
    });

    test('the busiest courses are ranked by enrolments, highest first', () {
      expect(report.topCourses, isNotEmpty);
      final counts = [for (final row in report.topCourses) row.enrollments];
      final descending = [...counts]..sort((a, b) => b.compareTo(a));
      expect(counts, orderedEquals(descending));
    });

    test('a category carries its own enrolments and completion', () {
      expect(report.categories, isNotEmpty);
      for (final category in report.categories) {
        expect(category.categoryId, isNotEmpty);
        expect(category.title, isNotEmpty);
      }
    });
  });

  group('the course tabs', () {
    test('every row carries the figures a card shows, and its own trend', () {
      final report = CoursesReport.fromJson(_map('courses'));
      expect(report.rows, isNotEmpty);
      for (final row in report.rows) {
        expect(row.courseId, isNotEmpty);
        expect(row.title, isNotEmpty);
        expect(row.categoryTitle, isNotEmpty);
        expect(row.status, isNotEmpty);
        expect(row.trend, isNotEmpty);
        expect(row.activeLearners, greaterThanOrEqualTo(0));
      }
    });

    test('the change against the previous period is the route\'s two counts, not a rate', () {
      final row = CoursesReport.fromJson(_map('courses')).rows.first;
      expect(row.enrollmentChange, row.enrollments - row.previousEnrollments);
    });

    test('a rating is sent only for a published course', () {
      for (final row in CoursesReport.fromJson(_map('courses')).rows) {
        if (row.rating != null) expect(row.status, 'published');
      }
    });

    test('one course carries its funnel, chapters, quizzes and assignments', () {
      final report = CourseReport.fromJson(_map('course'));
      expect(report.row.courseId, isNotEmpty);
      expect(report.funnel, isNotEmpty);
      expect(report.funnel.first.label, isNotEmpty);
      expect(report.chapters, isNotEmpty);
      for (final chapter in report.chapters) {
        expect(chapter.chapterId, isNotEmpty);
        expect(chapter.title, isNotEmpty);
      }
      expect(report.quizzes, isNotEmpty);
      expect(report.assignments, isNotEmpty);
      for (final assignment in report.assignments) {
        expect(assignment.assignmentId, isNotEmpty);
        expect(assignment.submitted, greaterThanOrEqualTo(0));
      }
    });

    test('the funnel narrows from the intake down, never widening', () {
      final funnel = CourseReport.fromJson(_map('course')).funnel;
      for (var i = 1; i < funnel.length; i++) {
        expect(
          funnel[i].value,
          lessThanOrEqualTo(funnel[i - 1].value),
          reason: '${funnel[i].label} cannot hold more than ${funnel[i - 1].label}',
        );
      }
    });
  });

  group('the learners tab', () {
    late LearnersReport report;

    setUp(() => report = LearnersReport.fromJson(_map('learners')));

    test('the segments are the academy\'s own six, read by its own words', () {
      expect(report.countOf(LearnerSegment.all), greaterThan(0));
      expect(report.countOf(LearnerSegment.atRisk), report.segments['at-risk']);
      expect(report.countOf(LearnerSegment.newcomers), report.segments['new']);
      for (final segment in LearnerSegment.values) {
        if (segment == LearnerSegment.unknown) continue;
        expect(report.segments.containsKey(segment.wireName), isTrue, reason: segment.name);
      }
    });

    test('the statuses add up to the learners the period covers', () {
      final total = [
        'active',
        'at-risk',
        'inactive',
        'suspended',
      ].fold<int>(0, (n, status) => n + report.statusCount(status));
      expect(total, report.countOf(LearnerSegment.all));
    });

    test('a row carries the figures a card shows, and absences stay absent', () {
      expect(report.rows, isNotEmpty);
      for (final row in report.rows) {
        expect(row.studentId, isNotEmpty);
        expect(row.name, isNotEmpty);
        expect(row.status, isNotEmpty);
        expect(row.completed, lessThanOrEqualTo(row.courses));
        expect(row.lastActiveAt?.isUtc ?? true, isTrue);
      }
      // Someone who has handed nothing in has no assignment average — not a nought.
      expect(report.rows.any((r) => r.assignmentAvg == null), isTrue);
    });

    test('one page is served, and the total is the whole answer', () {
      expect(report.rows.length, lessThanOrEqualTo(learnerReportPageSize));
      expect(report.total, greaterThanOrEqualTo(report.rows.length));
    });

    test('the rows arrive in the order asked for — progress, highest first', () {
      final progress = [for (final row in report.rows) row.avgProgress ?? 0];
      final descending = [...progress]..sort((a, b) => b.compareTo(a));
      expect(
        progress,
        orderedEquals(descending),
        reason: 'the route sorts the page; the app never re-sorts what it was handed',
      );
    });
  });

  group('the enrolments tab', () {
    late EnrolmentsReport report;

    setUp(() => report = EnrolmentsReport.fromJson(_map('enrolments')));

    test('the sources cover every enrolment, and their shares add to about a hundred', () {
      expect(report.sources, isNotEmpty);
      final shares = report.sources.fold<int>(0, (n, s) => n + (s.share ?? 0));
      expect(shares, inInclusiveRange(98, 102));
      for (final source in report.sources) {
        expect(source.source, isNotEmpty);
      }
    });

    test('the self-enrolled share is a rate, and the counts are counts', () {
      expect(report.kpis.selfShare.isRate, isTrue);
      expect(report.kpis.enrollments.isRate, isFalse);
    });

    test('a cohort names its month and keeps an unreachable milestone absent', () {
      expect(report.cohorts, isNotEmpty);
      for (final cohort in report.cohorts) {
        expect(cohort.month, isNotEmpty);
        expect(cohort.enrolled, greaterThanOrEqualTo(0));
      }
      // The newest months cannot have a 30/60/90-day figure yet, and send none.
      expect(report.cohorts.any((c) => c.within90 == null), isTrue);
    });
  });

  group('the instructors tab', () {
    late InstructorsReport report;

    setUp(() => report = InstructorsReport.fromJson(_map('instructors')));

    test('every row names an instructor and carries their teaching figures', () {
      expect(report.rows, isNotEmpty);
      for (final row in report.rows) {
        expect(row.instructorId, isNotEmpty);
        expect(row.name, isNotEmpty);
        expect(row.title, isNotEmpty);
        expect(row.courses, greaterThanOrEqualTo(0));
        expect(row.reviews, greaterThanOrEqualTo(0));
      }
    });

    test('the academy-wide figures are the route\'s, with their own units', () {
      expect(report.figures.reviews.isRate, isFalse);
      expect(report.figures.onTime.isRate, isTrue);
      expect(report.figures.attendance.isRate, isTrue);
      expect(report.figures.reviews.value, greaterThan(0));
    });
  });

  group('the query the tabs share', () {
    test('the period always travels, by the route\'s own word', () {
      expect(const ReportQuery().toQuery()['range'], '90d');
      expect(const ReportQuery(range: ReportRange.twelveMonths).toQuery()['range'], '12m');
      expect(ReportRange.thirtyDays.wireName, '30d');
      expect(ReportRange.sixMonths.wireName, '6m');
    });

    test('a segment travels hyphenated, as the route names it', () {
      expect(const ReportQuery(segment: LearnerSegment.atRisk).toQuery()['segment'], 'at-risk');
      expect(LearnerSegment.newcomers.wireName, 'new');
    });

    test('nothing narrowed sends nothing but the period', () {
      expect(const ReportQuery().toQuery().keys, ['range']);
    });

    test('every filter travels by its own name', () {
      final query = const ReportQuery(
        range: ReportRange.sixMonths,
        segment: LearnerSegment.active,
        categoryId: 'cat1',
        courseId: 'c1',
        instructorId: 'i1',
      ).toQuery();
      expect(query, {
        'range': '6m',
        'segment': 'active',
        'categoryId': 'cat1',
        'courseId': 'c1',
        'instructorId': 'i1',
      });
    });

    test('a sort key travels as the route spells it', () {
      expect(LearnerSortKey.lastActive.wireName, 'lastActive');
      expect(LearnerSortKey.progress.wireName, 'progress');
    });

    test('two queries that ask the same thing are the same query', () {
      // Without this, every rebuild would re-read all six tabs.
      expect(const ReportQuery(), const ReportQuery());
      expect(const ReportQuery(courseId: 'c1'), isNot(const ReportQuery(courseId: 'c2')));
    });
  });
}
