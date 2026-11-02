import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/staff_billing/staff_billing.dart';
import 'package:syniastrolms_mobile/shared/entitlements/entitlements.dart' show SubscriptionState;

/// Contract tests (§23) for the academy's own subscription, against what the real API returned.
/// Three states were created on the local server and captured with `tool/capture_fixture.sh`:
/// `tenant-billing-none.json` (never subscribed), `-active.json` (on a plan) and `-change.json` (an
/// upgrade quoted and waiting for its payment).
Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

TenantBilling _billing(String name) =>
    TenantBilling.fromJson(_fixture('staff/tenant-billing-$name.json')! as Map<String, dynamic>);

void main() {
  group('an academy that has never subscribed', () {
    late TenantBilling billing;

    setUp(() => billing = _billing('none'));

    test('has no subscription and no plan, and the academy says it is restricted', () {
      expect(billing.hasNoPlan, isTrue);
      expect(billing.subscription, isNull);
      expect(billing.plan, isNull);
      expect(billing.restricted, isTrue);
    });

    test('still lists what it is using, and the plans on sale', () {
      expect(billing.usage, isNotEmpty);
      expect(billing.plans, isNotEmpty);
      expect(billing.features, isNotEmpty);
    });

    test('nothing offers to take money: no gateway is connected', () {
      expect(billing.checkoutAvailable, isFalse);
      expect(
        mayPayInApp(enabledInBuild: true, billing: billing),
        isFalse,
        reason: 'the build offering payment is not enough; the academy has to have a gateway',
      );
    });
  });

  group('an academy on a plan', () {
    late TenantBilling billing;

    setUp(() => billing = _billing('active'));

    test('carries the subscription the academy holds, in its own words', () {
      final subscription = billing.subscription!;
      expect(subscription.id, isNotEmpty);
      expect(subscription.status, SubscriptionStatus.active);
      expect(subscription.cycle, BillingCycle.annual);
      expect(subscription.amount, greaterThan(0));
      expect(subscription.currency, 'INR');
      expect(subscription.startedAt.isUtc, isTrue);
      expect(subscription.renewsAt.isAfter(subscription.startedAt), isTrue);
      expect(billing.restricted, isFalse);
    });

    test('names the plan it is on, with that plan\'s own prices and limits', () {
      final plan = billing.plan!;
      expect(plan.name, isNotEmpty);
      expect(plan.monthlyPrice, greaterThan(0));
      expect(plan.annualPrice, greaterThan(0));
      expect(plan.limits, isNotEmpty);
      expect(plan.features, isNotEmpty);
    });

    test('a limit with a ceiling reports what is left; the academy did the arithmetic', () {
      final line = billing.usage.firstWhere((u) => u.allowed != null);
      expect(line.label, isNotEmpty);
      expect(line.remaining, line.allowed! - line.used);
      expect(line.share, closeTo(line.used / line.allowed!, 0.001));
      expect(line.isUnlimited, isFalse);
    });

    test('features say whether the plan includes them, and how each is delivered', () {
      expect(billing.features.any((f) => f.included), isTrue);
      expect(billing.features.any((f) => !f.included), isTrue);
      for (final feature in billing.features) {
        expect(feature.key, isNotEmpty);
        expect(feature.label, isNotEmpty);
        expect(feature.enforcement, isNot(FeatureEnforcement.unknown));
      }
    });

    test('the payment method is a brand and no more', () {
      final method = billing.subscription!.paymentMethod;
      expect(method.kind, isNot(PaymentMethodKind.unknown));
      expect(method.brand, isNotEmpty);
      // Nothing that could identify a card beyond its last four.
      expect(method.label, isNot(contains(RegExp(r'\d{6,}'))));
    });
  });

  group('an upgrade the academy has quoted', () {
    late TenantBilling billing;

    setUp(() => billing = _billing('change'));

    test('is waiting for its payment, and every figure is the academy\'s', () {
      final change = billing.openChange!;
      expect(change.id, isNotEmpty);
      expect(change.isUpgrade, isTrue);
      expect(change.awaitsPayment, isTrue);
      expect(change.isScheduled, isFalse);
      expect(change.toPlanName, isNotEmpty);
      expect(change.toCycle, BillingCycle.annual);
      // What is charged now and what is credited are both its arithmetic.
      expect(change.charge, greaterThan(0));
      expect(change.credit, greaterThan(0));
      expect(change.quotedAt.isUtc, isTrue);
    });
  });

  group('the checkout contract', () {
    test('a start carries the gateway the academy pinned and the invoice it issued', () {
      final start = CheckoutStart.fromJson(const {
        'checkout': {
          'provider': 'razorpay',
          'keyId': 'rzp_test_public',
          'orderId': 'order_ABC',
          'amount': 5899992,
          'currency': 'INR',
        },
        'invoice': {'id': 'inv_1', 'number': 'INV-2026-0148', 'total': 5899992, 'currency': 'INR'},
      });

      expect(start.checkout.provider, 'razorpay');
      expect(start.checkout.orderId, 'order_ABC');
      expect(start.checkout.amount, 5899992);
      expect(start.invoice.number, 'INV-2026-0148');
      // The amount shown is the invoice's own total, never a figure the app worked out.
      expect(start.invoice.total, start.checkout.amount);
    });

    test('an outcome is the academy\'s verdict, and pending is not a failure', () {
      final pending = CheckoutOutcome.fromJson(const {
        'status': 'authorized',
        'settled': false,
        'applied': false,
        'message': 'Your bank has approved this and it is being captured.',
      });
      expect(pending.isPending, isTrue);
      expect(pending.settled, isFalse);

      final paid = CheckoutOutcome.fromJson(const {
        'status': 'paid',
        'settled': true,
        'applied': true,
        'message': 'Payment received.',
      });
      expect(paid.isPending, isFalse);
      expect(paid.settled, isTrue);
      expect(paid.applied, isTrue);
      expect(paid.message, isNotEmpty);
    });

    test('a status the app does not know is unknown, not a success', () {
      final outcome = CheckoutOutcome.fromJson(const {
        'status': 'something-new',
        'settled': false,
        'applied': false,
        'message': '',
      });
      expect(outcome.status, ProviderPaymentStatus.unknown);
      expect(outcome.settled, isFalse);
      expect(outcome.isPending, isFalse);
    });
  });

  group('an invoice', () {
    /// The shape `packages/domain/src/subscription.ts` defines and the billing API serves. No invoice
    /// exists on the local server to capture: raising one needs an active payment gateway, which the
    /// scratch academy has none of (finding 32).
    InvoiceView invoice({Map<String, Object?> overrides = const {}}) => InvoiceView.fromJson({
      'id': 'inv_1',
      'number': 'INV-2026-0148',
      'subscriptionId': 'sub_1',
      'customerId': 'tenant-1',
      'customerName': 'ZuviloAI',
      'planName': 'Growth',
      'cycle': 'annual',
      'issuedAt': '2026-09-01T00:00:00.000Z',
      'periodStart': '2026-09-01T00:00:00.000Z',
      'periodEnd': '2027-09-01T00:00:00.000Z',
      'lines': [
        {'description': 'Growth, yearly', 'quantity': 1, 'unitAmount': 3999000},
      ],
      'taxPercent': 18,
      'currency': 'INR',
      'status': 'paid',
      'paidAt': '2026-09-01T06:30:00.000Z',
      'method': {'kind': 'card', 'brand': 'Visa', 'last4': '4242'},
      'billingAddress': ['4th Cross, Jayanagar', 'Bengaluru, KA 560041', 'India'],
      'amounts': {'subtotal': 3999000, 'tax': 719820, 'total': 4718820},
      ...overrides,
    });

    test('shows the figures the academy fixed, not a total the app added up', () {
      final view = invoice();
      expect(view.amounts!.subtotal, 3999000);
      expect(view.amounts!.tax, 719820);
      expect(view.amounts!.total, 4718820);
      expect(view.isPaid, isTrue);
      expect(view.isPayable, isFalse);
    });

    test('an open invoice is one the academy could be paid for', () {
      final view = invoice(overrides: const {'status': 'pending', 'paidAt': null});
      expect(view.isPayable, isTrue);
      expect(view.isPaid, isFalse);
      expect(view.paidAt, isNull);
    });

    test('a withdrawn invoice is kept as history and is not payable', () {
      final view = invoice(overrides: const {'status': 'void'});
      expect(view.status, InvoiceStatus.voided);
      expect(view.isPayable, isFalse);
    });

    test('the totals are absent rather than invented when the academy sends none', () {
      final view = invoice(overrides: const {'amounts': null});
      expect(view.amounts, isNull);
    });
  });

  group('a cancellation reason', () {
    test('is checked against what the route will take before it is sent', () {
      expect(cancelReasonIsEnough(''), isFalse);
      expect(cancelReasonIsEnough(' ab '), isFalse);
      expect(cancelReasonIsEnough('Too expensive for us this year.'), isTrue);
      expect(cancelReasonIsEnough('x' * maxCancelReason), isTrue);
      expect(cancelReasonIsEnough('x' * (maxCancelReason + 1)), isFalse);
    });
  });

  group('GET /tenant/plans — PlanRecord rows (constructed from lib/plans.ts toRecord)', () {
    Map<String, dynamic> plans() => _fixture('staff/tenant-plans.json')! as Map<String, dynamic>;

    test('reads the terms nested under `current`, as the billing page serves them flat', () {
      final rows = [
        for (final row in plans()['rows'] as List<dynamic>)
          PlanView.fromPlanRecord(row as Map<String, dynamic>),
      ];
      final onPage = {for (final p in _billing('active').plans) p.id: p};

      expect(rows, hasLength(onPage.length));
      for (final plan in rows) {
        final served = onPage[plan.id]!;
        expect(plan.name, served.name);
        expect(plan.monthlyPrice, served.monthlyPrice);
        expect(plan.annualPrice, served.annualPrice);
        expect(plan.currency, served.currency);
        expect(plan.cycles, served.cycles);
        expect(plan.trialDays, served.trialDays);
        expect(plan.trialEnabled, served.trialEnabled);
        expect(plan.limits, served.limits);
        expect(plan.features, served.features);
        expect(plan.order, served.order, reason: '`displayOrder` is the record\'s word for it');
      }
    });

    test('an unlimited limit stays unlimited, and a cycle not sold has no price', () {
      final row = Map<String, dynamic>.of(
        (plans()['rows'] as List<dynamic>).first as Map<String, dynamic>,
      );
      final current = Map<String, dynamic>.of(row['current'] as Map<String, dynamic>)
        ..['monthlyPrice'] = null
        ..['cycles'] = ['annual'];
      final plan = PlanView.fromPlanRecord({...row, 'current': current});

      expect(plan.limits['learners.max'], isNull, reason: 'Enterprise has no learner ceiling');
      expect(plan.sellsMonthly, isFalse);
      expect(plan.monthlyPrice, 0);
    });
  });

  group('cancel and resume answer with a raw SubscriptionRecord', () {
    test('which is not the view /tenant/billing serves — so the app does not read it as one', () {
      final record = _fixture('staff/subscription-record.json')! as Map<String, dynamic>;

      // `billingCycle`, `currentPeriodEndAt`, snake_case status: none of the view's fields.
      expect(record.containsKey('renewsAt'), isFalse);
      expect(record.containsKey('startedAt'), isFalse);
      expect(() => SubscriptionView.fromJson(record), throwsA(anything));
    });
  });

  group('POST /tenant/subscription/preview (constructed from lib/planChanges.ts)', () {
    PlanChangePreview preview(String name) => PlanChangePreview.fromJson(
      _fixture('staff/subscription-preview-$name.json')! as Map<String, dynamic>,
    );

    test('an upgrade is charged on payment, with the academy\'s own tax and total', () {
      final upgrade = preview('upgrade');

      expect(upgrade.kind, PlanChangeKind.upgrade);
      expect(upgrade.appliesOnPayment, isTrue);
      expect(upgrade.to.planName, 'Enterprise');
      expect(upgrade.to.cycle, BillingCycle.annual);
      expect(upgrade.credit, 3989995);
      expect(upgrade.payable!.gross, 5899992);
      expect(upgrade.needsBillingAddress, isFalse);
      expect(upgrade.conflicts, isEmpty);
      expect(upgrade.appliesAt.isUtc, isTrue);
    });

    test('a downgrade waits for the period to end, and names the limits already over', () {
      final downgrade = preview('downgrade');

      expect(downgrade.kind, PlanChangeKind.downgrade);
      expect(downgrade.timing, PlanChangeTiming.periodEnd);
      expect(downgrade.payable, isNull);
      expect(downgrade.conflicts.single.limit, 'courses.max');
      expect(downgrade.conflicts.single.usage, 12);
      expect(downgrade.conflicts.single.newLimit, 10);
    });

    test('a monthly-to-yearly move on the same plan is its own kind', () {
      final json = _fixture('staff/subscription-preview-upgrade.json')! as Map<String, dynamic>;

      expect(
        PlanChangePreview.fromJson({...json, 'kind': 'cycle_upgrade'}).kind,
        PlanChangeKind.cycleUpgrade,
      );
      expect(
        PlanChangePreview.fromJson({...json, 'kind': 'something_new'}).kind,
        PlanChangeKind.unknown,
      );
    });
  });

  group('billing details', () {
    const valid = BillingDetails(
      legalName: 'ZuviloAI Academy',
      email: 'billing@example.test',
      addressLine1: '4th Cross, Jayanagar',
      city: 'Bengaluru',
      region: 'KA',
      postalCode: '560041',
    );

    test('mirror the academy\'s own checks', () {
      expect(billingDetailsIssues(valid), isEmpty);
      expect(billingDetailsIssues(valid.copyWith(email: 'nope')), {BillingDetailsField.email});
      expect(billingDetailsIssues(valid.copyWith(country: 'IND')), {BillingDetailsField.country});
      expect(billingDetailsIssues(valid.copyWith(region: 'Karnataka state')), {
        BillingDetailsField.region,
      });
      expect(billingDetailsIssues(valid.copyWith(region: '', taxRegistration: '')), isEmpty);
    });

    test('send only the profile\'s own keys, and an optional one only when given', () {
      expect(valid.toRequest().keys.toSet(), {
        'legalName',
        'email',
        'addressLine1',
        'city',
        'region',
        'postalCode',
        'country',
      });
      expect(valid.copyWith(country: 'in').toRequest()['country'], 'IN');
    });
  });

  /// Onboarding (constructed from source — see the fixtures' `.cmd.txt`).
  group('self-serve onboarding', () {
    test('/tenant/billing says whether the academy may start a free trial', () {
      final billing = _billing('onboarding');

      expect(billing.trialAvailable, isTrue);
      expect(billing.enforced, isTrue);
      expect(billing.hasLiveSubscription, isFalse);
      // Starter, Growth and Pro offer trials; Enterprise does not.
      expect(billing.trialPlans.map((p) => p.code), ['STARTER', 'GROWTH', 'PRO']);
      expect(billing.plans.firstWhere((p) => p.code == 'PRO').trialDays, 21);
    });

    test('a page captured before the field existed reads as no trial on offer', () {
      final billing = _billing('none');

      expect(billing.trialAvailable, isFalse);
      expect(billing.trialPlans, isEmpty);
    });

    test('POST /tenant/billing/trial answers with the trialing subscription record', () {
      final body = _fixture('staff/tenant-billing-trial-start.json')! as Map<String, dynamic>;
      final trial = StartedTrial.fromJson(body['subscription'] as Map<String, dynamic>);

      expect(trial.id, 'cmuqtrial00001mmosab12cd3');
      expect(trial.planId, 'cmumqijur00kkmmoslkcygj8f');
      expect(trial.status, SubscriptionState.trialing);
      expect(trial.cycle, BillingCycle.monthly);
      expect(trial.trialStartAt, DateTime.utc(2026, 10, 3, 9, 30));
      expect(trial.trialEndAt, DateTime.utc(2026, 10, 17, 9, 30));
    });

    test('the tenant and the amount on that record are not modelled', () {
      final body = _fixture('staff/tenant-billing-trial-start.json')! as Map<String, dynamic>;
      final json = StartedTrial.fromJson(body['subscription'] as Map<String, dynamic>).toJson();

      expect(json.keys, isNot(contains('tenantId')));
      expect(json.keys, isNot(contains('amount')));
    });
  });
}
