import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/features/staff_billing/staff_billing.dart';
import 'package:syniastrolms_mobile/shared/entitlements/entitlements.dart' show SubscriptionState;

import '../helpers/fake_adapter.dart';
import '../helpers/public_harness.dart';
import '../helpers/test_config.dart';

/// What the billing service is allowed to send is a **closed list** (§18, §11). These tests assert the
/// request bodies key by key, so a price, an amount, a tenant, a status or an entitlement can never be
/// added to one by accident.
Map<String, Object?> _bodyOf(FakeAdapter adapter) =>
    adapter.lastRequest.data! as Map<String, Object?>;

Map<String, dynamic> _checkoutStart() => const {
  'checkout': {
    'provider': 'razorpay',
    'keyId': 'rzp_test_public',
    'orderId': 'order_ABC',
    'amount': 5899992,
    'currency': 'INR',
  },
  'invoice': {'id': 'inv_1', 'number': 'INV-2026-0148', 'total': 5899992, 'currency': 'INR'},
};

/// What `/tenant/subscription/cancel` and `/resume` really answer with: the raw `SubscriptionRecord`
/// (`billingCycle`, `currentPeriodEndAt`, …), not the view `/tenant/billing` serves.
Map<String, dynamic> _subscriptionRecord() =>
    fixture('staff/subscription-record.json')! as Map<String, dynamic>;

void main() {
  late FakeAdapter adapter;
  late StaffBillingApi api;

  setUp(() {
    adapter = FakeAdapter();
    api = StaffBillingApi(
      ApiClient(
        config: testConfig(),
        tokenStore: FakeTokenStore('jwt'),
        logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
        adapter: adapter,
        logRequests: false,
      ),
    );
  });

  group('reading', () {
    test('the billing page is one read, with no query', () async {
      adapter.enqueueJson(fixture('staff/tenant-billing-active.json'));

      final billing = await api.billing();

      expect(adapter.lastRequest.method, 'GET');
      expect(adapter.lastRequest.path, '/tenant/billing');
      expect(adapter.lastRequest.queryParameters, isEmpty);
      expect(billing.subscription, isNotNull);
    });

    test('an invoice is read by its id or its number, escaped into the path', () async {
      adapter.enqueueJson(const {
        'id': 'inv_1',
        'number': 'INV-2026-0148',
        'subscriptionId': 's',
        'customerId': 'c',
        'customerName': 'A',
        'planName': 'Growth',
        'cycle': 'annual',
        'issuedAt': '2026-09-01T00:00:00.000Z',
        'periodStart': '2026-09-01T00:00:00.000Z',
        'periodEnd': '2027-09-01T00:00:00.000Z',
        'lines': <Object?>[],
        'taxPercent': 18,
        'currency': 'INR',
        'status': 'paid',
        'method': {'kind': 'card', 'brand': 'Visa'},
        'billingAddress': <String>[],
      });

      await api.invoice('INV 2026-0148');

      expect(adapter.lastRequest.path, '/tenant/billing/invoices/INV%202026-0148');
    });

    test('the plans fall back to their own route, read from PlanRecord rows in order', () async {
      adapter.enqueueJson(fixture('staff/tenant-plans.json'));

      final plans = await api.plans();

      expect(adapter.lastRequest.path, '/tenant/plans');
      // Served out of order; the academy's `displayOrder` decides.
      expect(plans.map((p) => p.name), ['Starter', 'Growth', 'Professional', 'Enterprise']);
      expect(plans.first.monthlyPrice, 149900, reason: 'read from `current`, not the top level');
      expect(plans.first.limits['learners.max'], 150);
      expect(plans.first.trialEnabled, isTrue);
    });

    test('billing details are read as the academy stored them', () async {
      adapter.enqueueJson(const {
        'legalName': 'ZuviloAI Academy',
        'email': 'billing@example.test',
        'addressLine1': '4th Cross, Jayanagar',
        'city': 'Bengaluru',
        'region': 'KA',
        'postalCode': '560041',
        'country': 'IN',
      });

      final details = await api.billingProfile();

      expect(adapter.lastRequest.path, '/tenant/billing-profile');
      expect(details!.city, 'Bengaluru');
    });

    test('no billing details yet is a 404, read as none rather than as an error', () async {
      adapter.enqueueJson(const {
        'message': 'This academy has no billing profile yet.',
      }, status: 404);

      expect(await api.billingProfile(), isNull);
    });
  });

  group('what saving billing details may send', () {
    test('the profile\'s own fields, trimmed, and an optional one only when given', () async {
      adapter.enqueueJson(const {'legalName': 'A'});

      await api.saveBillingProfile(
        const BillingDetails(
          legalName: ' ZuviloAI Academy ',
          email: 'billing@example.test',
          addressLine1: '4th Cross',
          addressLine2: '  ',
          city: 'Bengaluru',
          postalCode: '560041',
          country: 'in',
        ),
      );

      expect(adapter.lastRequest.method, 'PUT');
      expect(adapter.lastRequest.path, '/tenant/billing-profile');
      final body = _bodyOf(adapter);
      expect(body.keys.toSet(), {
        'legalName',
        'email',
        'addressLine1',
        'city',
        'postalCode',
        'country',
      });
      expect(body['legalName'], 'ZuviloAI Academy');
      expect(body['country'], 'IN');
      for (final forbidden in ['tenantId', 'status', 'amount']) {
        expect(body.containsKey(forbidden), isFalse, reason: forbidden);
      }
    });
  });

  group('what a preview may send', () {
    test('only the plan and the cycle, and it reads the academy\'s figures', () async {
      adapter.enqueueJson(fixture('staff/subscription-preview-upgrade.json'));

      final preview = await api.previewChange(planId: 'p4', cycle: BillingCycle.annual);

      expect(adapter.lastRequest.method, 'POST');
      expect(adapter.lastRequest.path, '/tenant/subscription/preview');
      expect(_bodyOf(adapter), {'planId': 'p4', 'cycle': 'annual'});
      expect(preview.payable!.gross, 5899992);
    });
  });

  group('what a purchase may send', () {
    test('only the plan and the cycle — never a price or an amount', () async {
      adapter.enqueueJson(_checkoutStart());

      await api.purchase(planId: 'plan_growth', cycle: BillingCycle.annual);

      expect(adapter.lastRequest.method, 'POST');
      expect(adapter.lastRequest.path, '/tenant/billing/purchase');
      final body = _bodyOf(adapter);
      expect(body.keys.toSet(), {'planId', 'cycle'});
      expect(body['planId'], 'plan_growth');
      expect(body['cycle'], 'annual');
      // The things §18 forbids a client to choose.
      for (final forbidden in [
        'amount',
        'price',
        'total',
        'currency',
        'tenantId',
        'status',
        'entitlement',
        'features',
      ]) {
        expect(body.containsKey(forbidden), isFalse, reason: forbidden);
      }
    });

    test('a monthly cycle travels by the route\'s own word', () async {
      adapter.enqueueJson(_checkoutStart());

      await api.purchase(planId: 'p', cycle: BillingCycle.monthly);

      expect(_bodyOf(adapter)['cycle'], 'monthly');
    });
  });

  group('what a checkout may send', () {
    test('one invoice, and nothing else', () async {
      adapter.enqueueJson(_checkoutStart());

      await api.checkoutInvoice('inv_1');

      expect(adapter.lastRequest.path, '/tenant/billing/checkout');
      final body = _bodyOf(adapter);
      expect(body.keys.toSet(), {'invoiceId'});
      expect(body['invoiceId'], 'inv_1');
    });

    test('or one plan change, and nothing else', () async {
      adapter.enqueueJson(_checkoutStart());

      await api.checkoutPlanChange('chg_1');

      final body = _bodyOf(adapter);
      expect(body.keys.toSet(), {'planChangeId'});
      expect(
        body.containsKey('invoiceId'),
        isFalse,
        reason: 'the route refuses both at once, and the app never sends both',
      );
    });
  });

  group('what a confirmation may send', () {
    test('the provider\'s own three fields, unchanged', () async {
      adapter.enqueueJson(const {
        'status': 'paid',
        'settled': true,
        'applied': true,
        'message': 'Payment received.',
      });

      await api.confirm(orderId: 'order_ABC', paymentId: 'pay_1', signature: 'sig');

      expect(adapter.lastRequest.path, '/tenant/billing/checkout/confirm');
      final body = _bodyOf(adapter);
      expect(body.keys.toSet(), {'orderId', 'paymentId', 'signature'});
      expect(body['orderId'], 'order_ABC');
      // Nothing about what the payment was for, or what it was worth.
      expect(body.containsKey('amount'), isFalse);
      expect(body.containsKey('invoiceId'), isFalse);
      expect(body.containsKey('planId'), isFalse);
    });
  });

  group('what a plan change may send', () {
    test('only the plan and the cycle', () async {
      adapter.enqueueJson(const {
        'change': {
          'id': 'chg_1',
          'direction': 'upgrade',
          'status': 'pending_payment',
          'toPlanId': 'p2',
          'toPlanName': 'Professional',
          'toCycle': 'annual',
          'credit': 3998995,
          'charge': 4999993,
          'currency': 'INR',
          'quotedAt': '2026-09-30T13:07:08.737Z',
        },
      });

      await api.changePlan(planId: 'p2', cycle: BillingCycle.annual);

      expect(adapter.lastRequest.path, '/tenant/subscription/change');
      expect(_bodyOf(adapter).keys.toSet(), {'planId', 'cycle'});
    });

    test('giving one up names only a reason, and only when there is one', () async {
      adapter
        ..enqueueJson(const <String, Object?>{})
        ..enqueueJson(const <String, Object?>{});

      await api.cancelPlanChange('chg 1');
      expect(adapter.lastRequest.path, '/tenant/subscription/plan-changes/chg%201/cancel');
      expect(_bodyOf(adapter), isEmpty);

      await api.cancelPlanChange('chg_1', reason: 'Not now.');
      expect(_bodyOf(adapter), {'reason': 'Not now.'});
    });
  });

  group('cancelling and resuming', () {
    test('a cancellation sends the reason and when it takes effect, trimmed', () async {
      adapter.enqueueJson(_subscriptionRecord());

      // The route answers with its raw record; reading it as the page's view used to throw here.
      await api.cancelSubscription(reason: '  Too expensive this year.  ');

      expect(adapter.lastRequest.path, '/tenant/subscription/cancel');
      final body = _bodyOf(adapter);
      expect(body.keys.toSet(), {'immediately', 'reason'});
      expect(body['immediately'], isFalse, reason: 'the screen cancels at the end of the period');
      expect(body['reason'], 'Too expensive this year.');
    });

    test('a resume sends nothing it was not given, and takes the raw record', () async {
      adapter.enqueueJson({
        ..._subscriptionRecord(),
        'status': 'active',
        'cancelAtPeriodEnd': false,
      });

      await api.resumeSubscription();

      expect(adapter.lastRequest.path, '/tenant/subscription/resume');
      expect(_bodyOf(adapter), isEmpty);
    });

    test('a pause is the platform\'s to lift: the refusal carries the academy\'s words', () async {
      const words =
          'This subscription was paused by the platform team. It resumes on its planned date, or '
          'when they end the pause.';
      adapter.enqueueJson(const {'message': words}, status: 403);

      await expectLater(
        api.resumeSubscription(),
        throwsA(isA<ApiException>().having((e) => e.failure.message, 'message', words)),
      );
    });
  });

  group('what starting a free trial may send', () {
    Map<String, dynamic> started() =>
        fixture('staff/tenant-billing-trial-start.json')! as Map<String, dynamic>;

    test('only the plan and the cycle — no billing address, payment, amount or status', () async {
      adapter.enqueueJson(started(), status: 201);

      final trial = await api.startTrial(
        planId: 'cmumqijur00kkmmoslkcygj8f',
        cycle: BillingCycle.monthly,
      );

      expect(adapter.lastRequest.method, 'POST');
      expect(adapter.lastRequest.path, '/tenant/billing/trial');
      expect(_bodyOf(adapter), {'planId': 'cmumqijur00kkmmoslkcygj8f', 'cycle': 'monthly'});
      expect(trial.status, SubscriptionState.trialing);
      expect(trial.trialEndAt, DateTime.utc(2026, 10, 17, 9, 30));
    });

    test('a yearly cycle travels by the route\'s own word', () async {
      adapter.enqueueJson(started(), status: 201);

      await api.startTrial(planId: 'p', cycle: BillingCycle.annual);

      expect(_bodyOf(adapter), {'planId': 'p', 'cycle': 'annual'});
    });

    for (final (code, message) in [
      ('PLAN_UNAVAILABLE', 'This plan does not offer a free trial.'),
      ('INVALID_SUBSCRIPTION_STATE', 'This academy has already had its free trial.'),
    ]) {
      test('a 409 $code comes back with its code, for the screen to explain', () async {
        adapter.enqueueJson({'message': message, 'code': code}, status: 409);

        await expectLater(
          api.startTrial(planId: 'p', cycle: BillingCycle.monthly),
          throwsA(
            isA<ApiException>().having(
              (e) => e.failure,
              'failure',
              isA<ConflictFailure>()
                  .having((f) => f.code, 'code', code)
                  .having((f) => f.message, 'message', message),
            ),
          ),
        );
      });
    }
  });
}
