import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/core/network/token_store.dart';
import 'package:syniastrolms_mobile/features/staff_billing/staff_billing.dart';
import 'package:syniastrolms_mobile/shared/entitlements/entitlements.dart';

/// The academy's own subscription against the **real** API on the scratch database (FLUTTER-027).
/// Read-only apart from one plan change, which is quoted and then given up, so the run leaves the
/// academy exactly as it found it. No payment is attempted: the local server has no gateway, which is
/// itself one of the things asserted here.
const _password = 'syniastrolms123';
const _admin = 'admin@syniastrolms.test';
const _instructor = 'meenakshi@syniastrolms.test';
const _learner = 'ananya@syniastrolms.test';

class _Token implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppConfig config;
  final clients = <String, ApiClient>{};

  ApiClient clientFor(TokenStore store) => ApiClient(
    config: config,
    tokenStore: store,
    logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
    logRequests: false,
  );

  Future<ApiClient> signIn(String email) async {
    final cached = clients[email];
    if (cached != null) return cached;
    final store = _Token();
    final body = await clientFor(
      _Token(),
    ).post('/auth/login', body: {'email': email, 'password': _password});
    store.token = (body! as Map)['token'] as String;
    return clients[email] = clientFor(store);
  }

  setUpAll(() => config = AppConfig.fromEnvironment(Flavor.dev));

  testWidgets('the billing page is the academy\'s own account of itself', (tester) async {
    final billing = await StaffBillingApi(await signIn(_admin)).billing();

    expect(billing.academy.name, isNotEmpty);
    expect(billing.usage, isNotEmpty);
    expect(billing.features, isNotEmpty);
    expect(billing.plans, isNotEmpty);
    for (final feature in billing.features) {
      expect(feature.key, isNotEmpty);
      expect(feature.label, isNotEmpty);
      expect(feature.enforcement, isNot(FeatureEnforcement.unknown));
    }
  });

  testWidgets('a limit with a ceiling reports what is left, and one without says so', (
    tester,
  ) async {
    final billing = await StaffBillingApi(await signIn(_admin)).billing();

    for (final line in billing.usage) {
      expect(line.label, isNotEmpty);
      if (line.isUnlimited) {
        // Nothing to be a share of, so nothing is drawn as one.
        expect(line.share, isNull);
        expect(line.remaining, isNull);
      } else {
        // The academy did this subtraction, not the app — and it does not let the answer go
        // negative: an academy over its ceiling has nothing left, not minus sixty.
        expect(line.remaining, isNotNull);
        expect(line.remaining, greaterThanOrEqualTo(0));
        expect(line.remaining, line.allowed! - line.used > 0 ? line.allowed! - line.used : 0);
        expect(line.isFull, line.remaining == 0);
      }
    }
  });

  testWidgets('every plan on sale carries its own prices, cycles and limits', (tester) async {
    final billing = await StaffBillingApi(await signIn(_admin)).billing();

    for (final plan in billing.plans) {
      expect(plan.id, isNotEmpty);
      expect(plan.name, isNotEmpty);
      expect(plan.currency, isNotEmpty);
      expect(plan.cycles, isNotEmpty);
      expect(plan.limits, isNotEmpty);
      // Minor units, always: a price is an integer the academy fixed.
      expect(plan.priceFor(BillingCycle.monthly), greaterThanOrEqualTo(0));
      expect(plan.priceFor(BillingCycle.annual), greaterThanOrEqualTo(0));
    }
  });

  testWidgets('the plans route answers with the same plans as the billing page', (tester) async {
    final api = StaffBillingApi(await signIn(_admin));

    final billing = await api.billing();
    final plans = await api.plans();

    expect(
      plans.map((p) => p.id).toSet().containsAll(billing.plans.map((p) => p.id)),
      isTrue,
      reason: 'the fallback read serves at least what the page does',
    );
  });

  testWidgets('online payment is not available, and the academy says so itself', (tester) async {
    final billing = await StaffBillingApi(await signIn(_admin)).billing();

    // No gateway is configured on the local server, so nothing may offer to take money — and this is
    // the academy's word for it, not a guess by the app.
    expect(billing.checkoutAvailable, isFalse);
    expect(mayPayInApp(enabledInBuild: true, billing: billing), isFalse);
    expect(
      config.billingCheckoutEnabled,
      isFalse,
      reason: 'the dev flavour does not offer in-app payment either (C4)',
    );
  });

  testWidgets('a checkout is refused before anything is issued, with the academy\'s words', (
    tester,
  ) async {
    final api = StaffBillingApi(await signIn(_admin));
    final billing = await api.billing();
    final plan = billing.plans.firstWhere((p) => p.status == 'active');

    await expectLater(
      api.purchase(planId: plan.id, cycle: BillingCycle.annual),
      throwsA(isA<ApiException>()),
      reason: 'no gateway, and — on this academy — a subscription already exists',
    );
  });

  /// Whether the academy has a plan it is actually running on. A cancelled or expired subscription is
  /// still *there* — the academy keeps the record — but there is nothing to change.
  bool isLive(TenantBilling billing) => switch (billing.subscription?.status) {
    SubscriptionStatus.active || SubscriptionStatus.trial || SubscriptionStatus.pastDue => true,
    _ => false,
  };

  testWidgets('an academy with no plan running cannot change plan, and is told why', (
    tester,
  ) async {
    final api = StaffBillingApi(await signIn(_admin));
    final billing = await api.billing();
    if (isLive(billing)) return;

    final plan = billing.plans.firstWhere((p) => p.status == 'active');
    await expectLater(
      api.changePlan(planId: plan.id, cycle: BillingCycle.annual),
      throwsA(
        isA<ApiException>().having(
          (e) => (e.failure as ConflictFailure).message,
          'the academy\'s words',
          contains('no active subscription'),
        ),
      ),
    );
  });

  testWidgets('a plan change is quoted by the academy, then given up', (tester) async {
    final api = StaffBillingApi(await signIn(_admin));
    final billing = await api.billing();
    // Only an academy actually running on a plan has one to change.
    if (!isLive(billing)) return;
    final target = billing.plans
        .where((p) => p.status == 'active' && p.id != billing.plan?.id)
        .toList();
    if (target.isEmpty) return;

    final quote = await api.changePlan(planId: target.last.id, cycle: BillingCycle.annual);
    try {
      expect(quote.change.id, isNotEmpty);
      expect(quote.change.toPlanName, isNotEmpty);
      expect(quote.change.quotedAt.isUtc, isTrue);
      // Every figure is the academy's, including the tax it worked out.
      if (quote.payable case final payable?) {
        expect(payable.gross, greaterThan(0));
        expect(payable.currency, isNotEmpty);
        for (final line in payable.lines) {
          expect(line.label, isNotEmpty);
        }
      }

      // The page now says a change is waiting.
      final withChange = await api.billing();
      expect(withChange.openChange, isNotNull);
      expect(withChange.openChange!.id, quote.change.id);
    } finally {
      await api.cancelPlanChange(quote.change.id, reason: 'Contract check finished.');
    }

    expect((await api.billing()).openChange, isNull, reason: 'given up, and nothing changed');
  });

  testWidgets('a preview of a change writes nothing, and the page is left as it was', (
    tester,
  ) async {
    final api = StaffBillingApi(await signIn(_admin));
    final billing = await api.billing();
    if (!isLive(billing) || billing.subscription!.isTrial || billing.openChange != null) return;
    final target = billing.plans
        .where((p) => p.status == 'active' && p.id != billing.plan?.id)
        .toList();
    if (target.isEmpty) return;

    final preview = await api.previewChange(planId: target.last.id, cycle: BillingCycle.annual);

    expect(preview.kind, isNot(PlanChangeKind.unknown));
    expect(preview.to.planId, target.last.id);
    expect(preview.appliesAt.isUtc, isTrue);
    if (preview.payable case final payable?) expect(payable.gross, greaterThan(0));
    expect((await api.billing()).openChange, isNull, reason: 'a preview asks for nothing');
  });

  testWidgets('billing details are the academy\'s, or none yet', (tester) async {
    final details = await StaffBillingApi(await signIn(_admin)).billingProfile();

    if (details != null) {
      expect(details.legalName, isNotEmpty);
      expect(details.country, hasLength(2));
    }
  });

  testWidgets('a cancellation reason the academy will not take is refused', (tester) async {
    final api = StaffBillingApi(await signIn(_admin));

    expect(cancelReasonIsEnough('no'), isFalse);
    await expectLater(api.cancelSubscription(reason: 'no'), throwsA(isA<ApiException>()));
  });

  testWidgets('an invoice that does not exist is not found, rather than empty', (tester) async {
    await expectLater(
      StaffBillingApi(await signIn(_admin)).invoice('no-such-invoice'),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
    );
  });

  testWidgets('an instructor has no billing page, and neither has a learner', (tester) async {
    for (final email in [_instructor, _learner]) {
      await expectLater(
        StaffBillingApi(await signIn(email)).billing(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            anyOf(isA<ForbiddenFailure>(), isA<PermissionFailure>()),
          ),
        ),
        reason: email,
      );
    }
  });

  /* ── Plan-aware workspace and onboarding (2026-10-03) ───────────────── */

  testWidgets('every member of staff can read the academy plan, and a learner cannot', (
    tester,
  ) async {
    final asAdmin = await AcademyPlanApi(await signIn(_admin)).read();
    final asInstructor = await AcademyPlanApi(await signIn(_instructor)).read();

    // The same academy, the same answer, whoever of its staff asks.
    expect(asInstructor.enforced, asAdmin.enforced);
    expect(asInstructor.status, asAdmin.status);
    expect(asInstructor.features, asAdmin.features);
    // Every module reads one of the three ways, never by the plan's name.
    for (final module in WorkspaceModule.values) {
      expect(ModuleAccess.values, contains(moduleAccess(asAdmin, module)));
    }

    await expectLater(AcademyPlanApi(await signIn(_learner)).read(), throwsA(isA<ApiException>()));
  });

  testWidgets('the billing page says whether a free trial may start', (tester) async {
    final billing = await StaffBillingApi(await signIn(_admin)).billing();

    // Only an academy with no live subscription may; the seed's history decides which this is.
    if (billing.hasLiveSubscription) expect(billing.trialAvailable, isFalse);
  });

  testWidgets('a trial is refused to an instructor, and on a plan that does not exist', (
    tester,
  ) async {
    // Starting one is a one-way door for the academy, so only refusals are exercised here.
    await expectLater(
      StaffBillingApi(
        await signIn(_instructor),
      ).startTrial(planId: 'no-such-plan', cycle: BillingCycle.monthly),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          anyOf(isA<PermissionFailure>(), isA<ForbiddenFailure>()),
        ),
      ),
    );
    await expectLater(
      StaffBillingApi(
        await signIn(_admin),
      ).startTrial(planId: 'no-such-plan', cycle: BillingCycle.monthly),
      throwsA(isA<ApiException>()),
    );
  });
}
