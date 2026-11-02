import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_billing/staff_billing.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

UserProfile _admin({List<PermissionKey>? permissions}) => UserProfile(
  id: 'u_admin',
  name: 'Kavita Menon',
  email: 'admin@example.test',
  role: UserRole.admin,
  descriptor: 'Academy admin',
  permissions:
      permissions ?? PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

/// A brand-new academy while the platform does not enforce plans: nothing is refused, so nothing is
/// forced — the dashboard offers the trial instead.
const _newNotEnforced = {
  'enforced': false,
  'status': null,
  'restricted': true,
  'plan': null,
  'features': <String>[],
  'lastFeatures': <String>[],
};

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  void serve({Object plan = _newNotEnforced, bool trialAvailable = true}) {
    adapter.handler = (options) async {
      if (options.path == '/academy/plan') {
        return FakeAdapter.jsonResponse(plan is String ? fixture('entitlements/$plan') : plan);
      }
      if (options.path == '/tenant/billing') {
        final billing = Map<String, dynamic>.of(
          fixture('staff/tenant-billing-onboarding.json')! as Map<String, dynamic>,
        )..['trialAvailable'] = trialAvailable;
        return FakeAdapter.jsonResponse(billing);
      }
      return FakeAdapter.jsonResponse(const {'message': 'Not found'}, status: 404);
    };
  }

  Future<GoRouter> pump(
    WidgetTester tester, {
    UserProfile? signedInAs,
    Map<String, Object> preferences = const {},
  }) async {
    final router = await pumpPublicRouter(
      tester,
      adapter: adapter,
      signedInAs: signedInAs ?? _admin(),
      initialLocation: AppRoutes.staffDashboard,
      size: const Size(360, 800),
      preferences: preferences,
      routes: [
        GoRoute(
          path: AppRoutes.staffDashboard,
          builder: (_, _) => const Scaffold(body: TrialOfferCard()),
        ),
        GoRoute(path: AppRoutes.staffGetStarted, builder: (_, _) => const Scaffold()),
      ],
    );
    // The plan is read first and the billing page only once it says a trial could be offered: each
    // read finishes on a zero-length timer that no frame waits for, so let both run.
    for (var i = 0; i < 3; i++) {
      await tester.pump(Duration.zero);
      await tester.pumpAndSettle();
    }
    return router;
  }

  final card = find.text('Try a plan free for 21 days');

  testWidgets('offers the longest trial on sale, and opens the plans', (tester) async {
    serve();
    final router = await pump(tester);

    expect(card, findsOneWidget);
    expect(find.textContaining('No payment needed'), findsOneWidget);

    await tester.tap(find.text('See plans and start a trial'));
    await tester.pumpAndSettle();
    expect(locationOf(router), AppRoutes.staffGetStarted);
  });

  testWidgets('can be closed, and stays closed for this person', (tester) async {
    serve();
    await pump(tester);

    // The close button's tooltip is also its screen-reader name.
    await tester.tap(find.byTooltip('Dismiss the free trial offer'));
    await tester.pumpAndSettle();
    expect(card, findsNothing);

    await pump(tester, preferences: const {'user.trialOfferDismissed': true});
    expect(card, findsNothing);
  });

  testWidgets('is not offered while plans are enforced — onboarding takes over there', (
    tester,
  ) async {
    serve(plan: 'academy-plan-new.json');
    await pump(tester);

    expect(card, findsNothing);
  });

  testWidgets('is not offered to an academy that already has a plan', (tester) async {
    serve(plan: 'academy-plan-active.json');
    await pump(tester);

    expect(card, findsNothing);
    expect(adapter.requests.where((r) => r.path == '/tenant/billing'), isEmpty);
  });

  testWidgets('is not offered once the academy says no trial is available', (tester) async {
    serve(trialAvailable: false);
    await pump(tester);

    expect(card, findsNothing);
  });

  testWidgets('is not offered to an admin who cannot start one, nor to an instructor', (
    tester,
  ) async {
    serve();
    await pump(tester, signedInAs: _admin(permissions: const [PermissionKey.settingsView]));
    expect(card, findsNothing);

    await pump(
      tester,
      signedInAs: const UserProfile(
        id: 'u_inst',
        name: 'Meenakshi Iyer',
        email: 'instructor@example.test',
        role: UserRole.instructor,
        descriptor: 'Instructor',
      ),
    );
    expect(card, findsNothing);
  });
}
