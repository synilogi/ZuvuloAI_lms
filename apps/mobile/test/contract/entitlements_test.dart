import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/network/error_decoder.dart';
import 'package:syniastrolms_mobile/shared/entitlements/entitlements.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('captured from the real API', () {
    test('an academy served no plan is granted nothing', () {
      final entitlements = TenantEntitlements.fromJson(_fixture('entitlements/entitlements.json'));

      expect(entitlements.servesAPlan, isFalse);
      expect(entitlements.status, isNull);
      expect(entitlements.plan, isNull);
      expect(entitlements.features, isEmpty);
      expect(entitlements.includes(FeatureKey.liveClasses), isFalse);
      // Every catalogue limit comes back as 0 — "none", not "unlimited".
      expect(entitlements.limitOf(LimitKey.learnersMax), 0);
      expect(
        entitlements.limits.keys,
        containsAll(LimitKey.values.where((l) => l != LimitKey.unknown)),
      );
    });

    test('usage reports restriction and real counts', () {
      final usage = UsageSummary.fromJson(_fixture('entitlements/usage.json'));

      expect(usage.restricted, isTrue, reason: 'the seeded academy has no subscription');
      expect(usage.lines, hasLength(LimitKey.values.length - 1));
      final learners = usage.lineFor(LimitKey.learnersMax)!;
      expect(learners.label, 'Learners');
      expect(learners.used, greaterThan(0));
      expect(learners.allowed, 0);
      expect(learners.counts, isNotEmpty);
      expect(learners.isUnlimited, isFalse);
    });

    test('a gated create with enforcement on refuses with SUBSCRIPTION_REQUIRED', () {
      // Captured from the real API started with ENTITLEMENT_ENFORCEMENT=on, against the seeded
      // academy, which is served no plan.
      for (final fixture in [
        'errors/course-create-refused.json',
        'errors/live-create-refused.json',
      ]) {
        final failure = ErrorDecoder.fromResponse(402, _fixture(fixture));

        expect(
          failure,
          isA<EntitlementFailure>().having(
            (f) => f.problem,
            'problem',
            EntitlementProblem.subscriptionRequired,
          ),
          reason: fixture,
        );
        expect(refusalKindOf(failure), RefusalKind.subscriptionRequired);
        expect(failure.message, 'This academy has no plan. Choose one to use this.');
      }
    });

    test('an instructor reading /tenant is refused, which the app treats as "do not prefetch"', () {
      final failure = ErrorDecoder.fromResponse(
        403,
        _fixture('errors/entitlements-forbidden.json'),
      );

      expect(failure, isA<PermissionFailure>());
      expect(refusalKindOf(failure), RefusalKind.permission);
    });
  });

  group('an academy on a plan (the same shape, with a plan served)', () {
    final served = TenantEntitlements.fromJson(const {
      'tenantId': 'tenant-1',
      'status': 'active',
      'planVersionId': 'pv_1',
      'plan': {'id': 'p_1', 'code': 'PRO', 'name': 'Professional'},
      'features': ['courses.manage', 'live_classes', 'reports.basic', 'brand.new.feature'],
      'limits': {
        'learners.max': 500,
        'instructors.max': null,
        'courses.max': 25,
        'storage.bytes': 10737418240,
        'live_classes.max': 10,
        'admin_accounts.max': 3,
      },
    });

    test('reads the features and limits the server sent', () {
      expect(served.servesAPlan, isTrue);
      expect(served.status, SubscriptionState.active);
      expect(served.plan?.name, 'Professional');
      expect(served.includes(FeatureKey.liveClasses), isTrue);
      expect(served.includes(FeatureKey.certificatesManage), isFalse);
      expect(served.limitOf(LimitKey.learnersMax), 500);
      expect(served.limitOf(LimitKey.instructorsMax), isNull, reason: 'null is unlimited');
    });

    test('a feature this build does not know is ignored, not guessed at', () {
      expect(served.features, isNot(contains(FeatureKey.unknown)));
      expect(served.features, hasLength(3));
    });

    test('every subscription state the backend can send parses', () {
      for (final state in [
        'trialing',
        'active',
        'past_due',
        'paused',
        'canceling',
        'canceled',
        'expired',
      ]) {
        final parsed = TenantEntitlements.fromJson({'status': state, 'features': <String>[]});
        expect(parsed.status, isNot(SubscriptionState.unknown), reason: state);
      }
      expect(
        TenantEntitlements.fromJson(const {'status': 'something_new'}).status,
        SubscriptionState.unknown,
      );
    });

    test('a usage line for an unlimited allowance reads as unlimited', () {
      final usage = UsageSummary.fromJson(const {
        'status': 'active',
        'restricted': false,
        'lines': [
          {
            'limit': 'instructors.max',
            'label': 'Instructors',
            'used': 4,
            'allowed': null,
            'remaining': null,
            'counts': 'Every instructor.',
          },
        ],
      });
      final line = usage.lineFor(LimitKey.instructorsMax)!;
      expect(line.isUnlimited, isTrue);
      expect(line.fraction, isNull);
      expect(usage.restricted, isFalse);
    });

    test('a meter fraction is clamped to the allowance', () {
      final over = UsageLine.fromJson(const {
        'limit': 'courses.max',
        'label': 'Courses',
        'used': 30,
        'allowed': 25,
        'remaining': 0,
        'counts': 'x',
      });
      expect(over.fraction, 1.0);
    });
  });

  /// `GET /academy/plan`. The fixtures are constructed from the route's source, not captured — the
  /// local server was down (each `.cmd.txt` says so); recapture when it is up.
  group('academy plan (constructed from apps/api/src/routes/academyPlan.ts)', () {
    AcademyPlan plan(String name) => AcademyPlan.fromJson(_fixture('entitlements/$name.json'));

    test('a brand-new academy: enforced, never subscribed, nothing served', () {
      final p = plan('academy-plan-new');

      expect(p.enforced, isTrue);
      expect(p.status, isNull, reason: '`status: null` is "never subscribed", not unknown');
      expect(p.neverSubscribed, isTrue);
      expect(p.needsOnboarding, isTrue);
      expect(p.restricted, isTrue);
      expect(p.plan, isNull);
      expect(p.features, isEmpty);
      expect(p.lastFeatures, isEmpty);
      expect(p.trialEndsAt, isNull);
      expect(p.renewsAt, isNull);
    });

    test('a trial: its plan, its features and when it ends', () {
      final p = plan('academy-plan-trialing');

      expect(p.status, SubscriptionState.trialing);
      expect(p.trialing, isTrue);
      expect(p.restricted, isFalse);
      expect(
        p.plan,
        const PlanSummary(id: 'cmumqijur00kkmmoslkcygj8f', code: 'STARTER', name: 'Starter'),
      );
      expect(p.features, [FeatureKey.coursesManage, FeatureKey.assessmentsManage]);
      expect(p.trialEndsAt, DateTime.utc(2026, 10, 17, 9, 30));
      expect(p.trialEndsAt!.isUtc, isTrue);
      expect(p.renewsAt, isNull, reason: 'renewsAt is sent only for a live non-trial subscription');
    });

    test('a lapsed plan keeps its features readable, dropping ones this build does not know', () {
      final p = plan('academy-plan-lapsed');

      expect(p.status, SubscriptionState.expired);
      expect(p.restrictionBites, isTrue);
      expect(p.features, isEmpty);
      expect(p.lastFeatures, [
        FeatureKey.coursesManage,
        FeatureKey.assessmentsManage,
        FeatureKey.liveClasses,
        FeatureKey.certificatesManage,
        FeatureKey.reportsBasic,
      ]);
    });

    test('an active plan while not enforced, with its renewal date', () {
      final p = plan('academy-plan-active');

      expect(p.enforced, isFalse);
      expect(p.status, SubscriptionState.active);
      expect(p.renewsAt, DateTime.utc(2027, 9, 30, 13, 6, 26, 550));
      expect(p.trialEndsAt, isNull);
    });

    test('carries no money: no price, amount or invoice is modelled or sent', () {
      for (final name in [
        'academy-plan-new',
        'academy-plan-trialing',
        'academy-plan-lapsed',
        'academy-plan-active',
      ]) {
        final raw = File('test/fixtures/entitlements/$name.json').readAsStringSync();
        expect(raw, isNot(matches(RegExp('amount|price|invoice', caseSensitive: false))));
      }
    });

    test('a status a later server adds reads as unknown, not as never subscribed', () {
      final p = AcademyPlan.fromJson(const {
        'enforced': true,
        'status': 'hibernating',
        'restricted': true,
        'plan': null,
        'features': <String>[],
        'lastFeatures': <String>[],
      });

      expect(p.status, SubscriptionState.unknown);
      expect(p.needsOnboarding, isFalse);
    });
  });
}
