import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/theme/theme.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_billing/data/pending_payment_store.dart';
import 'package:syniastrolms_mobile/features/staff_billing/staff_billing.dart';
import 'package:syniastrolms_mobile/l10n/l10n.dart';

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

const _params = CheckoutParams(
  provider: 'razorpay',
  keyId: 'rzp_test_public',
  orderId: 'order_ABC',
  amount: 5899992,
);

const _start = CheckoutStart(
  checkout: _params,
  invoice: CheckoutInvoice(id: 'inv_1', number: 'INV-2026-0148', total: 5899992),
);

/// The native branch of [carryOutCheckout], with a stand-in for a gateway SDK this build does not
/// carry (C4). It proves what the app does with a gateway's result: hands it back to the academy
/// unchanged and shows the academy's answer — never the SDK's.
void main() {
  late FakeAdapter adapter;
  late List<CheckoutParams> launched;
  late MemoryPendingPaymentStore pending;

  setUp(() {
    adapter = FakeAdapter();
    launched = [];
    pending = MemoryPendingPaymentStore();
  });

  Future<void> pumpAndPay(
    WidgetTester tester, {
    required GatewayResult result,
    bool enabledInBuild = true,
  }) async {
    final scope = publicScope(
      adapter: adapter,
      signedInAs: _admin(),
      child: const SizedBox(),
      checkoutRunner: (params) async {
        launched.add(params);
        return result;
      },
      pendingPayments: pending,
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: noProviderRetry,
        overrides: [...scope.overrides, checkoutEnabledProvider.overrideWithValue(enabledInBuild)],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: app!,
          ),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                ref.watch(billingActionProvider);
                return TextButton(
                  onPressed: () => carryOutCheckout(
                    context,
                    ref,
                    plan: const CheckoutPlan(route: CheckoutRoute.native, params: _params),
                    start: _start,
                  ),
                  child: const Text('pay'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('pay'));
    await tester.pumpAndSettle();
  }

  testWidgets('a completed gateway result goes back to the academy unchanged', (tester) async {
    adapter.handler = (options) async => FakeAdapter.jsonResponse(const {
      'status': 'paid',
      'settled': true,
      'applied': true,
      'message': 'Payment received. Your plan is active.',
    });

    await pumpAndPay(
      tester,
      result: const GatewayCompleted(orderId: 'order_ABC', paymentId: 'pay_1', signature: 'sig'),
    );

    expect(launched.single.orderId, 'order_ABC');
    final confirm = adapter.requests.single;
    expect(confirm.path, '/tenant/billing/checkout/confirm');
    expect(confirm.data, {'orderId': 'order_ABC', 'paymentId': 'pay_1', 'signature': 'sig'});
    // The academy's words, not the gateway's.
    expect(find.text('Payment received. Your plan is active.'), findsOneWidget);
  });

  testWidgets('a closed or failed gateway changes nothing, and the academy is not asked', (
    tester,
  ) async {
    await pumpAndPay(tester, result: const GatewayNotCompleted(reason: 'cancelled'));

    expect(launched, hasLength(1));
    expect(adapter.requests, isEmpty);
    // Said plainly, with the way to try again, and nothing left spinning.
    expect(
      find.text('Payment not completed. Nothing has changed — you can try again.'),
      findsOneWidget,
    );
  });

  testWidgets('a build that takes no payments never launches a gateway', (tester) async {
    await pumpAndPay(
      tester,
      enabledInBuild: false,
      result: const GatewayCompleted(orderId: 'order_ABC', paymentId: 'pay_1', signature: 'sig'),
    );

    expect(launched, isEmpty);
    expect(adapter.requests.where((r) => r.method != 'GET'), isEmpty);
    expect(
      find.text(
        'Your invoice INV-2026-0148 for ₹58,999.92 is ready. Online payment isn’t available '
        'right now, so it stays open until it is.',
      ),
      findsOneWidget,
    );
  });

  group('a payment interrupted before the academy confirmed it', () {
    const paid = GatewayCompleted(orderId: 'order_ABC', paymentId: 'pay_1', signature: 'sig');

    testWidgets('is forgotten once the academy answers for good', (tester) async {
      adapter.handler = (options) async => FakeAdapter.jsonResponse(const {
        'status': 'paid',
        'settled': true,
        'applied': true,
        'message': 'Paid.',
      });
      await pumpAndPay(tester, result: paid);
      expect(pending.held, isNull);
    });

    testWidgets('is kept when the academy cannot be reached, to be confirmed later', (
      tester,
    ) async {
      adapter.handler = (options) async =>
          throw DioException.connectionError(requestOptions: options, reason: 'offline');
      await pumpAndPay(tester, result: paid);
      expect(pending.held, isNotNull);
      expect(pending.held!.paymentId, 'pay_1');
      expect(pending.held!.userId, _admin().id);
    });

    testWidgets('is dropped when the academy refuses it (not genuine, or not this academy\'s)', (
      tester,
    ) async {
      adapter.handler = (options) async => FakeAdapter.jsonResponse(const {
        'message': 'This payment was not signed by the payment provider.',
      }, status: 400);
      await pumpAndPay(tester, result: paid);
      expect(pending.held, isNull);
    });

    test('is confirmed on the next billing read, for the same person only', () async {
      final confirms = <Object?>[];
      adapter.handler = (options) async {
        if (options.path == '/tenant/billing/checkout/confirm') {
          confirms.add(options.data);
          return FakeAdapter.jsonResponse(const {
            'status': 'paid',
            'settled': true,
            'applied': true,
            'message': 'Paid.',
          });
        }
        return FakeAdapter.jsonResponse(fixture('staff/tenant-billing-active.json'));
      };
      Future<void> readBilling(String userId) async {
        final c = ProviderContainer(
          retry: noProviderRetry,
          overrides: publicScope(
            adapter: adapter,
            signedInAs: _admin(),
            child: const SizedBox(),
            pendingPayments: pending,
          ).overrides,
        );
        addTearDown(c.dispose);
        final sub = c.listen(tenantBillingProvider, (_, _) {});
        await c.read(tenantBillingProvider.future);
        sub.close();
      }

      // Someone else's proof on this device is not sent for this admin.
      await pending.write((
        userId: 'someone-else',
        orderId: 'order_X',
        paymentId: 'pay_X',
        signature: 's',
      ));
      await readBilling(_admin().id);
      expect(confirms, isEmpty);

      await pending.write((
        userId: _admin().id,
        orderId: 'order_ABC',
        paymentId: 'pay_1',
        signature: 'sig',
      ));
      await readBilling(_admin().id);
      expect(confirms, [
        {'orderId': 'order_ABC', 'paymentId': 'pay_1', 'signature': 'sig'},
      ]);
      expect(pending.held, isNull);
    });
  });
}
