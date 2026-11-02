import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_billing/staff_billing.dart';
import 'package:syniastrolms_mobile/shared/entitlements/entitlements.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

UserProfile _admin() => UserProfile(
  id: 'u_admin',
  name: 'Kavita Menon',
  email: 'admin@example.test',
  role: UserRole.admin,
  descriptor: 'Admin',
  permissions: PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

UserProfile _instructor() => const UserProfile(
  id: 'u_inst',
  name: 'Meenakshi Iyer',
  email: 'instructor@example.test',
  role: UserRole.instructor,
  descriptor: 'Instructor',
);

/// The module's own page, standing in for the real screen behind the gate.
class _ModulePage extends StatelessWidget {
  const _ModulePage();

  @override
  Widget build(BuildContext context) => const Center(child: Icon(Icons.check, key: Key('page')));
}

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  /// `/academy/plan` answers with [plan] (a fixture name, or a status for a refusal), and
  /// `/tenant/billing` with the onboarding page or [billingStatus].
  void serve({
    String plan = 'academy-plan-trialing.json',
    int? planStatus,
    int billingStatus = 200,
    Map<String, dynamic>? billing,
  }) {
    adapter.handler = (options) async {
      if (options.path == '/academy/plan') {
        return planStatus == null
            ? FakeAdapter.jsonResponse(fixture('entitlements/$plan'))
            : FakeAdapter.jsonResponse(const {'message': 'Forbidden'}, status: planStatus);
      }
      if (options.path == '/tenant/billing') {
        return billingStatus == 200
            ? FakeAdapter.jsonResponse(billing ?? fixture('staff/tenant-billing-onboarding.json'))
            : FakeAdapter.jsonResponse(const {'message': 'Down.'}, status: billingStatus);
      }
      return FakeAdapter.jsonResponse(const {'message': 'Not found'}, status: 404);
    };
  }

  Future<GoRouter> pump(
    WidgetTester tester, {
    WorkspaceModule module = WorkspaceModule.live,
    UserProfile? signedInAs,
    Size size = const Size(360, 2000),
  }) async {
    final router = await pumpPublicRouter(
      tester,
      adapter: adapter,
      signedInAs: signedInAs ?? _admin(),
      initialLocation: AppRoutes.staffLive,
      size: size,
      routes: [
        GoRoute(
          path: AppRoutes.staffLive,
          builder: (_, _) => Scaffold(
            body: PlanGate(module: module, child: const _ModulePage()),
          ),
        ),
        for (final path in [AppRoutes.staffBillingPlans, AppRoutes.staffGetStarted])
          GoRoute(path: path, builder: (_, _) => const Scaffold()),
      ],
    );
    await tester.pumpAndSettle();
    return router;
  }

  final page = find.byKey(const Key('page'));
  int billingReads() => adapter.requests.where((r) => r.path == '/tenant/billing').length;

  group('open', () {
    testWidgets('a module the plan includes is the page itself', (tester) async {
      serve();
      await pump(tester, module: WorkspaceModule.courses);

      expect(page, findsOneWidget);
      expect(find.byType(PlanGateScreen), findsNothing);
      expect(find.byType(ReadOnlyModuleBanner), findsNothing);
    });

    testWidgets('everything is open while plans are not enforced', (tester) async {
      serve(plan: 'academy-plan-active.json');
      await pump(tester, module: WorkspaceModule.reports);

      expect(page, findsOneWidget);
    });

    testWidgets('a plan that cannot be read leaves the page to the server\'s refusal', (
      tester,
    ) async {
      serve(planStatus: 403);
      await pump(tester);

      expect(page, findsOneWidget);
      expect(find.byType(PlanGateScreen), findsNothing);
    });
  });

  group('locked, for an admin', () {
    testWidgets('names the module, says what it does and which plans include it', (tester) async {
      serve();
      await pump(tester);

      expect(page, findsNothing);
      expect(find.text('Live classes'), findsOneWidget);
      expect(find.text('Not included in your LMS plan'), findsOneWidget);
      expect(find.textContaining('Schedule live classes'), findsOneWidget);
      expect(find.text('Included in'), findsOneWidget);
      // Starter has no live classes; the three plans above it do.
      expect(find.text('Starter'), findsNothing);
      for (final name in ['Growth', 'Professional', 'Enterprise']) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
    });

    testWidgets('See plans goes to the plans', (tester) async {
      serve();
      final router = await pump(tester);

      await tester.tap(find.text('See plans'));
      await tester.pumpAndSettle();

      expect(locationOf(router), AppRoutes.staffBillingPlans);
    });

    testWidgets('a brand-new academy is sent to choose its first plan instead', (tester) async {
      serve(plan: 'academy-plan-new.json');
      final router = await pump(tester);

      await tester.tap(find.text('Choose a plan'));
      await tester.pumpAndSettle();

      expect(locationOf(router), AppRoutes.staffGetStarted);
    });

    testWidgets('the plans failing to load is said, with a retry, and the way on stays', (
      tester,
    ) async {
      serve(billingStatus: 500);
      await pump(tester);

      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('See plans'), findsOneWidget);
    });

    testWidgets('a module no plan on sale includes says so, and still offers the plans', (
      tester,
    ) async {
      final onlyStarter = Map<String, dynamic>.of(
        fixture('staff/tenant-billing-onboarding.json')! as Map<String, dynamic>,
      );
      onlyStarter['plans'] = [(onlyStarter['plans'] as List).first];
      serve(billing: onlyStarter);
      await pump(tester);

      expect(find.text('Included in'), findsNothing);
      expect(find.text('No plan on sale includes this yet.'), findsOneWidget);
      expect(find.text('See plans'), findsOneWidget);
    });

    testWidgets('its title is a heading, and it fits a small phone', (tester) async {
      serve();
      await pump(tester, size: const Size(320, 640));
      final handle = tester.ensureSemantics();

      expect(tester.takeException(), isNull);
      expect(
        tester.getSemantics(find.text('Live classes')),
        matchesSemantics(label: 'Live classes', isHeader: true),
      );
      handle.dispose();
    });
  });

  group('locked, for an instructor', () {
    testWidgets('asks them to ask their admin, and never reads or shows plans', (tester) async {
      serve();
      await pump(tester, signedInAs: _instructor());

      expect(find.text('Not included in your LMS plan'), findsOneWidget);
      expect(find.text('Ask your admin to upgrade the plan.'), findsOneWidget);
      expect(find.text('See plans'), findsNothing);
      expect(find.text('Growth'), findsNothing);
      expect(billingReads(), 0);
    });

    testWidgets('of a brand-new academy: being set up, not an error', (tester) async {
      serve(plan: 'academy-plan-new.json');
      await pump(tester, signedInAs: _instructor(), module: WorkspaceModule.courses);

      expect(find.text('Your LMS is being set up'), findsOneWidget);
      expect(find.textContaining('Courses will open here'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(billingReads(), 0);
    });
  });

  group('read-only', () {
    testWidgets('the page stays, under a notice that nothing new can be added', (tester) async {
      serve(plan: 'academy-plan-lapsed.json');
      await pump(tester);

      expect(page, findsOneWidget);
      expect(find.text('Live classes is read-only'), findsOneWidget);
      expect(find.text('See plans'), findsOneWidget);
    });

    testWidgets('an instructor sees it too, told who can renew', (tester) async {
      serve(plan: 'academy-plan-lapsed.json');
      await pump(tester, signedInAs: _instructor());

      expect(page, findsOneWidget);
      expect(find.text('Live classes is read-only'), findsOneWidget);
      expect(find.text('See plans'), findsNothing);
    });

    testWidgets('a module the last plan did not have is locked, not read-only', (tester) async {
      serve(plan: 'academy-plan-lapsed.json');
      await pump(tester, module: WorkspaceModule.branding);

      expect(page, findsNothing);
      expect(find.byType(PlanGateScreen), findsOneWidget);
    });
  });
}
