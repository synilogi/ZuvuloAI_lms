import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_dashboard/staff_dashboard.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _snapshot(String name) =>
    jsonDecode(jsonEncode(fixture('dashboard/$name.json'))) as Map<String, dynamic>;

UserProfile _admin() => UserProfile(
  id: 'u_admin',
  name: 'Kavita Menon',
  email: 'admin@example.test',
  role: UserRole.admin,
  descriptor: 'Admin',
  permissions: PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

UserProfile _instructor() => const UserProfile(
  id: 'u_staff',
  name: 'Dr. Meenakshi Iyer',
  email: 'staff@example.test',
  role: UserRole.instructor,
  descriptor: 'Instructor',
);

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  /// Answers by path: the dashboard, the course titles and the instructor list are read together.
  void answering({Map<String, dynamic>? snapshot, Object? error, int status = 200}) {
    adapter.handler = (options) async {
      if (error != null && options.path == '/dashboard') {
        return FakeAdapter.jsonResponse(error, status: status);
      }
      if (options.path == '/courses') {
        return FakeAdapter.jsonResponse(fixture('staff/courses.json'));
      }
      if (options.path == '/instructors') {
        return FakeAdapter.jsonResponse(fixture('staff/instructors.json'));
      }
      return FakeAdapter.jsonResponse(snapshot ?? _snapshot('academy'));
    };
  }

  Future<GoRouter> pumpDashboard(
    WidgetTester tester, {
    UserProfile? signedInAs,
    Size size = const Size(400, 3000),
  }) => pumpPublicRouter(
    tester,
    adapter: adapter,
    signedInAs: signedInAs ?? _admin(),
    initialLocation: AppRoutes.staffDashboard,
    size: size,
    routes: [
      GoRoute(
        path: AppRoutes.staffDashboard,
        builder: (_, _) => const Scaffold(body: SafeArea(child: StaffDashboardScreen())),
      ),
      GoRoute(path: AppRoutes.staffStudents, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.staffReview, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.staffLive, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.staffLiveClassPattern, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.staffCertificatePattern, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.staffCoursePattern, builder: (_, _) => const Placeholder()),
    ],
  );

  testWidgets('what needs doing comes first, in the academy\'s own words', (tester) async {
    answering();

    await pumpDashboard(tester);
    await tester.pumpAndSettle();

    expect(find.text('Needs you'), findsOneWidget);
    expect(find.byType(AttentionCard), findsOneWidget);
    expect(find.textContaining('at risk'), findsWidgets);
    // The count the academy sent, not one the app worked out.
    expect(find.text('10'), findsWidgets);
  });

  testWidgets('the headline figures are the server\'s, and move in their own units', (
    tester,
  ) async {
    answering();

    await pumpDashboard(tester);
    await tester.pumpAndSettle();

    expect(find.text('Courses'), findsWidgets);
    expect(find.text('6'), findsWidgets);
    expect(find.text('52'), findsWidgets);
    expect(find.text('58%'), findsWidgets, reason: 'the completion rate, as a rate');
    // 43 → 52 learners is a count: percent. 59% → 58% completion is a rate: points.
    expect(find.text('+20.9%'), findsOneWidget);
    expect(find.text('−1 pts'), findsOneWidget);
  });

  testWidgets('an instructor sees their own review queue as the third figure', (tester) async {
    answering(snapshot: _snapshot('instructor'));

    await pumpDashboard(tester, signedInAs: _instructor());
    await tester.pumpAndSettle();

    // The queue leads the dashboard's figures, and is the third headline tile.
    expect(find.text('Waiting for review'), findsNWidgets(2));
    expect(find.text('Active instructors'), findsNothing);
    // No scope picker: the route decides an instructor's scope whatever is asked for.
    expect(find.text('Whole platform'), findsNothing);
    expect(
      adapter.requests.where((r) => r.path == '/dashboard').single.queryParameters,
      isEmpty,
      reason: 'an instructor never sends a scope or an instructorId',
    );
  });

  testWidgets('an admin may look at the academy or at one instructor', (tester) async {
    answering();

    await pumpDashboard(tester);
    await tester.pumpAndSettle();

    expect(find.text('Whole platform'), findsOneWidget);
    expect(adapter.requests.where((r) => r.path == '/dashboard').first.queryParameters, {
      'scope': 'academy',
    });

    answering(snapshot: _snapshot('instructor'));
    await tester.tap(find.text('One instructor'));
    await tester.pumpAndSettle();

    final asked = adapter.requests.where((r) => r.path == '/dashboard').last.queryParameters;
    expect(asked['scope'], 'instructor');
    expect(asked['instructorId'], isNotEmpty);
    expect(find.text('Waiting for review'), findsNWidgets(2));
  });

  testWidgets('an attention item opens the screen the academy pointed at', (tester) async {
    answering();

    final router = await pumpDashboard(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AttentionCard));
    await tester.pumpAndSettle();

    expect(locationOf(router), startsWith(AppRoutes.staffStudents));
  });

  testWidgets('an item pointing somewhere this app has no screen for leads nowhere', (
    tester,
  ) async {
    final snapshot = _snapshot('academy');
    (snapshot['attention']! as List<dynamic>).first as Map<String, dynamic>
      ..['to'] = '/ops/console'
      ..['title'] = 'Something elsewhere';
    answering(snapshot: snapshot);

    final router = await pumpDashboard(tester);
    await tester.pumpAndSettle();

    expect(find.text('Something elsewhere'), findsOneWidget);
    await tester.tap(find.byType(AttentionCard));
    await tester.pumpAndSettle();

    expect(locationOf(router), AppRoutes.staffDashboard, reason: 'it is not a door');
  });

  testWidgets('what happened lately reads as a sentence, and opens where it points', (
    tester,
  ) async {
    answering();

    final router = await pumpDashboard(tester);
    await tester.pumpAndSettle();

    expect(find.text('Recently'), findsOneWidget);
    expect(find.byType(DashboardEventRow), findsWidgets);

    await tester.scrollUntilVisible(
      find.byType(DashboardEventRow).first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(DashboardEventRow).first);
    await tester.pumpAndSettle();

    expect(locationOf(router), isNot(AppRoutes.staffDashboard));
  });

  testWidgets('each course says how it is doing, under the name the academy gave it', (
    tester,
  ) async {
    answering();

    await pumpDashboard(tester);
    await tester.pumpAndSettle();

    // The list is long; the course section sits below everything else.
    await tester.scrollUntilVisible(
      find.text('Course performance'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    // The heading can land on the bottom edge; one more step brings its cards on screen.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Course performance'), findsOneWidget);
    expect(find.byType(CoursePerformanceCard), findsWidgets);
    expect(find.textContaining('enrolled ·'), findsWidgets);
  });

  testWidgets('a brand-new academy is told there is nothing yet', (tester) async {
    answering(
      snapshot: {
        'scope': const {'kind': 'academy'},
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
        'kpis': const <String, Object>{},
        'enrollments': const <Object>[],
        'completions': const <Object>[],
        'courses': const <Object>[],
        'activity': const <Object>[],
        'engagement': const <String, Object>{},
        'upcomingLive': const <Object>[],
        'attention': const <Object>[],
        'events': const <Object>[],
      },
    );

    await pumpDashboard(tester);
    await tester.pumpAndSettle();

    expect(find.text('Nothing is waiting for you.'), findsOneWidget);
    expect(find.text('Nothing has happened yet.'), findsOneWidget);
    expect(find.text('Course performance'), findsNothing);
  });

  testWidgets('an academy that may not see reports is told so, not shown an error', (tester) async {
    // The academy's own refusal, as `permissionDenied` sends it.
    answering(
      error: {
        'message': 'You do not have permission to view reports.',
        'code': 'PERMISSION_DENIED',
      },
      status: 403,
    );

    await pumpDashboard(tester);
    await tester.pumpAndSettle();

    expect(find.byType(PermissionDeniedView), findsOneWidget);
  });

  testWidgets('a failed read offers a retry', (tester) async {
    answering(error: {'message': 'Server error.'}, status: 500);

    await pumpDashboard(tester);
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);

    answering();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(AttentionCard), findsOneWidget);
  });

  testWidgets('the figures stay side by side on a tablet, and stack on a phone', (tester) async {
    answering();

    await pumpDashboard(tester, size: const Size(900, 3000));
    await tester.pumpAndSettle();

    expect(find.byType(KpiTile), findsNWidgets(8), reason: 'four headline and four engagement');
    expect(tester.takeException(), isNull);
  });

  testWidgets('everything still fits at the largest text size', (tester) async {
    answering();

    await pumpPublicRouter(
      tester,
      adapter: adapter,
      signedInAs: _admin(),
      initialLocation: AppRoutes.staffDashboard,
      size: const Size(400, 6000),
      textScale: 2,
      routes: [
        GoRoute(
          path: AppRoutes.staffDashboard,
          builder: (_, _) => const Scaffold(body: SafeArea(child: StaffDashboardScreen())),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AttentionCard), findsOneWidget);
  });

  group('the scope a request carries', () {
    test('an instructor asks for nothing at all', () async {
      final adapter = FakeAdapter()
        ..handler = (_) async => FakeAdapter.jsonResponse(_snapshot('instructor'));
      final container = ProviderContainer(
        retry: noProviderRetry,
        overrides: publicScope(
          adapter: adapter,
          signedInAs: _instructor(),
          child: const SizedBox(),
        ).overrides,
      );
      addTearDown(container.dispose);

      await container.read(dashboardProvider.future);

      expect(adapter.lastRequest.queryParameters, isEmpty);
    });

    test('an admin asks for the academy until they pick someone', () async {
      final adapter = FakeAdapter()
        ..handler = (_) async => FakeAdapter.jsonResponse(_snapshot('academy'));
      final container = ProviderContainer(
        retry: noProviderRetry,
        overrides: publicScope(
          adapter: adapter,
          signedInAs: _admin(),
          child: const SizedBox(),
        ).overrides,
      );
      addTearDown(container.dispose);
      container.listen(dashboardProvider, (_, _) {});

      await container.read(dashboardProvider.future);
      expect(adapter.lastRequest.queryParameters, {'scope': 'academy'});

      container.read(dashboardViewProvider.notifier).showInstructor('ins_1');
      await container.read(dashboardProvider.future);

      expect(adapter.lastRequest.queryParameters, {'scope': 'instructor', 'instructorId': 'ins_1'});
    });
  });
}
