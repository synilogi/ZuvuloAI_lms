import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_reports/staff_reports.dart';
import 'package:syniastrolms_mobile/shared/entitlements/entitlements.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(jsonEncode(fixture('staff/reports-$name.json'))) as Map<String, dynamic>;

/// The fixtures were captured on 30 September 2026.
final _now = DateTime.utc(2026, 9, 30, 12);

UserProfile _admin() => UserProfile(
  id: 'u_admin',
  name: 'Kavita Menon',
  email: 'admin@example.test',
  role: UserRole.admin,
  descriptor: 'Academy admin',
  permissions: PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

UserProfile _instructor() => const UserProfile(
  id: 'u_instructor',
  name: 'Meenakshi Iyer',
  email: 'meenakshi@example.test',
  role: UserRole.instructor,
  descriptor: 'Instructor',
  permissions: [PermissionKey.reportsView],
);

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  void answering({Map<String, dynamic>? overview, Object? refuse, int refuseStatus = 402}) {
    adapter.handler = (options) async {
      final path = options.path;
      if (refuse != null && path == '/reports/instructors') {
        return FakeAdapter.jsonResponse(refuse, status: refuseStatus);
      }
      if (path.startsWith('/reports/courses/')) {
        return FakeAdapter.jsonResponse(_json('course'));
      }
      if (path == '/reports/overview') {
        return FakeAdapter.jsonResponse(overview ?? _json('overview'));
      }
      for (final name in ['courses', 'learners', 'enrolments', 'instructors']) {
        if (path == '/reports/$name') return FakeAdapter.jsonResponse(_json(name));
      }
      if (path == '/instructors') {
        return FakeAdapter.jsonResponse(fixture('staff/instructors.json'));
      }
      return FakeAdapter.jsonResponse(fixture('staff/courses.json'));
    };
  }

  Future<GoRouter> pump(
    WidgetTester tester, {
    required String at,
    UserProfile? signedInAs,
    Size size = const Size(400, 8000),
    double textScale = 1,
  }) async {
    final router = await pumpPublicRouter(
      tester,
      adapter: adapter,
      signedInAs: signedInAs ?? _admin(),
      initialLocation: at,
      size: size,
      textScale: textScale,
      clock: () => _now,
      routes: [
        GoRoute(
          path: AppRoutes.staffReports,
          builder: (_, _) => const Scaffold(body: SafeArea(child: ReportsOverviewScreen())),
        ),
        GoRoute(
          path: AppRoutes.staffReportsCourses,
          builder: (_, _) => const Scaffold(body: SafeArea(child: CoursesReportScreen())),
        ),
        GoRoute(
          path: AppRoutes.staffReportsCoursePattern,
          builder: (_, state) => Scaffold(
            body: SafeArea(
              child: CourseReportScreen(courseId: state.pathParameters['courseId'] ?? ''),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.staffReportsLearners,
          builder: (_, _) => const Scaffold(body: SafeArea(child: LearnersReportScreen())),
        ),
        GoRoute(
          path: AppRoutes.staffReportsInstructors,
          builder: (_, _) => const Scaffold(body: SafeArea(child: InstructorsReportScreen())),
        ),
        GoRoute(
          path: AppRoutes.staffReportsEnrolments,
          builder: (_, _) => const Scaffold(body: SafeArea(child: EnrolmentsReportScreen())),
        ),
        GoRoute(path: AppRoutes.staffStudentPattern, builder: (_, _) => const Placeholder()),
        GoRoute(path: AppRoutes.staffInstructorPattern, builder: (_, _) => const Placeholder()),
      ],
    );
    await tester.pumpAndSettle();
    return router;
  }

  group('the overview', () {
    testWidgets('shows the academy\'s figures and says what it covers', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffReports);

      expect(find.text('Overview'), findsWidgets);
      // The period and the course count come from the route, not the app.
      expect(find.textContaining('Last 90 days'), findsOneWidget);
      expect(find.textContaining('6 courses'), findsOneWidget);
      expect(find.text('Enrolments'), findsWidgets);
      expect(find.text('35'), findsWidgets);
      expect(find.text('58%'), findsWidgets);
    });

    testWidgets('a rate\'s change reads in points, a count\'s in percent', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffReports);

      // Completion fell from 69% to 58%: eleven points, never sixteen percent.
      expect(find.textContaining('11 pts'), findsWidgets);
      expect(find.textContaining('16%'), findsNothing);
    });

    testWidgets('every chart is written out as a list beside it', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffReports);

      expect(find.byType(TrendChart), findsWidgets);
      final readOut = find.text('Read the figures');
      expect(readOut, findsWidgets);

      await tester.tap(readOut.first);
      await tester.pumpAndSettle();

      // The list behind the chart, so the figures survive a screen reader and 200% text.
      expect(find.byType(KeyValueTable), findsWidgets);
    });

    testWidgets('the busiest courses are listed and open their own report', (tester) async {
      answering();
      final router = await pump(tester, at: AppRoutes.staffReports);

      expect(find.text('Busiest courses'), findsOneWidget);
      await tester.tap(find.byType(CourseReportCard).first);
      await tester.pumpAndSettle();

      expect(locationOf(router), startsWith('/staff/reports/courses/'));
    });

    testWidgets('an academy with nothing to report says so', (tester) async {
      final empty = _json('overview');
      for (final key in ['enrollments', 'activeLearners']) {
        (empty['kpis']! as Map<String, dynamic>)[key] = {
          'value': 0,
          'previous': 0,
          'series': <int>[],
          'unit': 'count',
        };
      }
      answering(overview: empty);
      await pump(tester, at: AppRoutes.staffReports);

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.textContaining('Nothing to report yet'), findsOneWidget);
    });

    testWidgets('the figures are still readable at 200% text', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffReports, textScale: 2);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Last 90 days'), findsOneWidget);
    });
  });

  group('the filter sheet', () {
    testWidgets('changing the period re-reads the tab for that period', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffReports);

      // The header's Filters button is an icon, named by its tooltip.
      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();
      expect(find.text('What these reports cover'), findsOneWidget);

      await tester.tap(find.text('Last 90 days').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 12 months').last);
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/reports/overview').last.queryParameters['range'],
        '12m',
      );
    });

    testWidgets('an instructor is not offered the instructor filter', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffReports, signedInAs: _instructor());

      // The header's Filters button is an icon, named by its tooltip.
      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Period'), findsOneWidget);
      expect(
        find.text('Instructor'),
        findsNothing,
        reason: 'reporting on someone else\'s teaching is reports.instructors.view, an admin key',
      );
    });
  });

  group('the courses tabs', () {
    testWidgets('lists every course with activity and opens one', (tester) async {
      answering();
      final router = await pump(tester, at: AppRoutes.staffReportsCourses);

      expect(find.byType(CourseReportCard), findsWidgets);
      await tester.tap(find.byType(CourseReportCard).first);
      await tester.pumpAndSettle();

      expect(locationOf(router), startsWith('/staff/reports/courses/'));
    });

    testWidgets('one course shows its funnel, chapters, quizzes and assignments', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffReportsCourse('c1'));

      expect(find.text('How far the intake got'), findsOneWidget);
      expect(find.text('Chapters reached'), findsOneWidget);
      expect(find.text('The Nine Planets'), findsOneWidget);
      expect(find.text('Quizzes in this course'), findsOneWidget);
      expect(find.text('Assignments in this course'), findsOneWidget);
    });

    testWidgets('a course with no report says so rather than offering a retry', (tester) async {
      adapter.handler = (options) async => options.path.startsWith('/reports/courses/')
          ? FakeAdapter.jsonResponse(const {
              'message': 'There’s no report for this course — it may still be a draft.',
            }, status: 404)
          : FakeAdapter.jsonResponse(fixture('staff/courses.json'));
      await pump(tester, at: AppRoutes.staffReportsCourse('draft'));

      expect(find.textContaining('may still be a draft'), findsOneWidget);
      expect(find.byType(ErrorState), findsNothing);
    });
  });

  group('the learners tab', () {
    testWidgets('shows the academy\'s segments, statuses and its ordered page', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffReportsLearners);

      expect(find.text('Where learners stand'), findsOneWidget);
      expect(find.text('Gaurav Rao'), findsOneWidget);
      expect(find.text('Highest first'), findsOneWidget);
    });

    testWidgets('choosing a column asks the academy to order by it', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffReportsLearners);

      await tester.tap(find.text('Progress').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name').last);
      await tester.pumpAndSettle();

      final query = adapter.requests
          .where((r) => r.path == '/reports/learners')
          .last
          .queryParameters;
      expect(query['sortKey'], 'name');
      // A name reads A–Z first.
      expect(query['sortDirection'], 'asc');
    });

    testWidgets('turning the order around keeps the same column', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffReportsLearners);

      await tester.tap(find.text('Highest first'));
      await tester.pumpAndSettle();

      final query = adapter.requests
          .where((r) => r.path == '/reports/learners')
          .last
          .queryParameters;
      expect(query['sortKey'], 'progress');
      expect(query['sortDirection'], 'asc');
      expect(find.text('Lowest first'), findsOneWidget);
    });

    testWidgets('a learner opens their own profile', (tester) async {
      answering();
      final router = await pump(tester, at: AppRoutes.staffReportsLearners);

      await tester.tap(find.text('Gaurav Rao'));
      await tester.pumpAndSettle();

      expect(locationOf(router), startsWith('/staff/students/'));
    });
  });

  group('the enrolments tab', () {
    testWidgets('shows where enrolments came from and each month\'s intake', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffReportsEnrolments);

      expect(find.text('Where enrolments came from'), findsOneWidget);
      expect(find.text('Learner themselves'), findsOneWidget);
      expect(find.text('Each month’s intake'), findsOneWidget);
      expect(find.text('Aug 2026'), findsOneWidget);
    });

    testWidgets('a milestone the period cannot answer yet shows a dash, not a nought', (
      tester,
    ) async {
      answering();
      await pump(tester, at: AppRoutes.staffReportsEnrolments);

      // The fixture's newest cohorts have no 30/60/90-day figure.
      expect(find.text('—'), findsWidgets);
    });
  });

  group('the instructors tab', () {
    testWidgets('shows each instructor\'s teaching figures and opens their profile', (
      tester,
    ) async {
      answering();
      final router = await pump(tester, at: AppRoutes.staffReportsInstructors);

      expect(find.text('Dr. Meenakshi Iyer'), findsOneWidget);
      expect(find.text('How the teaching is going'), findsOneWidget);

      await tester.tap(find.text('Dr. Meenakshi Iyer'));
      await tester.pumpAndSettle();

      expect(locationOf(router), startsWith('/staff/instructors/'));
    });

    testWidgets('a plan without this report says so, and offers no retry', (tester) async {
      answering(
        refuse: const {
          'message': 'Instructor reports are not part of your plan.',
          'code': 'FEATURE_NOT_INCLUDED',
        },
        refuseStatus: 403,
      );
      await pump(tester, at: AppRoutes.staffReportsInstructors);

      expect(find.byType(RefusalView), findsOneWidget);
      expect(
        find.byType(ErrorState),
        findsNothing,
        reason: 'a plan that does not include a report is not an error to try again',
      );
    });
  });
}
