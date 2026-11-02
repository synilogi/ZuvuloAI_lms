import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/entitlements/academy_plan_provider.dart';
import '../../../shared/session/current_user.dart';
import '../data/dto/billing.dart';
import '../data/pending_payment_store.dart';
import '../data/razorpay_checkout.dart';
import '../data/staff_billing_api.dart';
import 'checkout_launcher.dart';

/// What the billing screens read (§26).
export '../data/dto/billing.dart';
export 'checkout_launcher.dart';

final tenantBillingProvider = FutureProvider<TenantBilling>((ref) async {
  // A payment the gateway reported but the academy never confirmed (the app was closed in between)
  // is confirmed first, so the page shows what was paid rather than asking for it again.
  await ref.watch(pendingPaymentRecoveryProvider.future);
  return ref.watch(staffBillingApiProvider).billing();
}, isAutoDispose: true);

/// Confirms a [PendingPayment] left by an interrupted checkout, once, for the person who made it.
/// The academy verifies it as it verifies any confirmation; whatever it answers short of "still with
/// the bank" ends the wait. Never fails: the academy's webhook settles the payment regardless.
final pendingPaymentRecoveryProvider = FutureProvider<bool>((ref) async {
  final store = ref.watch(pendingPaymentStoreProvider);
  final user = ref.watch(currentUserProvider);
  final pending = await store.read();
  if (pending == null || user == null || pending.userId != user.id) return false;
  try {
    final outcome = await ref
        .read(staffBillingApiProvider)
        .confirm(
          orderId: pending.orderId,
          paymentId: pending.paymentId,
          signature: pending.signature,
        );
    if (outcome.isPending) return false;
    await store.clear();
    // The shell's plan (banner, locked modules) may have moved too; it is re-read once this settles.
    unawaited(
      Future(() {
        if (ref.mounted) ref.invalidate(academyPlanProvider);
      }),
    );
    return outcome.applied || outcome.settled;
  } on ApiException catch (e) {
    // Offline or the server erred: try again next time. Refused (not this academy's, not genuine): drop it.
    if (e.failure is! NetworkFailure && e.failure is! ServerFailure) await store.clear();
    return false;
  }
}, isAutoDispose: true);

final tenantInvoiceProvider = FutureProvider.family<InvoiceView, String>(
  (ref, idOrNumber) => ref.watch(staffBillingApiProvider).invoice(idOrNumber),
  isAutoDispose: true,
);

/// A plan and a cycle the academy could move to — the key a preview is read by.
typedef PlanChoice = ({String planId, BillingCycle cycle});

/// What moving to a plan and cycle would do, as the academy previews it. Reading it writes nothing,
/// so an admin who may only read billing can see it too.
final planChangePreviewProvider = FutureProvider.family<PlanChangePreview, PlanChoice>(
  (ref, choice) =>
      ref.watch(staffBillingApiProvider).previewChange(planId: choice.planId, cycle: choice.cycle),
  isAutoDispose: true,
);

/// The gateway SDK this build runs: Razorpay Checkout, in a build that takes payments. `null` in a
/// build that does not ([checkoutEnabledProvider]); a test provides its own to prove what happens
/// with the result. The payer's name and email only prefill the form.
final nativeCheckoutRunnerProvider = Provider<NativeCheckoutRunner?>((ref) {
  if (!ref.watch(checkoutEnabledProvider)) return null;
  final user = ref.watch(currentUserProvider);
  final checkout = RazorpayCheckout();
  return (params) =>
      checkout.run(params, payer: user == null ? null : (name: user.name, email: user.email));
});

/// Whether this build takes payments in the app (`BILLING_CHECKOUT_ENABLED`). It is the build's
/// switch only: a payment control also needs the academy to have a gateway connected
/// ([mayPayInApp]) and the admin to be allowed to change billing. Off, the screens read, quote and
/// say payment is not available — whether a store listing may take payments in the app is a
/// store-policy decision (C4).
final checkoutEnabledProvider = Provider<bool>(
  (ref) => ref.watch(appConfigProvider).billingCheckoutEnabled,
);

/// Whether a payment control may be shown: this build offers one **and** the academy has a gateway
/// connected. Both have to be true, and the academy's word is the second one.
bool mayPayInApp({required bool enabledInBuild, required TenantBilling billing}) =>
    enabledInBuild && billing.checkoutAvailable;

/// How far a checkout has got. The app never decides that a payment succeeded — [outcome] is the
/// academy's answer, and the plan only reads as active after `/tenant/billing` has been read again.
enum CheckoutStage {
  idle,

  /// Asking the academy to open an order.
  starting,

  /// With the gateway, or on its page.
  atGateway,

  /// Handing the provider's result back to the academy.
  confirming,

  /// The academy says the bank has not settled it yet; asking again.
  waiting,

  /// The academy settled it. What changed is in the re-read, not here.
  settled,

  /// Nothing was paid, and nothing changed.
  notCompleted,
}

@immutable
class BillingActionState {
  const BillingActionState({
    this.busy = false,
    this.stage = CheckoutStage.idle,
    this.start,
    this.plan,
    this.outcome,
    this.quote,
    this.done = false,
    this.failure,
  });

  final bool busy;
  final CheckoutStage stage;

  /// The order the academy opened, while it is in flight.
  final CheckoutStart? start;

  /// How this device can carry that checkout out.
  final CheckoutPlan? plan;

  /// The academy's own verdict on the payment.
  final CheckoutOutcome? outcome;

  /// What a plan change would cost, as the academy quoted it.
  final PlanChangeStart? quote;

  /// A write the academy carried out (a cancellation, a resume, a change asked for).
  final bool done;
  final AppFailure? failure;

  BillingActionState copyWith({
    bool? busy,
    CheckoutStage? stage,
    CheckoutStart? start,
    CheckoutPlan? plan,
    CheckoutOutcome? outcome,
    PlanChangeStart? quote,
    bool? done,
    AppFailure? failure,
  }) => BillingActionState(
    busy: busy ?? this.busy,
    stage: stage ?? this.stage,
    start: start ?? this.start,
    plan: plan ?? this.plan,
    outcome: outcome ?? this.outcome,
    quote: quote ?? this.quote,
    done: done ?? this.done,
    failure: failure ?? this.failure,
  );
}

/// Subscribing, changing plan, paying, cancelling and resuming. Every refusal and every figure is the
/// academy's; the app sends only what §18 allows it to, and re-reads `/tenant/billing` after anything
/// that could have moved the subscription.
class BillingActionController extends Notifier<BillingActionState> {
  @override
  BillingActionState build() => const BillingActionState();

  void clearAnswer() => state = const BillingActionState();

  /// Asks the academy to quote a plan change. An upgrade comes back waiting for its payment.
  Future<PlanChangeStart?> changePlan({required String planId, required BillingCycle cycle}) async {
    if (state.busy) return null;
    state = const BillingActionState(busy: true);
    try {
      final quote = await ref
          .read(staffBillingApiProvider)
          .changePlan(planId: planId, cycle: cycle);
      if (!ref.mounted) return quote;
      state = BillingActionState(quote: quote, done: true);
      _reread();
      return quote;
    } on ApiException catch (e) {
      if (!ref.mounted) return null;
      state = BillingActionState(failure: e.failure);
      return null;
    }
  }

  Future<bool> cancelPlanChange(String planChangeId, {String? reason}) => _write(
    () => ref.read(staffBillingApiProvider).cancelPlanChange(planChangeId, reason: reason),
  );

  /// Cancels at the end of the period. The reason reaches the academy's record, and the screen will
  /// not send one it knows is too short.
  Future<bool> cancelSubscription({required String reason}) {
    if (!cancelReasonIsEnough(reason)) return Future.value(false);
    return _write(() => ref.read(staffBillingApiProvider).cancelSubscription(reason: reason));
  }

  Future<bool> resumeSubscription({String? reason}) =>
      _write(() => ref.read(staffBillingApiProvider).resumeSubscription(reason: reason));

  Future<bool> _write(Future<void> Function() action) async {
    if (state.busy) return false;
    state = const BillingActionState(busy: true);
    try {
      await action();
      if (!ref.mounted) return true;
      state = const BillingActionState(done: true);
      // The answer is not read: what changed is what the academy says when it is asked again.
      _reread();
      return true;
    } on ApiException catch (e) {
      if (!ref.mounted) return false;
      state = BillingActionState(failure: e.failure);
      return false;
    }
  }

  /// Opens an order for a first subscription. What it does **not** send: an amount, a price, a tenant
  /// or a status. It answers with how this device can carry the checkout out — which, in a build
  /// carrying no payment SDK, is the academy's own page or nothing at all.
  Future<CheckoutPlan?> startPurchase({required String planId, required BillingCycle cycle}) =>
      _startCheckout(
        () => ref.read(staffBillingApiProvider).purchase(planId: planId, cycle: cycle),
      );

  Future<CheckoutPlan?> startInvoicePayment(String invoiceId) =>
      _startCheckout(() => ref.read(staffBillingApiProvider).checkoutInvoice(invoiceId));

  Future<CheckoutPlan?> startPlanChangePayment(String planChangeId) =>
      _startCheckout(() => ref.read(staffBillingApiProvider).checkoutPlanChange(planChangeId));

  Future<CheckoutPlan?> _startCheckout(Future<CheckoutStart> Function() open) async {
    if (state.busy) return null;
    state = const BillingActionState(busy: true, stage: CheckoutStage.starting);
    try {
      final start = await open();
      if (!ref.mounted) return null;
      final plan = planCheckout(start.checkout);
      state = BillingActionState(stage: CheckoutStage.atGateway, start: start, plan: plan);
      return plan;
    } on ApiException catch (e) {
      if (!ref.mounted) return null;
      state = BillingActionState(stage: CheckoutStage.idle, failure: e.failure);
      return null;
    }
  }

  /// Hands the provider's result back to the academy. While the academy says the bank has not settled
  /// it, the app asks again — and it never flips anything to active by itself.
  Future<CheckoutOutcome?> confirm({
    required String orderId,
    required String paymentId,
    required String signature,
    Duration interval = checkoutPollInterval,
    int attempts = checkoutPollAttempts,
  }) async {
    if (state.busy) return null;
    state = state.copyWith(busy: true, stage: CheckoutStage.confirming);
    final api = ref.read(staffBillingApiProvider);
    // Kept until the academy answers for good, so a payment survives the app being closed now.
    final store = ref.read(pendingPaymentStoreProvider);
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await store.write((
        userId: user.id,
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      ));
    }
    try {
      var outcome = await api.confirm(orderId: orderId, paymentId: paymentId, signature: signature);
      var left = attempts;
      while (outcome.isPending && left > 0) {
        if (!ref.mounted) return outcome;
        state = state.copyWith(stage: CheckoutStage.waiting, outcome: outcome);
        await Future<void>.delayed(interval);
        if (!ref.mounted) return outcome;
        outcome = await api.confirm(orderId: orderId, paymentId: paymentId, signature: signature);
        left--;
      }
      if (!outcome.isPending) await store.clear();
      if (!ref.mounted) return outcome;
      state = BillingActionState(
        stage: outcome.settled ? CheckoutStage.settled : CheckoutStage.waiting,
        outcome: outcome,
        done: outcome.settled,
      );
      // Whether the plan moved is what the academy says next, not what the SDK said.
      _reread();
      return outcome;
    } on ApiException catch (e) {
      // Refused for good: nothing to retry. Offline or a server error: the next billing visit retries.
      if (e.failure is! NetworkFailure && e.failure is! ServerFailure) await store.clear();
      if (!ref.mounted) return null;
      state = BillingActionState(stage: CheckoutStage.notCompleted, failure: e.failure);
      return null;
    }
  }

  /// Where the academy's invoices are addressed — `details` `null` when it has not said yet — or
  /// why it could not be read, for the caller to show.
  Future<({BillingDetails? details, AppFailure? failure})> readBillingDetails() async {
    try {
      return (details: await ref.read(staffBillingApiProvider).billingProfile(), failure: null);
    } on ApiException catch (e) {
      return (details: null, failure: e.failure);
    }
  }

  /// Saves the academy's billing details. Answers with the academy's refusal, or `null` once it has
  /// stored them; a form shows the refusal beside its fields rather than as a passing message.
  Future<AppFailure?> saveBillingDetails(BillingDetails details) async {
    try {
      await ref.read(staffBillingApiProvider).saveBillingProfile(details);
      // A preview's tax depends on the address, so any preview already read is out of date.
      if (ref.mounted) ref.invalidate(planChangePreviewProvider);
      return null;
    } on ApiException catch (e) {
      return e.failure;
    }
  }

  /// Everything a billing write can move: the page, and the plan the shell reads for its banner.
  void _reread() {
    ref
      ..invalidate(tenantBillingProvider)
      ..invalidate(academyPlanProvider);
  }

  /// The academy was not paid: nothing changed, and the screen says so.
  void paymentNotCompleted() {
    if (!ref.mounted) return;
    state = const BillingActionState(stage: CheckoutStage.notCompleted);
  }
}

final billingActionProvider = NotifierProvider<BillingActionController, BillingActionState>(
  BillingActionController.new,
  isAutoDispose: true,
);
