import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_billing/staff_billing.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';
import '../../helpers/test_config.dart';

/// The fixtures are dated 3 October 2026.
final _now = DateTime.utc(2026, 10, 3, 9, 30);

Map<String, dynamic> _billing() =>
    jsonDecode(jsonEncode(fixture('staff/tenant-billing-onboarding.json'))) as Map<String, dynamic>;

UserProfile _admin({List<PermissionKey>? permissions}) => UserProfile(
  id: 'u_admin',
  name: 'Kavita Menon',
  email: 'admin@example.test',
  role: UserRole.admin,
  descriptor: 'Admin',
  permissions:
      permissions ?? PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

const _starter = 'cmumqijur00kkmmoslkcygj8f';

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  /// Answers the onboarding screen's reads, and the trial with [trial] (status, body).
  void serve({
    Map<String, dynamic>? billing,
    (int, Object?) trial = const (201, null),
    int billingStatus = 200,
  }) {
    final page = billing ?? _billing();
    adapter.handler = (options) async {
      switch (options.path) {
        case '/tenant/billing':
          return billingStatus == 200
              ? FakeAdapter.jsonResponse(page)
              : FakeAdapter.jsonResponse(const {
                  'message': 'Something went wrong.',
                }, status: billingStatus);
        case '/academy/plan':
          return FakeAdapter.jsonResponse(fixture('entitlements/academy-plan-trialing.json'));
        case '/tenant/billing/trial':
          final (status, body) = trial;
          return FakeAdapter.jsonResponse(
            body ?? fixture('staff/tenant-billing-trial-start.json'),
            status: status,
          );
      }
      return FakeAdapter.jsonResponse(const {'message': 'Not found'}, status: 404);
    };
  }

  Future<GoRouter> pump(
    WidgetTester tester, {
    UserProfile? signedInAs,
    bool checkoutEnabled = false,
    Size size = const Size(360, 6000),
  }) async {
    final router = await pumpPublicRouter(
      tester,
      adapter: adapter,
      signedInAs: signedInAs ?? _admin(),
      initialLocation: AppRoutes.staffGetStarted,
      size: size,
      clock: () => _now,
      config: testConfig(billingCheckoutEnabled: checkoutEnabled),
      routes: [
        GoRoute(path: AppRoutes.staffGetStarted, builder: (_, _) => const ChoosePlanScreen()),
        GoRoute(
          path: AppRoutes.staffDashboard,
          builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
        ),
      ],
    );
    await tester.pumpAndSettle();
    return router;
  }

  Finder startTrial(int days) => find.widgetWithText(AppButton, 'Start $days-day free trial');

  group('the plans on offer', () {
    testWidgets('greets the academy and lists every plan with its price, trial and limits', (
      tester,
    ) async {
      serve();
      await pump(tester);

      expect(find.text('Welcome to ZuviloAI'), findsOneWidget);
      for (final name in ['Starter', 'Growth', 'Professional', 'Enterprise']) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.text('₹1,499 a month'), findsOneWidget);
      expect(find.text('14-day free trial'), findsNWidgets(2));
      expect(find.text('21-day free trial'), findsOneWidget);
      // Limits by name, never by the academy's key.
      expect(find.text('Learners'), findsWidgets);
      expect(find.text('learners.max'), findsNothing);
      expect(find.text('25 GB'), findsOneWidget);
      // Features by the academy's own label.
      expect(find.text('Course management'), findsWidgets);
    });

    testWidgets('the cycle toggle shows yearly prices, and a plan not sold monthly says so', (
      tester,
    ) async {
      serve();
      await pump(tester);

      expect(find.text('Not sold monthly'), findsOneWidget, reason: 'Enterprise is yearly only');
      await tester.tap(find.text('Yearly'));
      await tester.pumpAndSettle();

      expect(find.text('₹14,990 a year'), findsOneWidget);
      expect(find.text('Not sold monthly'), findsNothing);
    });

    testWidgets('a trial is offered only on plans that have one', (tester) async {
      serve();
      await pump(tester);

      expect(startTrial(14), findsNWidgets(2));
      expect(startTrial(21), findsOneWidget);
      expect(find.textContaining('free trial'), findsWidgets);
    });

    testWidgets('no purchase in a build that takes no payments — it says where to buy', (
      tester,
    ) async {
      serve();
      await pump(tester);

      expect(find.textContaining('Buy for'), findsNothing);
      expect(
        find.text(
          'Paid plans can’t be bought in the app right now. You can still start a free trial.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('no purchase either while the academy has no gateway, even if the build would', (
      tester,
    ) async {
      serve();
      await pump(tester, checkoutEnabled: true);

      expect(find.textContaining('Buy for'), findsNothing);
      expect(
        find.text(
          'Paid plans can’t be bought in the app right now. You can still start a free trial.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Buy appears only with the build\'s checkout on and a gateway connected', (
      tester,
    ) async {
      serve(billing: _billing()..['checkoutAvailable'] = true);
      await pump(tester, checkoutEnabled: true);

      expect(find.widgetWithText(AppButton, 'Buy for ₹1,499'), findsOneWidget);
      expect(
        find.text(
          'Paid plans can’t be bought in the app right now. You can still start a free trial.',
        ),
        findsNothing,
      );
    });

    testWidgets('a trial already used is said, and none is offered', (tester) async {
      serve(billing: _billing()..['trialAvailable'] = false);
      await pump(tester);

      expect(find.text('Your LMS has already used its free trial.'), findsOneWidget);
      expect(find.textContaining('-day free trial').hitTestable(), findsWidgets);
      expect(
        find.byWidgetPredicate((w) => w is AppButton && w.label.startsWith('Start')),
        findsNothing,
      );
    });

    testWidgets('an admin who may read billing but not change it is told who can', (tester) async {
      serve();
      await pump(tester, signedInAs: _admin(permissions: const [PermissionKey.settingsView]));

      expect(find.textContaining('Only an admin who can change billing'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is AppButton && w.label.startsWith('Start')),
        findsNothing,
      );
    });
  });

  group('states', () {
    testWidgets('an empty catalogue says no plans are on sale', (tester) async {
      serve(billing: _billing()..['plans'] = <Object>[]);
      await pump(tester);

      expect(find.text('No plans on sale'), findsOneWidget);
      expect(find.text('Not now — go to the dashboard'), findsOneWidget);
    });

    testWidgets('a failed read offers a retry', (tester) async {
      serve(billingStatus: 500);
      await pump(tester);

      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('an academy already on a plan is sent on to its dashboard', (tester) async {
      final billing =
          jsonDecode(jsonEncode(fixture('staff/tenant-billing-active.json')))
              as Map<String, dynamic>;
      serve(billing: billing);
      final router = await pump(tester);

      expect(find.text('Your LMS is on a plan'), findsOneWidget);
      await tester.tap(find.text('Go to the dashboard'));
      await tester.pumpAndSettle();
      expect(locationOf(router), AppRoutes.staffDashboard);
    });

    testWidgets('fits a small phone without overflow', (tester) async {
      serve();
      await pump(tester, size: const Size(320, 640));

      expect(tester.takeException(), isNull);
      expect(find.text('Welcome to ZuviloAI'), findsOneWidget);
    });
  });

  group('starting the trial', () {
    testWidgets('sends the plan and cycle, then says it started and goes to the dashboard', (
      tester,
    ) async {
      serve();
      final router = await pump(tester);

      await tester.tap(startTrial(14).first);
      await tester.pumpAndSettle();

      final write = adapter.requests.singleWhere((r) => r.method == 'POST');
      expect(write.path, '/tenant/billing/trial');
      expect(write.data, {'planId': _starter, 'cycle': 'monthly'});
      expect(find.text('Your free trial has started'), findsOneWidget);
      expect(find.textContaining('open until 17 Oct 2026'), findsOneWidget);
      // What the academy is served now is re-read by the controller (trial_controller_test).

      await tester.tap(find.text('Go to the dashboard'));
      await tester.pumpAndSettle();
      expect(locationOf(router), AppRoutes.staffDashboard);
    });

    testWidgets('on the yearly cycle the trial is asked for yearly', (tester) async {
      serve();
      await pump(tester);

      await tester.tap(find.text('Yearly'));
      await tester.pumpAndSettle();
      await tester.tap(startTrial(21));
      await tester.pumpAndSettle();

      expect(adapter.requests.singleWhere((r) => r.method == 'POST').data, {
        'planId': 'cmumqijva00kommosrabmizys',
        'cycle': 'annual',
      });
    });

    testWidgets('a plan that no longer has a trial is explained, and the plans re-read', (
      tester,
    ) async {
      serve(trial: (409, {'message': 'No trial.', 'code': 'PLAN_UNAVAILABLE'}));
      await pump(tester);
      final readsBefore = adapter.requests.where((r) => r.path == '/tenant/billing').length;

      await tester.tap(startTrial(14).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('doesn’t offer a free trial any more'), findsOneWidget);
      expect(find.text('Your free trial has started'), findsNothing);
      expect(
        adapter.requests.where((r) => r.path == '/tenant/billing').length,
        greaterThan(readsBefore),
      );
    });

    testWidgets('a trial already used elsewhere is explained', (tester) async {
      serve(trial: (409, {'message': 'Used.', 'code': 'INVALID_SUBSCRIPTION_STATE'}));
      await pump(tester);

      await tester.tap(startTrial(14).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('already has a plan or has used its free trial'), findsOneWidget);
    });
  });

  testWidgets('"Not now" goes to the dashboard', (tester) async {
    serve();
    final router = await pump(tester);

    await tester.tap(find.text('Not now — go to the dashboard'));
    await tester.pumpAndSettle();

    expect(locationOf(router), AppRoutes.staffDashboard);
  });

  testWidgets('every action carries a label a screen reader can say', (tester) async {
    serve();
    await pump(tester);
    final handle = tester.ensureSemantics();

    expect(find.bySemanticsLabel(RegExp('Start 14-day free trial')), findsWidgets);
    expect(find.bySemanticsLabel('Billing cycle'), findsOneWidget);
    handle.dispose();
  });
}
