import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/storage/preferences.dart';
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
  descriptor: 'Academy admin',
  permissions: PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

const _starter = 'cmumqijur00kkmmoslkcygj8f';

void main() {
  late FakeAdapter adapter;

  /// What the academy says before and after the trial starts.
  late String planFixture;
  late (int, Object?) trialAnswer;

  setUp(() {
    adapter = FakeAdapter();
    planFixture = 'academy-plan-new.json';
    trialAnswer = (201, fixture('staff/tenant-billing-trial-start.json'));
    adapter.handler = (options) async {
      if (options.path == '/academy/plan') {
        return FakeAdapter.jsonResponse(fixture('entitlements/$planFixture'));
      }
      if (options.path == '/tenant/billing') {
        return FakeAdapter.jsonResponse(fixture('staff/tenant-billing-onboarding.json'));
      }
      if (options.path == '/tenant/billing/trial') {
        final (status, body) = trialAnswer;
        return FakeAdapter.jsonResponse(body, status: status);
      }
      return FakeAdapter.jsonResponse(const {'message': 'Not found'}, status: 404);
    };
  });

  int reads(String path) =>
      adapter.requests.where((r) => r.method == 'GET' && r.path == path).length;

  Future<ProviderContainer> container({Preferences? preferences}) async {
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: publicScope(
        adapter: adapter,
        signedInAs: _admin(),
        preferences: preferences ?? await testPreferences(),
        child: const SizedBox.shrink(),
      ).overrides,
    );
    addTearDown(container.dispose);
    container
      ..listen(trialControllerProvider, (_, _) {})
      ..listen(tenantBillingProvider, (_, _) {})
      ..listen(academyPlanProvider, (_, _) {})
      ..listen(onboardingDeferredProvider, (_, _) {});
    await container.read(tenantBillingProvider.future);
    await container.read(academyPlanProvider.future);
    return container;
  }

  group('starting a trial', () {
    test('sends the plan and the cycle, and nothing else', () async {
      final c = await container();

      await c
          .read(trialControllerProvider.notifier)
          .start(planId: _starter, cycle: BillingCycle.annual);

      final write = adapter.requests.singleWhere((r) => r.method == 'POST');
      expect(write.path, '/tenant/billing/trial');
      expect(write.data, {'planId': _starter, 'cycle': 'annual'});
    });

    test(
      'on success: started, with the academy\'s answer, and the plan and billing re-read',
      () async {
        final c = await container();
        expect(c.read(academyPlanProvider).value!.needsOnboarding, isTrue);
        final billingBefore = reads('/tenant/billing');
        final planBefore = reads('/academy/plan');
        planFixture = 'academy-plan-trialing.json';

        final ok = await c
            .read(trialControllerProvider.notifier)
            .start(planId: _starter, cycle: BillingCycle.monthly);

        expect(ok, isTrue);
        final state = c.read(trialControllerProvider);
        expect(state.stage, TrialStage.started);
        expect(state.planId, _starter);
        expect(state.trial!.status, SubscriptionState.trialing);
        expect(state.failure, isNull);

        // The workspace opens because the server now says so, not because the app flipped it.
        final plan = await c.read(academyPlanProvider.future);
        await c.read(tenantBillingProvider.future);
        expect(reads('/academy/plan'), planBefore + 1);
        expect(reads('/tenant/billing'), billingBefore + 1);
        expect(plan!.trialing, isTrue);
        expect(plan.needsOnboarding, isFalse);
        // The dashboard is not swapped back for onboarding while that re-read is on its way.
        expect(c.read(onboardingDeferredProvider), isTrue);
      },
    );

    test('busy while it is being asked for, and a second tap asks nothing', () async {
      final c = await container();
      final controller = c.read(trialControllerProvider.notifier);

      final first = controller.start(planId: _starter, cycle: BillingCycle.monthly);
      expect(c.read(trialControllerProvider).busy, isTrue);
      final second = await controller.start(planId: 'other', cycle: BillingCycle.monthly);
      await first;

      expect(second, isFalse);
      expect(adapter.requests.where((r) => r.method == 'POST'), hasLength(1));
    });
  });

  group('when the academy refuses', () {
    for (final (code, refusal) in [
      ('PLAN_UNAVAILABLE', TrialRefusal.planUnavailable),
      ('INVALID_SUBSCRIPTION_STATE', TrialRefusal.alreadySubscribed),
    ]) {
      test('a 409 $code fails with its reason and re-reads what is on offer', () async {
        trialAnswer = (409, {'message': 'Refused.', 'code': code});
        final c = await container();
        final billingBefore = reads('/tenant/billing');

        final ok = await c
            .read(trialControllerProvider.notifier)
            .start(planId: _starter, cycle: BillingCycle.monthly);

        expect(ok, isFalse);
        final state = c.read(trialControllerProvider);
        expect(state.stage, TrialStage.failed);
        expect(trialRefusalOf(state.failure!), refusal);
        await c.read(tenantBillingProvider.future);
        expect(reads('/tenant/billing'), billingBefore + 1);
        expect(c.read(onboardingDeferredProvider), isFalse);
      });
    }

    test('a permission refusal is not a 409: nothing is re-read', () async {
      trialAnswer = (403, {'message': 'You need settings.edit.', 'code': 'PERMISSION_DENIED'});
      final c = await container();
      final billingBefore = reads('/tenant/billing');

      await c
          .read(trialControllerProvider.notifier)
          .start(planId: _starter, cycle: BillingCycle.monthly);

      final state = c.read(trialControllerProvider);
      expect(state.failure, isA<PermissionFailure>());
      expect(trialRefusalOf(state.failure!), TrialRefusal.other);
      expect(reads('/tenant/billing'), billingBefore);
    });

    test('clearing the failure returns it to idle, ready to try again', () async {
      trialAnswer = (409, {'message': 'Refused.', 'code': 'PLAN_UNAVAILABLE'});
      final c = await container();
      final controller = c.read(trialControllerProvider.notifier);
      await controller.start(planId: _starter, cycle: BillingCycle.monthly);

      controller.clearFailure();

      expect(c.read(trialControllerProvider).stage, TrialStage.idle);
    });
  });

  group('the dashboard\'s trial offer', () {
    test('is remembered as closed for this person', () async {
      final preferences = await testPreferences();
      final c = await container(preferences: preferences);
      expect(c.read(trialOfferDismissedProvider), isFalse);

      await c.read(trialOfferDismissedProvider.notifier).dismiss();

      expect(c.read(trialOfferDismissedProvider), isTrue);
      expect(preferences.trialOfferDismissed, isTrue);
      // Person-scoped: a sign-out forgets it.
      await preferences.clearUserScoped();
      expect(preferences.trialOfferDismissed, isFalse);
    });
  });
}
