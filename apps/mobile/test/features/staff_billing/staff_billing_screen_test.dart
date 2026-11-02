import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/core/platform/external_link.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_billing/staff_billing.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';
import '../../helpers/test_config.dart';

Map<String, dynamic> _billing(String name) =>
    jsonDecode(jsonEncode(fixture('staff/tenant-billing-$name.json'))) as Map<String, dynamic>;

/// The fixtures were captured on 30 September 2026.
final _now = DateTime.utc(2026, 9, 30, 13);

UserProfile _admin({List<PermissionKey>? permissions}) => UserProfile(
  id: 'u_admin',
  name: 'Kavita Menon',
  email: 'admin@example.test',
  role: UserRole.admin,
  descriptor: 'Admin',
  permissions:
      permissions ?? PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

/// An admin who may read billing but not change it.
UserProfile _readOnlyAdmin() => _admin(permissions: const [PermissionKey.settingsView]);

Map<String, dynamic> _invoiceJson({String status = 'paid'}) => {
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
  'status': status,
  'paidAt': status == 'paid' ? '2026-09-01T06:30:00.000Z' : null,
  'method': {'kind': 'card', 'brand': 'Visa', 'last4': '4242'},
  'billingAddress': ['4th Cross, Jayanagar', 'Bengaluru, KA 560041'],
  'amounts': {'subtotal': 3999000, 'tax': 719820, 'total': 4718820},
};

const _profile = <String, dynamic>{
  'legalName': 'ZuviloAI Academy',
  'email': 'billing@example.test',
  'addressLine1': '4th Cross, Jayanagar',
  'city': 'Bengaluru',
  'region': 'KA',
  'postalCode': '560041',
  'country': 'IN',
};

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

const _quotedChange = {
  'change': {
    'id': 'chg_1',
    'direction': 'upgrade',
    'status': 'pending_payment',
    'toPlanId': 'p4',
    'toPlanName': 'Enterprise',
    'toCycle': 'annual',
    'credit': 3989995,
    'charge': 4999993,
    'currency': 'INR',
    'quotedAt': '2026-09-30T13:07:08.737Z',
  },
  'payable': {'currency': 'INR', 'net': 4999993, 'tax': 899999, 'gross': 5899992},
};

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  /// The non-GET requests made, in order.
  List<RequestOptions> writes() => adapter.requests.where((r) => r.method != 'GET').toList();

  /// Answers by path: the billing page, the billing profile ([profile] `null` is a 404 until one is
  /// saved), and each POST from [posts].
  void routed(
    Map<String, dynamic> billing, {
    Map<String, dynamic>? profile = _profile,
    Map<String, (int, Object?)> posts = const {},
  }) {
    var stored = profile;
    adapter.handler = (options) async {
      if (options.path == '/tenant/billing-profile') {
        if (options.method == 'PUT') {
          stored = Map<String, dynamic>.from(options.data as Map);
          return FakeAdapter.jsonResponse(stored);
        }
        return stored == null
            ? FakeAdapter.jsonResponse(const {
                'message': 'This academy has no billing profile yet.',
              }, status: 404)
            : FakeAdapter.jsonResponse(stored);
      }
      if (options.method == 'GET') return FakeAdapter.jsonResponse(billing);
      final (status, body) = posts[options.path] ?? (404, const {'message': 'Not found'});
      return FakeAdapter.jsonResponse(body, status: status);
    };
  }

  void answering(Map<String, dynamic> billing, {Object? write, int writeStatus = 200}) {
    adapter.handler = (options) async => options.method == 'GET'
        ? FakeAdapter.jsonResponse(billing)
        : FakeAdapter.jsonResponse(write ?? const <String, Object?>{}, status: writeStatus);
  }

  Future<GoRouter> pump(
    WidgetTester tester, {
    required String at,
    UserProfile? signedInAs,
    Size size = const Size(400, 8000),
    bool checkoutEnabled = false,
    OpenExternalLink? openExternalLink,
    NativeCheckoutRunner? checkoutRunner,
  }) async {
    final router = await pumpPublicRouter(
      tester,
      adapter: adapter,
      signedInAs: signedInAs ?? _admin(),
      initialLocation: at,
      size: size,
      clock: () => _now,
      config: testConfig(billingCheckoutEnabled: checkoutEnabled),
      openExternalLink: openExternalLink,
      checkoutRunner: checkoutRunner,
      routes: [
        GoRoute(
          path: AppRoutes.staffBilling,
          builder: (_, _) => const Scaffold(body: SafeArea(child: BillingScreen())),
        ),
        GoRoute(
          path: AppRoutes.staffBillingPlans,
          builder: (_, _) => const Scaffold(body: SafeArea(child: PlansScreen())),
        ),
        GoRoute(
          path: AppRoutes.staffInvoicePattern,
          builder: (_, state) => Scaffold(
            body: SafeArea(
              child: InvoiceScreen(invoiceId: state.pathParameters['invoiceId'] ?? ''),
            ),
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();
    return router;
  }

  group('an academy with no plan', () {
    testWidgets('says so, and offers the plans rather than a purchase', (tester) async {
      answering(_billing('none'));
      await pump(tester, at: AppRoutes.staffBilling);

      expect(find.textContaining('isn’t on a plan yet'), findsOneWidget);
      expect(find.text('See the plans'), findsOneWidget);
      // No gateway is connected, so nothing offers to take money.
      expect(find.textContaining('Online payment isn’t available yet'), findsOneWidget);
      expect(find.text('Pay this invoice'), findsNothing);
    });

    testWidgets('shows what it is using and what its plan would include', (tester) async {
      answering(_billing('none'));
      await pump(tester, at: AppRoutes.staffBilling);

      expect(find.text('What you’re using'), findsOneWidget);
      expect(find.text('Learners'), findsWidgets);
      expect(find.text('What your plan includes'), findsOneWidget);
      expect(find.text('Not included'), findsWidgets);
    });

    testWidgets('says limits are not being enforced while the platform does not', (tester) async {
      answering(_billing('none'));
      await pump(tester, at: AppRoutes.staffBilling);

      expect(find.textContaining('aren’t enforced yet'), findsOneWidget);
    });

    testWidgets('has no invoices or payments to list', (tester) async {
      answering(_billing('none'));
      await pump(tester, at: AppRoutes.staffBilling);

      expect(find.text('No invoices yet.'), findsOneWidget);
      expect(find.text('No payments yet.'), findsOneWidget);
    });
  });

  group('an academy on a plan', () {
    testWidgets('shows the plan, its price and when it renews', (tester) async {
      answering(_billing('active'));
      await pump(tester, at: AppRoutes.staffBilling);

      expect(find.text('Growth'), findsWidgets);
      // The amount is the academy's own, formatted and never recomputed.
      expect(find.textContaining('₹39,990.00'), findsWidgets);
      expect(find.textContaining('Billed yearly'), findsOneWidget);
      expect(find.textContaining('Renews'), findsOneWidget);
    });

    testWidgets('a limit with a ceiling draws a meter and says what is left', (tester) async {
      answering(_billing('active'));
      await pump(tester, at: AppRoutes.staffBilling);

      expect(find.text('60 of 750'), findsOneWidget);
      expect(find.text('690 left'), findsOneWidget);
      expect(find.byType(ProgressBar), findsWidgets);
    });

    testWidgets('offers to change the plan and to cancel it', (tester) async {
      answering(_billing('active'));
      await pump(tester, at: AppRoutes.staffBilling);

      expect(find.text('Change plan'), findsOneWidget);
      expect(find.text('Cancel the plan'), findsOneWidget);
    });

    testWidgets('an admin who may only read is offered no change at all', (tester) async {
      answering(_billing('active'));
      await pump(tester, at: AppRoutes.staffBilling, signedInAs: _readOnlyAdmin());

      expect(
        find.text('Cancel the plan'),
        findsNothing,
        reason: 'cancelling is settings.edit, which this account does not have',
      );
    });

    testWidgets('cancelling asks for the reason and will not send a short one', (tester) async {
      answering(_billing('active'));
      await pump(tester, at: AppRoutes.staffBilling);

      await tester.tap(find.text('Cancel the plan'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel at the end of the period?'), findsOneWidget);

      final confirm = find.widgetWithText(AppButton, 'Cancel the plan').last;
      await tester.enterText(_field(tester, 'Why are you cancelling?'), 'no');
      await tester.pumpAndSettle();
      expect(tester.widget<AppButton>(confirm).onPressed, isNull);

      await tester.enterText(
        _field(tester, 'Why are you cancelling?'),
        'Too expensive for us this year.',
      );
      await tester.pumpAndSettle();
      expect(tester.widget<AppButton>(confirm).onPressed, isNotNull);
    });
  });

  group('a plan change the academy has quoted', () {
    testWidgets('says what it is, what it costs, and offers to give it up', (tester) async {
      answering(_billing('change'));
      await pump(tester, at: AppRoutes.staffBilling);

      expect(find.textContaining('upgrade to Professional'), findsOneWidget);
      // Both figures are the academy's arithmetic.
      expect(find.textContaining('₹49,999.93'), findsOneWidget);
      expect(find.textContaining('₹39,989.95'), findsOneWidget);
      expect(find.text('Give up this change'), findsWidgets);
    });

    testWidgets('offers no way to pay it, because the academy has no gateway', (tester) async {
      answering(_billing('change'));
      await pump(tester, at: AppRoutes.staffBilling);

      expect(
        find.text('Pay for this upgrade'),
        findsNothing,
        reason: 'checkout is off in this build and the academy has no gateway connected',
      );
    });

    testWidgets('giving it up asks first', (tester) async {
      answering(_billing('change'));
      await pump(tester, at: AppRoutes.staffBilling);

      await tester.tap(find.text('Give up this change').first);
      await tester.pumpAndSettle();

      expect(find.text('Give up this plan change?'), findsOneWidget);
    });
  });

  group('the plans screen', () {
    testWidgets('lists the plans with the academy\'s own prices and limits', (tester) async {
      answering(_billing('active'));
      await pump(tester, at: AppRoutes.staffBillingPlans);

      expect(find.text('Starter'), findsOneWidget);
      expect(find.textContaining('a month'), findsWidgets);
      expect(find.text('What it allows'), findsWidgets);
    });

    testWidgets('marks the plan the academy is already on and offers no change to it', (
      tester,
    ) async {
      answering(_billing('active'));
      await pump(tester, at: AppRoutes.staffBillingPlans);

      expect(find.text('Your plan'), findsOneWidget);
    });

    testWidgets('an upgrade the app can pay for says it continues to payment', (tester) async {
      routed(
        {..._billing('active'), 'checkoutAvailable': true},
        posts: {
          '/tenant/subscription/preview': (200, fixture('staff/subscription-preview-upgrade.json')),
        },
      );
      await pump(tester, at: AppRoutes.staffBillingPlans, checkoutEnabled: true);

      await tester.tap(find.text('Choose yearly').last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppButton, 'Continue to payment'), findsOneWidget);
      expect(find.text('Ask for this change'), findsNothing);
    });

    testWidgets('choosing one previews it first, and asks only once confirmed', (tester) async {
      routed(
        _billing('active'),
        posts: {
          '/tenant/subscription/preview': (200, fixture('staff/subscription-preview-upgrade.json')),
          '/tenant/subscription/change': (201, _quotedChange),
        },
      );
      await pump(tester, at: AppRoutes.staffBillingPlans);

      await tester.tap(find.text('Choose yearly').last);
      await tester.pumpAndSettle();

      // The academy's preview: credit, charge, tax and total, all its own figures.
      expect(find.text('Move to Enterprise'), findsOneWidget);
      expect(find.text('₹39,899.95'), findsOneWidget);
      expect(find.text('₹49,999.93'), findsOneWidget);
      expect(find.text('₹8,999.99'), findsOneWidget);
      expect(find.text('₹58,999.92'), findsOneWidget);
      expect(find.text('It applies as soon as it is paid.'), findsOneWidget);
      expect(writes().map((r) => r.path), ['/tenant/subscription/preview']);
      expect((writes().single.data! as Map).keys.toSet(), {'planId', 'cycle'});

      await tester.tap(find.text('Ask for this change'));
      await tester.pumpAndSettle();

      final change = writes().last;
      expect(change.path, '/tenant/subscription/change');
      expect((change.data! as Map).keys.toSet(), {'planId', 'cycle'});
      expect(find.text('This change has been quoted.'), findsOneWidget);
      // Checkout is off in this build, so nothing went on to a payment.
      expect(writes().where((r) => r.path.contains('checkout')), isEmpty);
    });

    testWidgets('a downgrade says when it applies and which limits are already over', (
      tester,
    ) async {
      routed(
        _billing('active'),
        posts: {
          '/tenant/subscription/preview': (
            200,
            fixture('staff/subscription-preview-downgrade.json'),
          ),
        },
      );
      await pump(tester, at: AppRoutes.staffBillingPlans);

      await tester.tap(find.text('Choose monthly').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('It applies on 30 Sep 2027'), findsOneWidget);
      expect(find.text('Already over the new plan’s limits'), findsOneWidget);
      expect(find.textContaining('Courses: you use 12, the new plan allows 10'), findsOneWidget);
      expect(find.text('Ask for this change'), findsOneWidget);
    });

    testWidgets('a charged change with no billing address asks for one before anything else', (
      tester,
    ) async {
      final preview = fixture('staff/subscription-preview-upgrade.json')! as Map<String, dynamic>;
      routed(
        _billing('active'),
        posts: {
          '/tenant/subscription/preview': (
            200,
            {...preview, 'payable': null, 'needsBillingAddress': true},
          ),
        },
      );
      await pump(tester, at: AppRoutes.staffBillingPlans);

      await tester.tap(find.text('Choose yearly').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('its tax depends on the LMS’s billing address'), findsOne);
      expect(find.text('Add billing details'), findsOneWidget);
      expect(find.text('Ask for this change'), findsNothing, reason: 'not before the address');

      await tester.tap(find.text('Add billing details'));
      await tester.pumpAndSettle();
      expect(find.text('Billing details'), findsOneWidget);
    });

    testWidgets('the plan the academy is on is offered only billed the other way', (tester) async {
      answering(_billing('active'));
      await pump(tester, at: AppRoutes.staffBillingPlans);

      // Growth, billed yearly now: moving to monthly is a change; yearly again is not.
      final growth = find.ancestor(of: find.text('Growth'), matching: find.byType(PlanOfferCard));
      expect(find.descendant(of: growth, matching: find.text('Choose monthly')), findsOneWidget);
      expect(find.descendant(of: growth, matching: find.text('Choose yearly')), findsNothing);
    });

    testWidgets('an admin who may only read is offered no choice', (tester) async {
      answering(_billing('active'));
      await pump(tester, at: AppRoutes.staffBillingPlans, signedInAs: _readOnlyAdmin());

      expect(find.text('Choose yearly'), findsNothing);
      expect(find.text('Choose monthly'), findsNothing);
    });
  });

  group('on a free trial (D33)', () {
    Map<String, dynamic> trial({bool gateway = true}) {
      final b = {..._billing('active'), 'checkoutAvailable': gateway};
      b['subscription'] = {...(b['subscription'] as Map<String, dynamic>), 'status': 'trial'};
      return b;
    }

    testWidgets('billing leads with upgrading to a paid plan where the app can take payment', (
      tester,
    ) async {
      answering(trial());
      await pump(tester, at: AppRoutes.staffBilling, checkoutEnabled: true);

      final upgrade = find.widgetWithText(AppButton, 'Upgrade to a paid plan');
      expect(upgrade, findsOneWidget);
      expect(tester.widget<AppButton>(upgrade).variant, AppButtonVariant.primary);
      expect(find.widgetWithText(AppButton, 'Change plan'), findsNothing);
    });

    testWidgets('with no gateway it offers no purchase and says why', (tester) async {
      answering(trial(gateway: false));
      await pump(tester, at: AppRoutes.staffBilling, checkoutEnabled: true);

      expect(find.widgetWithText(AppButton, 'Upgrade to a paid plan'), findsNothing);
      expect(find.textContaining('Online payment isn’t available yet'), findsOneWidget);
    });
  });

  group('a first subscription', () {
    Map<String, dynamic> withGateway() => {..._billing('none'), 'checkoutAvailable': true};

    testWidgets('an academy with no plan is offered to subscribe, not to change plan', (
      tester,
    ) async {
      answering(withGateway());
      await pump(tester, at: AppRoutes.staffBillingPlans, checkoutEnabled: true);

      expect(find.text('Subscribe yearly'), findsWidgets);
      expect(find.text('Subscribe monthly'), findsWidgets);
      expect(find.text('Choose yearly'), findsNothing);
      expect(find.text('Your plan'), findsNothing);
    });

    testWidgets('without a gateway the academy would only refuse it, so nothing is offered', (
      tester,
    ) async {
      answering(_billing('none'));
      await pump(tester, at: AppRoutes.staffBillingPlans);

      expect(find.text('Subscribe yearly'), findsNothing);
      expect(find.text('Choose yearly'), findsNothing);
      expect(find.textContaining('Online payment isn’t available yet'), findsOneWidget);
    });

    testWidgets('asks for billing details first; with no gateway SDK to run, the invoice waits', (
      tester,
    ) async {
      routed(
        withGateway(),
        profile: null,
        posts: {'/tenant/billing/purchase': (201, _checkoutStart())},
      );
      await pump(tester, at: AppRoutes.staffBillingPlans, checkoutEnabled: true);

      await tester.tap(find.text('Subscribe yearly').first);
      await tester.pumpAndSettle();

      expect(find.text('Billing details'), findsOneWidget);
      // The form checks what the academy will, before sending anything.
      await tester.tap(find.text('Save billing details'));
      await tester.pumpAndSettle();
      expect(find.text('Give the name the LMS bills under.'), findsOneWidget);
      expect(writes(), isEmpty);

      await tester.enterText(_field(tester, 'Name to bill'), 'ZuviloAI Academy');
      await tester.enterText(_field(tester, 'Email for invoices'), 'billing@example.test');
      await tester.enterText(_field(tester, 'Street address'), '4th Cross, Jayanagar');
      await tester.enterText(_field(tester, 'City'), 'Bengaluru');
      await tester.enterText(_field(tester, 'Region code'), 'KA');
      await tester.enterText(_field(tester, 'Postal code'), '560041');
      await tester.tap(find.text('Save billing details'));
      await tester.pumpAndSettle();

      final put = writes().first;
      expect(put.method, 'PUT');
      expect(put.path, '/tenant/billing-profile');
      expect((put.data! as Map)['country'], 'IN');

      final purchase = writes().last;
      expect(purchase.path, '/tenant/billing/purchase');
      expect((purchase.data! as Map).keys.toSet(), {'planId', 'cycle'});
      // Checkout is off in this build (C4): an honest answer, and no dead button.
      expect(
        find.text(
          'Your invoice INV-2026-0148 for ₹58,999.92 is ready. Online payment isn’t available '
          'right now, so it stays open until it is.',
        ),
        findsOneWidget,
      );
      expect(find.text('Pay this invoice'), findsNothing);
    });

    testWidgets('with billing details in place, it goes straight to the purchase', (tester) async {
      routed(withGateway(), posts: {'/tenant/billing/purchase': (201, _checkoutStart())});
      await pump(tester, at: AppRoutes.staffBillingPlans, checkoutEnabled: true);

      await tester.tap(find.text('Subscribe monthly').first);
      await tester.pumpAndSettle();

      expect(find.text('Billing details'), findsNothing);
      expect(writes().single.path, '/tenant/billing/purchase');
      expect((writes().single.data! as Map)['cycle'], 'monthly');
      expect(find.text('Your invoice is ready'), findsOneWidget);
    });

    testWidgets('a build that takes payments opens the academy\'s payment page', (tester) async {
      final opened = <Uri>[];
      routed(
        withGateway(),
        posts: {
          '/tenant/billing/purchase': (
            201,
            _checkoutStart(provider: 'vyapar', redirectUrl: 'https://pay.example.test/order_ABC'),
          ),
        },
      );
      await pump(
        tester,
        at: AppRoutes.staffBillingPlans,
        checkoutEnabled: true,
        openExternalLink: (link) async => opened.add(link),
      );

      await tester.tap(find.text('Subscribe yearly').first);
      await tester.pumpAndSettle();

      expect(opened.single.toString(), 'https://pay.example.test/order_ABC');
      expect(find.text('Finish paying on the payment page'), findsOneWidget);
    });
    testWidgets('nothing is offered where this build takes no payments, and it says so', (
      tester,
    ) async {
      answering(withGateway());
      await pump(tester, at: AppRoutes.staffBillingPlans);

      expect(find.text('Subscribe yearly'), findsNothing);
      expect(find.textContaining('Online payment isn’t available yet'), findsOneWidget);
      expect(find.textContaining('web'), findsNothing, reason: 'never sent to the website to pay');
    });

    testWidgets('an academy on a free trial buys a plan rather than changing one (D33)', (
      tester,
    ) async {
      final trial = {..._billing('active'), 'checkoutAvailable': true};
      trial['subscription'] = {
        ...(trial['subscription'] as Map<String, dynamic>),
        'status': 'trial',
      };
      answering(trial);
      await pump(tester, at: AppRoutes.staffBillingPlans, checkoutEnabled: true);

      expect(find.text('Subscribe monthly'), findsWidgets);
      expect(find.text('Choose monthly'), findsNothing);
    });

    testWidgets(
      'Razorpay runs in the app; the academy confirms the payment and the plan is re-read',
      (tester) async {
        final launched = <CheckoutParams>[];
        routed(
          withGateway(),
          posts: {
            '/tenant/billing/purchase': (201, _checkoutStart()),
            '/tenant/billing/checkout/confirm': (
              200,
              const {
                'status': 'paid',
                'settled': true,
                'applied': true,
                'message': 'Paid. The subscription is active.',
              },
            ),
          },
        );
        await pump(
          tester,
          at: AppRoutes.staffBillingPlans,
          checkoutEnabled: true,
          checkoutRunner: (params) async {
            launched.add(params);
            return const GatewayCompleted(
              orderId: 'order_ABC',
              paymentId: 'pay_1',
              signature: 'sig_1',
            );
          },
        );

        await tester.tap(find.text('Subscribe yearly').first);
        await tester.pumpAndSettle();

        expect(
          launched.single,
          isA<CheckoutParams>().having((p) => p.keyId, 'keyId', 'rzp_test_public'),
        );
        final confirm = adapter.requests.singleWhere(
          (r) => r.path == '/tenant/billing/checkout/confirm',
        );
        // Only the gateway's proof is sent: no tenant, price, plan or status from the app.
        expect(confirm.data, {'orderId': 'order_ABC', 'paymentId': 'pay_1', 'signature': 'sig_1'});
        expect(find.text('Paid. The subscription is active.'), findsOneWidget);
        expect(
          adapter.requests.where((r) => r.method == 'GET' && r.path == '/tenant/billing').length,
          greaterThan(1),
          reason: 'the page is read again after the academy confirms',
        );
      },
    );
  });

  group('paying what is owed', () {
    Map<String, dynamic> owing() => {
      ..._billing('active'),
      'checkoutAvailable': true,
      'invoices': [_invoiceJson(status: 'pending')],
    };

    testWidgets('as shipped, an open invoice is paid from the web dashboard', (tester) async {
      answering(owing());
      await pump(tester, at: AppRoutes.staffBilling);

      expect(find.textContaining('Online payment isn’t available right now'), findsOneWidget);
      expect(find.text('Pay this invoice'), findsNothing);
    });

    testWidgets('as shipped, the invoice itself says so too', (tester) async {
      answering(_invoiceJson(status: 'pending'));
      await pump(tester, at: AppRoutes.staffInvoice('inv_1'));

      expect(find.text('Online payment isn’t available right now'), findsOneWidget);
      expect(find.text('Pay this invoice'), findsNothing);
    });

    testWidgets('a build that takes payments pays an open invoice on the academy\'s page', (
      tester,
    ) async {
      final opened = <Uri>[];
      adapter.handler = (options) async {
        if (options.method == 'GET') {
          return FakeAdapter.jsonResponse(
            options.path == '/tenant/billing' ? owing() : _invoiceJson(status: 'pending'),
          );
        }
        return FakeAdapter.jsonResponse(
          _checkoutStart(provider: 'vyapar', redirectUrl: 'https://pay.example.test/order_ABC'),
          status: 201,
        );
      };
      await pump(
        tester,
        at: AppRoutes.staffInvoice('inv_1'),
        checkoutEnabled: true,
        openExternalLink: (link) async => opened.add(link),
      );

      await tester.tap(find.text('Pay this invoice'));
      await tester.pumpAndSettle();

      expect(writes().single.path, '/tenant/billing/checkout');
      expect(writes().single.data, {'invoiceId': 'inv_1'});
      expect(opened.single.host, 'pay.example.test');
    });

    testWidgets('a quoted upgrade is paid on the web as shipped', (tester) async {
      answering({..._billing('change'), 'checkoutAvailable': true});
      await pump(tester, at: AppRoutes.staffBilling);

      expect(find.text('Online payment isn’t available right now'), findsOneWidget);
      expect(find.text('Pay for this upgrade'), findsNothing);
    });
  });

  group('resuming', () {
    Map<String, dynamic> canceling() {
      final billing = _billing('active');
      return {
        ...billing,
        'subscription': {...billing['subscription'] as Map<String, dynamic>, 'status': 'canceling'},
      };
    }

    testWidgets('a pause the platform holds is refused in the academy\'s own words', (
      tester,
    ) async {
      answering(
        canceling(),
        write: const {
          'message':
              'This subscription was paused by the platform team. It resumes on its planned '
              'date, or when they end the pause.',
        },
        writeStatus: 403,
      );
      await pump(tester, at: AppRoutes.staffBilling);

      await tester.tap(find.text('Resume the plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Resume the plan').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('paused by the platform team'), findsOneWidget);
    });

    testWidgets('a withdrawn cancellation reads the raw record without failing', (tester) async {
      answering(canceling(), write: fixture('staff/subscription-record.json'));
      await pump(tester, at: AppRoutes.staffBilling);

      await tester.tap(find.text('Resume the plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Resume the plan').last);
      await tester.pumpAndSettle();

      expect(find.text('Your plan is running again.'), findsOneWidget);
    });
  });

  group('an invoice', () {
    Map<String, dynamic> invoice({String status = 'paid'}) => _invoiceJson(status: status);

    testWidgets('shows the figures the academy fixed, not a sum of its own', (tester) async {
      answering(invoice());
      await pump(tester, at: AppRoutes.staffInvoice('inv_1'));

      expect(find.textContaining('INV-2026-0148'), findsWidgets);
      expect(find.text('₹39,990.00'), findsWidgets);
      expect(find.text('₹7,198.20'), findsOneWidget);
      expect(find.text('₹47,188.20'), findsOneWidget);
      expect(find.text('Paid'), findsWidgets);
    });

    testWidgets('shows who it was billed to and how it was paid', (tester) async {
      answering(invoice());
      await pump(tester, at: AppRoutes.staffInvoice('inv_1'));

      expect(find.textContaining('Visa •••• 4242'), findsOneWidget);
      expect(find.text('Billed to'), findsOneWidget);
      expect(find.textContaining('Bengaluru, KA 560041'), findsOneWidget);
    });

    testWidgets('an open invoice reads as open, with no paid date', (tester) async {
      answering(invoice(status: 'pending'));
      await pump(tester, at: AppRoutes.staffInvoice('inv_1'));

      expect(find.text('Open'), findsWidgets);
      expect(find.textContaining('Paid 1 Sep'), findsNothing);
    });
  });
}

/// An [AppTextField] carries its label in the decoration, and `required: true` appends " · Required"
/// to what is drawn — so the field is found by the label it was given.
Finder _field(WidgetTester tester, String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is AppTextField && w.label == label),
  matching: find.byType(TextField),
);
