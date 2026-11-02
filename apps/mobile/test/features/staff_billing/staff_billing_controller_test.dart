import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_billing/staff_billing.dart';

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

Map<String, dynamic> _checkoutStart({String? redirectUrl, String provider = 'razorpay'}) => {
  'checkout': {
    'provider': provider,
    'keyId': 'rzp_test_public',
    'orderId': 'order_ABC',
    'amount': 5899992,
    'currency': 'INR',
    'redirectUrl': ?redirectUrl,
  },
  'invoice': {'id': 'inv_1', 'number': 'INV-2026-0148', 'total': 5899992, 'currency': 'INR'},
};

Map<String, dynamic> _outcome({
  required String status,
  required bool settled,
  bool applied = false,
}) => {'status': status, 'settled': settled, 'applied': applied, 'message': 'The academy says so.'};

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  ProviderContainer container() {
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: publicScope(
        adapter: adapter,
        signedInAs: _admin(),
        child: const SizedBox.shrink(),
      ).overrides,
    );
    addTearDown(container.dispose);
    container.listen(billingActionProvider, (_, _) {});
    return container;
  }

  void reading({Object? write, int writeStatus = 200}) {
    adapter.handler = (options) async => options.method == 'GET'
        ? FakeAdapter.jsonResponse(fixture('staff/tenant-billing-active.json'))
        : FakeAdapter.jsonResponse(write ?? _checkoutStart(), status: writeStatus);
  }

  group('reading the page', () {
    test('serves the academy\'s own subscription', () async {
      reading();
      final c = container();
      c.listen(tenantBillingProvider, (_, _) {});

      final billing = await c.read(tenantBillingProvider.future);

      expect(billing.subscription, isNotNull);
      expect(adapter.lastRequest.path, '/tenant/billing');
    });

    test('this build does not offer to take a payment', () async {
      reading();
      final c = container();

      expect(
        c.read(checkoutEnabledProvider),
        isFalse,
        reason: 'BILLING_CHECKOUT_ENABLED is off by default until the store question is answered',
      );
    });
  });

  group('starting a checkout', () {
    test('answers with how this device can carry it out — a Razorpay order, natively', () async {
      reading();
      final c = container();

      final plan = await c
          .read(billingActionProvider.notifier)
          .startPurchase(planId: 'p1', cycle: BillingCycle.annual);

      expect(plan, isNotNull);
      expect(plan!.route, CheckoutRoute.native);
      expect(plan.params.keyId, 'rzp_test_public', reason: 'the publishable key, from the server');
      expect(c.read(billingActionProvider).stage, CheckoutStage.atGateway);
      expect(c.read(billingActionProvider).start!.invoice.number, 'INV-2026-0148');
    });

    test('another gateway\'s own payment page is opened instead', () async {
      reading(
        write: _checkoutStart(
          provider: 'vyapar',
          redirectUrl: 'https://pay.example.test/order_ABC',
        ),
      );
      final c = container();

      final plan = await c.read(billingActionProvider.notifier).startInvoicePayment('inv_1');

      expect(plan!.route, CheckoutRoute.hostedPage);
      expect(plan.hostedUrl!.host, 'pay.example.test');
    });

    test('an academy with no gateway refuses before anything is issued', () async {
      reading(
        write: const {'message': 'Online payment is not set up yet.', 'code': 'PAYMENT_REQUIRED'},
        writeStatus: 409,
      );
      final c = container();

      final plan = await c.read(billingActionProvider.notifier).startPlanChangePayment('chg_1');

      expect(plan, isNull);
      expect(c.read(billingActionProvider).stage, CheckoutStage.idle);
      expect(c.read(billingActionProvider).failure, isA<ConflictFailure>());
    });
  });

  group('confirming a payment', () {
    test('a settled payment is the academy\'s word, and the page is read again', () async {
      var reads = 0;
      adapter.handler = (options) async {
        if (options.method == 'GET') {
          reads++;
          return FakeAdapter.jsonResponse(fixture('staff/tenant-billing-active.json'));
        }
        return FakeAdapter.jsonResponse(_outcome(status: 'paid', settled: true, applied: true));
      };
      final c = container();
      c.listen(tenantBillingProvider, (_, _) {});
      await c.read(tenantBillingProvider.future);
      final before = reads;

      final outcome = await c
          .read(billingActionProvider.notifier)
          .confirm(orderId: 'order_ABC', paymentId: 'pay_1', signature: 'sig');
      await c.read(tenantBillingProvider.future);

      expect(outcome!.settled, isTrue);
      expect(c.read(billingActionProvider).stage, CheckoutStage.settled);
      expect(reads, greaterThan(before), reason: 'the plan reads as active only from a fresh read');
    });

    test('a payment the bank has not settled is asked about again, then given up on', () async {
      var confirms = 0;
      adapter.handler = (options) async {
        if (options.method == 'GET') {
          return FakeAdapter.jsonResponse(fixture('staff/tenant-billing-active.json'));
        }
        confirms++;
        return FakeAdapter.jsonResponse(_outcome(status: 'authorized', settled: false));
      };
      final c = container();

      final outcome = await c
          .read(billingActionProvider.notifier)
          .confirm(
            orderId: 'order_ABC',
            paymentId: 'pay_1',
            signature: 'sig',
            // The real schedule is 5s × 12; the rule is the same at any speed.
            interval: Duration.zero,
            attempts: 3,
          );

      expect(outcome!.isPending, isTrue);
      expect(confirms, 4, reason: 'the first ask, then three more');
      expect(
        c.read(billingActionProvider).stage,
        CheckoutStage.waiting,
        reason: 'still waiting is not settled, and never reads as paid',
      );
      expect(c.read(billingActionProvider).done, isFalse);
    });

    test('a payment that settles on a later ask is taken as settled then', () async {
      var confirms = 0;
      adapter.handler = (options) async {
        if (options.method == 'GET') {
          return FakeAdapter.jsonResponse(fixture('staff/tenant-billing-active.json'));
        }
        confirms++;
        return FakeAdapter.jsonResponse(
          confirms < 3
              ? _outcome(status: 'pending', settled: false)
              : _outcome(status: 'paid', settled: true, applied: true),
        );
      };
      final c = container();

      final outcome = await c
          .read(billingActionProvider.notifier)
          .confirm(
            orderId: 'order_ABC',
            paymentId: 'pay_1',
            signature: 'sig',
            interval: Duration.zero,
          );

      expect(outcome!.settled, isTrue);
      expect(confirms, 3);
      expect(c.read(billingActionProvider).stage, CheckoutStage.settled);
    });

    test('a refused confirmation leaves nothing changed', () async {
      reading(
        write: const {'message': 'That signature does not match this payment.'},
        writeStatus: 400,
      );
      final c = container();

      final outcome = await c
          .read(billingActionProvider.notifier)
          .confirm(orderId: 'order_ABC', paymentId: 'pay_1', signature: 'wrong');

      expect(outcome, isNull);
      expect(c.read(billingActionProvider).stage, CheckoutStage.notCompleted);
      expect(c.read(billingActionProvider).done, isFalse);
    });

    test('a payment the academy was never paid for says so, and changes nothing', () {
      reading();
      final c = container();

      c.read(billingActionProvider.notifier).paymentNotCompleted();

      expect(c.read(billingActionProvider).stage, CheckoutStage.notCompleted);
      expect(c.read(billingActionProvider).done, isFalse);
      expect(c.read(billingActionProvider).outcome, isNull);
    });
  });

  group('changing and cancelling', () {
    test('a quote is the academy\'s, and the page is read again', () async {
      reading(
        write: const {
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
          'payable': {
            'currency': 'INR',
            'net': 4999993,
            'lines': [
              {'code': 'GST', 'label': 'Goods and Services Tax', 'rateBps': 1800, 'amount': 899999},
            ],
            'tax': 899999,
            'gross': 5899992,
            'inclusive': false,
            'purpose': 'plan_change',
          },
        },
      );
      final c = container();

      final quote = await c
          .read(billingActionProvider.notifier)
          .changePlan(planId: 'p2', cycle: BillingCycle.annual);

      expect(quote!.change.awaitsPayment, isTrue);
      expect(quote.payable!.gross, 5899992);
      expect(quote.payable!.tax, 899999);
      // The app never adds net and tax together to get the gross; all three are the academy's.
      expect(quote.payable!.net, 4999993);
    });

    test('a reason the route would refuse is never sent', () async {
      reading();
      final c = container();

      final ok = await c.read(billingActionProvider.notifier).cancelSubscription(reason: 'no');

      expect(ok, isFalse);
      expect(
        adapter.requests.where((r) => r.method != 'GET'),
        isEmpty,
        reason: 'the route takes 3 to 500 characters, and the app checks before asking',
      );
    });

    test('a cancellation the academy takes re-reads the page', () async {
      // The route's real answer: the raw SubscriptionRecord, which is not read as the page's view.
      reading(write: fixture('staff/subscription-record.json'));
      final c = container();
      var reads = 0;
      c.listen(tenantBillingProvider, (_, _) {
        reads++;
      });
      await c.read(tenantBillingProvider.future);

      final ok = await c
          .read(billingActionProvider.notifier)
          .cancelSubscription(reason: 'Too expensive this year.');
      await c.read(tenantBillingProvider.future);

      expect(ok, isTrue);
      expect(reads, greaterThan(1));
    });

    test('a second action is ignored while the first is in flight', () async {
      reading();
      final c = container();
      final controller = c.read(billingActionProvider.notifier);

      final first = controller.changePlan(planId: 'p2', cycle: BillingCycle.annual);
      final second = controller.resumeSubscription();

      expect(await second, isFalse);
      await first;
      expect(adapter.requests.where((r) => r.method != 'GET'), hasLength(1));
    });
  });

  group('resuming', () {
    test('a withdrawn cancellation takes the raw record and re-reads the page', () async {
      reading(write: fixture('staff/subscription-record.json'));
      final c = container();
      var reads = 0;
      c.listen(tenantBillingProvider, (_, _) => reads++);
      await c.read(tenantBillingProvider.future);

      final ok = await c.read(billingActionProvider.notifier).resumeSubscription();
      await c.read(tenantBillingProvider.future);

      expect(ok, isTrue);
      expect(c.read(billingActionProvider).done, isTrue);
      expect(c.read(billingActionProvider).failure, isNull);
      expect(reads, greaterThan(1));
    });

    test('a pause the platform holds is refused in the academy\'s own words', () async {
      const words =
          'This subscription was paused by the platform team. It resumes on its planned date, or '
          'when they end the pause.';
      reading(write: const {'message': words}, writeStatus: 403);
      final c = container();

      final ok = await c.read(billingActionProvider.notifier).resumeSubscription();

      expect(ok, isFalse);
      final failure = c.read(billingActionProvider).failure;
      expect(failure, isA<ForbiddenFailure>());
      expect(failure!.message, words);
    });
  });

  group('previewing a change', () {
    test('reads the academy\'s preview for one plan and cycle, and writes nothing', () async {
      reading(write: fixture('staff/subscription-preview-upgrade.json'));
      final c = container();
      const choice = (planId: 'p4', cycle: BillingCycle.annual);
      c.listen(planChangePreviewProvider(choice), (_, _) {});

      final preview = await c.read(planChangePreviewProvider(choice).future);

      expect(preview.payable!.gross, 5899992);
      final write = adapter.requests.where((r) => r.method != 'GET').single;
      expect(write.path, '/tenant/subscription/preview');
    });

    test('a trial or an open change is the academy\'s refusal, not an empty preview', () async {
      reading(
        write: const {
          'message': 'A plan change is already waiting.',
          'code': 'INVALID_SUBSCRIPTION_STATE',
        },
        writeStatus: 409,
      );
      final c = container();
      const choice = (planId: 'p4', cycle: BillingCycle.annual);
      c.listen(planChangePreviewProvider(choice), (_, _) {});

      await expectLater(c.read(planChangePreviewProvider(choice).future), throwsA(anything));
    });
  });

  group('billing details', () {
    const details = BillingDetails(
      legalName: 'ZuviloAI Academy',
      email: 'billing@example.test',
      addressLine1: '4th Cross, Jayanagar',
      city: 'Bengaluru',
      postalCode: '560041',
    );

    test('none yet reads as none', () async {
      adapter.handler = (options) async => FakeAdapter.jsonResponse(const {
        'message': 'This academy has no billing profile yet.',
      }, status: 404);
      final c = container();

      final read = await c.read(billingActionProvider.notifier).readBillingDetails();
      expect(read.details, isNull);
      expect(read.failure, isNull, reason: 'none yet is not a failure');
    });

    test('saved, they answer no refusal', () async {
      reading(write: details.toJson());
      final c = container();

      expect(await c.read(billingActionProvider.notifier).saveBillingDetails(details), isNull);
    });

    test('refused, the academy\'s field issues come back for the form to show', () async {
      reading(
        write: const {
          'message': 'Check the billing details.',
          'issues': [
            {'path': 'country', 'message': 'Choose the country by its two-letter code, e.g. IN.'},
          ],
        },
        writeStatus: 400,
      );
      final c = container();

      final failure = await c.read(billingActionProvider.notifier).saveBillingDetails(details);

      expect(failure, isA<ValidationFailure>());
      expect((failure! as ValidationFailure).issues.single.key, 'country');
    });
  });
}
