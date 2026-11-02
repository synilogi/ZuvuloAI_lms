import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/platform/clock.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/shared/entitlements/entitlements.dart';

import '../../helpers/pump.dart';

UserProfile _profile(UserRole role, {List<PermissionKey> permissions = const []}) => UserProfile(
  id: 'u1',
  name: 'A',
  email: 'a@b.test',
  role: role,
  descriptor: 'x',
  permissions: permissions,
);

final _billingAdmin = _profile(UserRole.admin, permissions: const [PermissionKey.settingsView]);

final _now = DateTime.utc(2026, 10, 3, 9, 30);

class _StubPlan extends AcademyPlanNotifier {
  _StubPlan(this._plan);

  final AcademyPlan? _plan;

  @override
  Future<AcademyPlan?> build() async => _plan;
}

void main() {
  Future<void> pumpBanner(
    WidgetTester tester, {
    required UserProfile? profile,
    required AcademyPlan? plan,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(profile),
          clockProvider.overrideWithValue(() => _now),
          academyPlanProvider.overrideWith(() => _StubPlan(plan)),
        ],
        child: themedHarness(const AcademyPlanBanner(), scroll: false),
      ),
    );
    await tester.pumpAndSettle();
  }

  const lapsed = AcademyPlan(
    enforced: true,
    status: SubscriptionState.expired,
    restricted: true,
    lastFeatures: [FeatureKey.coursesManage],
  );
  const brandNew = AcademyPlan(enforced: true, restricted: true);
  final trialing = AcademyPlan(
    enforced: true,
    status: SubscriptionState.trialing,
    plan: const PlanSummary(id: 'p1', code: 'STARTER', name: 'Starter'),
    features: const [FeatureKey.coursesManage],
    trialEndsAt: _now.add(const Duration(days: 13, hours: 2)),
  );

  group('restricted', () {
    testWidgets('an admin who can read billing sees it while the plan has lapsed', (tester) async {
      await pumpBanner(tester, profile: _billingAdmin, plan: lapsed);

      expect(find.text('Your LMS has no active plan'), findsOneWidget);
      expect(
        find.text('Existing courses and learners stay available. New ones need a plan.'),
        findsOneWidget,
      );
      expect(find.text('Review plan'), findsOneWidget);
    });

    testWidgets('a brand-new academy is asked to choose its first plan', (tester) async {
      await pumpBanner(tester, profile: _billingAdmin, plan: brandNew);

      expect(find.text('Your LMS has no active plan'), findsOneWidget);
      expect(find.textContaining('Start a free trial'), findsOneWidget);
      expect(find.text('Choose a plan'), findsOneWidget);
    });

    testWidgets('while plans are not enforced it is not shown — nothing is refused', (
      tester,
    ) async {
      await pumpBanner(
        tester,
        profile: _billingAdmin,
        plan: const AcademyPlan(status: SubscriptionState.expired, restricted: true),
      );

      expect(find.text('Your LMS has no active plan'), findsNothing);
      expect(find.text('Review plan'), findsNothing);
    });

    testWidgets('a plan that was not read shows nothing', (tester) async {
      await pumpBanner(tester, profile: _billingAdmin, plan: null);

      expect(find.byType(PlanNoticeBar), findsNothing);
    });
  });

  group('past due', () {
    testWidgets('says the payment is overdue, with a way to billing', (tester) async {
      await pumpBanner(
        tester,
        profile: _billingAdmin,
        plan: const AcademyPlan(status: SubscriptionState.pastDue),
      );

      expect(find.text('Payment overdue'), findsOneWidget);
      expect(find.text('Open billing'), findsOneWidget);
      expect(find.text('Your LMS has no active plan'), findsNothing);
    });

    testWidgets('outranks restriction: one banner at a time', (tester) async {
      await pumpBanner(
        tester,
        profile: _billingAdmin,
        plan: const AcademyPlan(
          enforced: true,
          status: SubscriptionState.pastDue,
          restricted: true,
        ),
      );

      expect(find.byType(PlanNoticeBar), findsOneWidget);
      expect(find.text('Payment overdue'), findsOneWidget);
    });
  });

  group('trial', () {
    testWidgets('says how many days are left and links to the plans', (tester) async {
      await pumpBanner(tester, profile: _billingAdmin, plan: trialing);

      expect(find.text('Free trial · 14 days left'), findsOneWidget);
      expect(find.text('You’re trying Starter. Choose a plan before it ends.'), findsOneWidget);
      expect(find.text('Choose a plan'), findsOneWidget);
    });

    testWidgets('the last day reads as today', (tester) async {
      await pumpBanner(
        tester,
        profile: _billingAdmin,
        plan: trialing.copyWith(trialEndsAt: _now.subtract(const Duration(minutes: 1))),
      );

      expect(find.text('Free trial · ends today'), findsOneWidget);
    });

    testWidgets('a past-due trial shows the overdue banner instead', (tester) async {
      await pumpBanner(
        tester,
        profile: _billingAdmin,
        plan: trialing.copyWith(status: SubscriptionState.pastDue),
      );

      expect(find.byType(PlanNoticeBar), findsOneWidget);
      expect(find.text('Payment overdue'), findsOneWidget);
    });
  });

  group('who sees it', () {
    testWidgets('an instructor and a learner never see the academy\'s billing state', (
      tester,
    ) async {
      for (final profile in [_profile(UserRole.instructor), _profile(UserRole.student)]) {
        for (final plan in [
          lapsed,
          trialing,
          const AcademyPlan(status: SubscriptionState.pastDue),
        ]) {
          await pumpBanner(tester, profile: profile, plan: plan);
          expect(find.byType(PlanNoticeBar), findsNothing, reason: '${profile.role}');
        }
      }
    });

    testWidgets('an admin without the billing key does not see it either', (tester) async {
      await pumpBanner(tester, profile: _profile(UserRole.admin), plan: lapsed);

      expect(find.byType(PlanNoticeBar), findsNothing);
    });
  });

  group('read-only module banner', () {
    Future<void> pumpReadOnly(WidgetTester tester, UserProfile profile) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentUserProvider.overrideWithValue(profile)],
          child: themedHarness(
            const ReadOnlyModuleBanner(module: WorkspaceModule.live),
            scroll: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('offers an admin the plans', (tester) async {
      await pumpReadOnly(tester, _billingAdmin);

      expect(find.text('Live classes is read-only'), findsOneWidget);
      expect(find.text('See plans'), findsOneWidget);
    });

    testWidgets('tells an instructor who can renew, with no billing link', (tester) async {
      await pumpReadOnly(tester, _profile(UserRole.instructor));

      expect(find.text('Live classes is read-only'), findsOneWidget);
      expect(find.textContaining('ask your admin'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });
  });
}
