import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_billing/staff_billing.dart';
import 'package:syniastrolms_mobile/features/staff_certificates/staff_certificates.dart';
import 'package:syniastrolms_mobile/features/staff_instructors/staff_instructors.dart';
import 'package:syniastrolms_mobile/features/staff_reports/staff_reports.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

/// The accessibility smoke pass for the screens FLUTTER-025 to 027 added (§16, §19, FLUTTER-029).
///
/// Every one is drawn from a real captured response and then held to the same three rules the design
/// system's gallery is: a tap target big enough to hit, a label a screen reader can read out, and text
/// that stands out from what is behind it. They are also drawn at 200% text, where a screen that
/// assumed its own font size falls over.
Map<String, dynamic> _json(String name) =>
    jsonDecode(jsonEncode(fixture('staff/$name.json'))) as Map<String, dynamic>;

final _now = DateTime.utc(2026, 9, 30, 13);

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
        return FakeAdapter.jsonResponse(_json('reports-course'));
      }
      for (final name in ['overview', 'courses', 'learners', 'enrolments', 'instructors']) {
        if (path == '/reports/$name') {
          return FakeAdapter.jsonResponse(_json('reports-$name'));
        }
      }
      if (path.startsWith('/instructors/')) return FakeAdapter.jsonResponse(_json('instructor'));
      if (path == '/instructors') return FakeAdapter.jsonResponse(_json('instructors'));
      if (path.startsWith('/certificates/')) return FakeAdapter.jsonResponse(_json('certificate'));
      if (path == '/certificates') return FakeAdapter.jsonResponse(_json('certificates'));
      if (path == '/tenant/billing') {
        return FakeAdapter.jsonResponse(_json('tenant-billing-active'));
      }
      return FakeAdapter.jsonResponse(fixture('staff/courses.json'));
    };
  });

  /// Pumps one screen and holds it to the three guidelines.
  Future<void> check(
    WidgetTester tester, {
    required String at,
    required List<RouteBase> routes,
    double textScale = 1,
  }) async {
    final semantics = tester.ensureSemantics();
    await pumpPublicRouter(
      tester,
      adapter: adapter,
      signedInAs: _admin(),
      initialLocation: at,
      size: const Size(400, 8000),
      textScale: textScale,
      clock: () => _now,
      routes: routes,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: at);
    if (textScale == 1) {
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }
    semantics.dispose();
  }

  List<RouteBase> routesFor(String path, Widget screen) => [
    GoRoute(
      path: path,
      builder: (_, _) => Scaffold(body: SafeArea(child: screen)),
    ),
  ];

  final screens = <String, (String, Widget)>{
    'the instructor directory': (AppRoutes.staffInstructors, const InstructorsScreen()),
    'the credential register': (AppRoutes.staffCertificates, const CertificatesRegisterScreen()),
    'the reports overview': (AppRoutes.staffReports, const ReportsOverviewScreen()),
    'the learners report': (AppRoutes.staffReportsLearners, const LearnersReportScreen()),
    'the enrolments report': (AppRoutes.staffReportsEnrolments, const EnrolmentsReportScreen()),
    'the instructors report': (AppRoutes.staffReportsInstructors, const InstructorsReportScreen()),
    'the billing page': (AppRoutes.staffBilling, const BillingScreen()),
    'the plans page': (AppRoutes.staffBillingPlans, const PlansScreen()),
  };

  for (final entry in screens.entries) {
    final (path, screen) = entry.value;

    testWidgets('${entry.key} can be hit, read out and read', (tester) async {
      await check(tester, at: path, routes: routesFor(path, screen));
    });

    testWidgets('${entry.key} still draws at 200% text', (tester) async {
      await check(tester, at: path, routes: routesFor(path, screen), textScale: 2);
    });
  }

  testWidgets('one instructor\'s profile can be hit, read out and read', (tester) async {
    await check(
      tester,
      at: AppRoutes.staffInstructor('i1'),
      routes: [
        GoRoute(
          path: AppRoutes.staffInstructorPattern,
          builder: (_, state) => Scaffold(
            body: SafeArea(
              child: InstructorScreen(instructorId: state.pathParameters['instructorId'] ?? ''),
            ),
          ),
        ),
      ],
    );
  });

  testWidgets('one certificate can be hit, read out and read', (tester) async {
    await check(
      tester,
      at: AppRoutes.staffCertificate('c1'),
      routes: [
        GoRoute(
          path: AppRoutes.staffCertificatePattern,
          builder: (_, state) => Scaffold(
            body: SafeArea(
              child: StaffCertificateScreen(
                certificateId: state.pathParameters['certificateId'] ?? '',
              ),
            ),
          ),
        ),
      ],
    );
  });
}
