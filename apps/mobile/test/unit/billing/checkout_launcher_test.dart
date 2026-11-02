import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/staff_billing/staff_billing.dart';

/// How the app decides what it can do with a checkout the academy opened (§11). The academy chooses
/// the gateway; the app only reads the shape it was handed, and where it cannot run it, it says so
/// rather than offering a button that leads nowhere (B9, A3).
CheckoutParams params({
  String provider = 'razorpay',
  String? keyId = 'rzp_test_public',
  String orderId = 'order_ABC',
  int amount = 5899992,
  String currency = 'INR',
  String? redirectUrl,
}) => CheckoutParams(
  provider: provider,
  keyId: keyId,
  orderId: orderId,
  amount: amount,
  currency: currency,
  redirectUrl: redirectUrl,
);

void main() {
  group('this build', () {
    test('carries the Razorpay Checkout SDK, which needs the order\'s publishable key', () {
      expect(nativeLaunchers, hasLength(1));
      expect(nativeLaunchers.single.provider, 'razorpay');
      expect(nativeLaunchers.single.needsKeyId, isTrue);
    });

    test('so a Razorpay order runs natively', () {
      final plan = planCheckout(params());

      expect(plan.route, CheckoutRoute.native);
      expect(plan.canRunHere, isTrue);
    });

    test('and another gateway with no page to open cannot be run here', () {
      final plan = planCheckout(params(provider: 'stripe'));

      expect(plan.route, CheckoutRoute.unsupported);
      expect(plan.canRunHere, isFalse);
      expect(plan.hostedUrl, isNull);
    });
  });

  group('a registered native launcher', () {
    const razorpay = NativeLauncher(provider: 'razorpay', needsKeyId: true);

    test('takes a checkout of its own provider with everything it needs', () {
      final plan = planCheckout(params(), launchers: const [razorpay]);

      expect(plan.route, CheckoutRoute.native);
      expect(plan.canRunHere, isTrue);
    });

    test('does not take another provider\'s checkout', () {
      final plan = planCheckout(params(provider: 'stripe'), launchers: const [razorpay]);

      expect(plan.route, CheckoutRoute.unsupported);
    });

    test('will not start without the publishable key it needs', () {
      expect(razorpay.canStart(params(keyId: null)), isFalse);
      expect(razorpay.canStart(params(keyId: '')), isFalse);
      expect(
        planCheckout(params(keyId: null), launchers: const [razorpay]).route,
        CheckoutRoute.unsupported,
      );
    });

    test('will not start without an order, or for nothing', () {
      expect(razorpay.canStart(params(orderId: '')), isFalse);
      expect(razorpay.canStart(params(amount: 0)), isFalse);
      expect(razorpay.canStart(params(amount: -1)), isFalse);
      expect(razorpay.canStart(params(currency: '')), isFalse);
    });

    test('a launcher that needs no key starts without one', () {
      const noKey = NativeLauncher(provider: 'upi-intent', needsKeyId: false);
      expect(noKey.canStart(params(provider: 'upi-intent', keyId: null)), isTrue);
    });

    test('is preferred over the academy\'s page when both are possible', () {
      final plan = planCheckout(
        params(redirectUrl: 'https://pay.example.test/order_ABC'),
        launchers: const [razorpay],
      );

      expect(plan.route, CheckoutRoute.native);
    });
  });

  group('a page the academy gave', () {
    test('is opened when there is no launcher for the gateway', () {
      final plan = planCheckout(
        params(provider: 'vyapar', redirectUrl: 'https://pay.example.test/order_ABC'),
      );

      expect(plan.route, CheckoutRoute.hostedPage);
      expect(plan.hostedUrl, Uri.parse('https://pay.example.test/order_ABC'));
    });

    test('is refused unless it is https: a payment is never carried in the clear', () {
      for (final url in [
        'http://pay.example.test/order',
        'ftp://pay.example.test/order',
        'javascript:alert(1)',
        'pay.example.test/order',
        '',
      ]) {
        expect(hostedPageOf(params(redirectUrl: url)), isNull, reason: url);
        expect(
          planCheckout(params(provider: 'vyapar', redirectUrl: url)).route,
          CheckoutRoute.unsupported,
          reason: url,
        );
      }
    });

    test('is refused when it names no host', () {
      expect(hostedPageOf(params(redirectUrl: 'https://')), isNull);
    });

    test(
      'an unknown provider with a page is still openable, because the page is the academy\'s',
      () {
        final plan = planCheckout(
          params(
            provider: 'a-gateway-nobody-has-heard-of',
            redirectUrl: 'https://pay.example.test/x',
          ),
        );

        expect(plan.route, CheckoutRoute.hostedPage);
      },
    );
  });

  group('how patiently the app waits', () {
    test('asks the academy again on its own schedule, not the bank\'s', () {
      expect(checkoutPollInterval, const Duration(seconds: 5));
      expect(checkoutPollAttempts, 12);
    });
  });

  group('whether a payment control may be shown at all', () {
    TenantBilling billing({required bool checkoutAvailable}) =>
        TenantBilling(checkoutAvailable: checkoutAvailable);

    test('needs both the build and the academy to allow it', () {
      expect(
        mayPayInApp(enabledInBuild: false, billing: billing(checkoutAvailable: true)),
        isFalse,
        reason: 'the build does not offer payment',
      );
      expect(
        mayPayInApp(enabledInBuild: true, billing: billing(checkoutAvailable: false)),
        isFalse,
        reason: 'the academy has no gateway connected',
      );
      expect(mayPayInApp(enabledInBuild: true, billing: billing(checkoutAvailable: true)), isTrue);
    });
  });
}
