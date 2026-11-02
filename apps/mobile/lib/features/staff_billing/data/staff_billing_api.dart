import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import 'dto/billing.dart';

/// `apps/api/src/routes/tenant.ts` and `lib/checkout.ts` — the academy's own subscription. Reading
/// needs `settings.view`; every write needs `settings.edit`, and the route refuses anyone else.
///
/// **What this service may send is a closed list.** A price, an amount, a tenant, a status and an
/// entitlement are the academy's to decide, so none of them is ever in a request body: a purchase
/// names a plan and a cycle, a checkout names one invoice or one plan change, and a confirmation
/// passes the provider's own result back unchanged (§18, §11). The service tests assert these bodies
/// key by key.
class StaffBillingApi {
  StaffBillingApi(this._client);

  final ApiClient _client;

  Future<TenantBilling> billing() async {
    const endpoint = 'GET /tenant/billing';
    final body = await _client.get('/tenant/billing');
    return parseResponse(endpoint, body, (b) => TenantBilling.fromJson(asJsonObject(endpoint, b)));
  }

  /// One invoice, by its id or its human-facing number.
  Future<InvoiceView> invoice(String idOrNumber) async {
    const endpoint = 'GET /tenant/billing/invoices/:idOrNumber';
    final body = await _client.get(
      ApiPath.of(['tenant', 'billing', 'invoices', ApiPath.id(idOrNumber)]),
    );
    return parseResponse(endpoint, body, (b) => InvoiceView.fromJson(asJsonObject(endpoint, b)));
  }

  /// The plans on sale, as a fallback for the plans screen when `/tenant/billing` was not read.
  /// `GET /tenant/plans` answers with `PlanRecord` rows — terms nested under `current`, ordered by
  /// `displayOrder` — which are read as the [PlanView]s the billing page serves, in the academy's order.
  Future<List<PlanView>> plans() async {
    const endpoint = 'GET /tenant/plans';
    final body = await _client.get('/tenant/plans');
    return parseResponse(endpoint, body, (b) {
      final rows = asJsonObject(endpoint, b)['rows'];
      return [
        for (final row in asJsonList(endpoint, rows))
          PlanView.fromPlanRecord(asJsonObject(endpoint, row)),
      ]..sort((a, b) => a.order.compareTo(b.order));
    });
  }

  /// Where the academy's invoices are addressed, or `null` when it has not said yet (404).
  Future<BillingDetails?> billingProfile() async {
    const endpoint = 'GET /tenant/billing-profile';
    try {
      final body = await _client.get('/tenant/billing-profile');
      return parseResponse(
        endpoint,
        body,
        (b) => BillingDetails.fromJson(asJsonObject(endpoint, b)),
      );
    } on ApiException catch (e) {
      if (e.failure is NotFoundFailure) return null;
      rethrow;
    }
  }

  /// Creates or replaces the academy's billing details. Only the address fields travel; the server
  /// checks them again and answers with what it stored.
  Future<BillingDetails> saveBillingProfile(BillingDetails details) async {
    const endpoint = 'PUT /tenant/billing-profile';
    final body = await _client.put('/tenant/billing-profile', body: details.toRequest());
    return parseResponse(endpoint, body, (b) => BillingDetails.fromJson(asJsonObject(endpoint, b)));
  }

  /// Subscribing for the first time. The body names **only** the plan and the cycle: the academy
  /// prices it, and sending an amount would be sending a price the client chose.
  Future<CheckoutStart> purchase({required String planId, required BillingCycle cycle}) async {
    const endpoint = 'POST /tenant/billing/purchase';
    final body = await _client.post(
      '/tenant/billing/purchase',
      body: {'planId': planId, 'cycle': cycle.wireName},
    );
    return parseResponse(endpoint, body, (b) => CheckoutStart.fromJson(asJsonObject(endpoint, b)));
  }

  /// Starts the plan's free trial for an academy with no live subscription — once per academy, on a
  /// plan that offers one, with no payment and no billing address. The body names **only** the plan
  /// and the cycle; the academy decides the trial's length, its end and whether it may start at all
  /// (409 `PLAN_UNAVAILABLE` for a plan without a trial, `INVALID_SUBSCRIPTION_STATE` once used).
  /// It takes no payment, so it is offered whatever this build's checkout setting is (C4 is about
  /// payments only).
  Future<StartedTrial> startTrial({required String planId, required BillingCycle cycle}) async {
    const endpoint = 'POST /tenant/billing/trial';
    final body = await _client.post(
      '/tenant/billing/trial',
      body: {'planId': planId, 'cycle': cycle.wireName},
    );
    return parseResponse(endpoint, body, (b) {
      final subscription = asJsonObject(endpoint, b)['subscription'];
      return StartedTrial.fromJson(asJsonObject(endpoint, subscription));
    });
  }

  /// Paying one open invoice.
  Future<CheckoutStart> checkoutInvoice(String invoiceId) =>
      _startCheckout({'invoiceId': invoiceId});

  /// Paying the upgrade the academy has already quoted.
  Future<CheckoutStart> checkoutPlanChange(String planChangeId) =>
      _startCheckout({'planChangeId': planChangeId});

  Future<CheckoutStart> _startCheckout(Map<String, Object?> target) async {
    const endpoint = 'POST /tenant/billing/checkout';
    // The route insists on exactly one of the two, and so does this.
    final body = await _client.post('/tenant/billing/checkout', body: target);
    return parseResponse(endpoint, body, (b) => CheckoutStart.fromJson(asJsonObject(endpoint, b)));
  }

  /// Hands the provider's own result back to the academy, unchanged. Whether the payment settled and
  /// whether the plan moved are the academy's answers, never the SDK's callback.
  Future<CheckoutOutcome> confirm({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    const endpoint = 'POST /tenant/billing/checkout/confirm';
    final body = await _client.post(
      '/tenant/billing/checkout/confirm',
      body: {'orderId': orderId, 'paymentId': paymentId, 'signature': signature},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => CheckoutOutcome.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Asks for a plan change. An upgrade comes back waiting for its payment with a quote; a downgrade
  /// comes back scheduled for the end of the period.
  Future<PlanChangeStart> changePlan({required String planId, required BillingCycle cycle}) async {
    const endpoint = 'POST /tenant/subscription/change';
    final body = await _client.post(
      '/tenant/subscription/change',
      body: {'planId': planId, 'cycle': cycle.wireName},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => PlanChangeStart.fromJson(asJsonObject(endpoint, b)),
    );
  }

  Future<void> cancelPlanChange(String planChangeId, {String? reason}) => _client.post(
    ApiPath.of(['tenant', 'subscription', 'plan-changes', ApiPath.id(planChangeId), 'cancel']),
    body: {'reason': ?reason},
  );

  /// Cancels the subscription. `immediately: false` lets it run to the end of the period, which is
  /// what the screen asks for; the reason reaches the academy's own record.
  ///
  /// The route answers with its raw subscription *record* (`billingCycle`, `currentPeriodEndAt`, …),
  /// not the view `/tenant/billing` serves, so the answer is not read: what changed is what the
  /// billing page says when it is read again.
  Future<void> cancelSubscription({required String reason, bool immediately = false}) =>
      _client.post(
        '/tenant/subscription/cancel',
        body: {'immediately': immediately, 'reason': reason.trim()},
      );

  /// Withdraws a pending cancellation. A pause is the platform's to lift: the route refuses it with a
  /// 403 in its own words. Like [cancelSubscription], the raw record it answers with is not read.
  Future<void> resumeSubscription({String? reason}) =>
      _client.post('/tenant/subscription/resume', body: {'reason': ?reason});

  /// What moving to [planId] on [cycle] would do — upgrade or downgrade, when it applies, the credit,
  /// the charge with tax and the limits already over — without asking for it. Writes nothing.
  Future<PlanChangePreview> previewChange({
    required String planId,
    required BillingCycle cycle,
  }) async {
    const endpoint = 'POST /tenant/subscription/preview';
    final body = await _client.post(
      '/tenant/subscription/preview',
      body: {'planId': planId, 'cycle': cycle.wireName},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => PlanChangePreview.fromJson(asJsonObject(endpoint, b)),
    );
  }
}

final staffBillingApiProvider = Provider<StaffBillingApi>(
  (ref) => StaffBillingApi(ref.watch(apiClientProvider)),
);
