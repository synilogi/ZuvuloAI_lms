import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';
import '../../../../shared/entitlements/dto/entitlements.dart' show SubscriptionState;

part 'billing.freezed.dart';
part 'billing.g.dart';

/// `apps/api/src/routes/tenant.ts`, `lib/checkout.ts`, `packages/domain/src/billingViews.ts` and
/// `subscription.ts` — the academy's own subscription as its admin is served it (SaaS §24).
///
/// **Every amount is an integer in the currency's minor unit, and every total is the server's.** The
/// app formats them through `Money.format` and does no arithmetic on them at all: tax may be
/// inclusive and several components each round, so a total the app added up could differ from the one
/// the academy was charged (§18).

enum BillingCycle { monthly, annual, unknown }

extension BillingCycleWire on BillingCycle {
  String get wireName => this == BillingCycle.annual ? 'annual' : 'monthly';
}

/// `SubscriptionStatus`.
enum SubscriptionStatus {
  trial,
  active,
  @JsonValue('past-due')
  pastDue,
  canceling,
  canceled,
  paused,
  expired,
  unknown,
}

/// `PaymentStatus` — how an invoice stands. `void` is withdrawn before payment, kept as history.
enum InvoiceStatus {
  paid,
  pending,
  failed,
  refunded,
  @JsonValue('void')
  voided,
  unknown,
}

/// How a payment of the academy's stands.
enum TenantPaymentStatus {
  pending,
  paid,
  failed,
  refunded,
  @JsonValue('partially_refunded')
  partiallyRefunded,
  unknown,
}

enum PaymentMethodKind { card, upi, netbanking, mandate, invoice, unknown }

/// How a feature is delivered: `planned` is sold and not built yet; `service` is a service level.
enum FeatureEnforcement { route, service, planned, unknown }

/// What the provider says a payment is.
enum ProviderPaymentStatus { pending, authorized, paid, failed, refunded, unknown }

/// The academy a subscription belongs to.
@freezed
abstract class BillingCustomer with _$BillingCustomer {
  const factory BillingCustomer({
    @Default('') String id,
    @Default('') String name,
    @Default('') String email,
    @Default('') String city,
    @Default('') String country,
    @Default(0) int learners,
  }) = _BillingCustomer;

  factory BillingCustomer.fromJson(Map<String, dynamic> json) => _$BillingCustomerFromJson(json);
}

/// How the academy pays — the brand and a masked identifier, never more.
@freezed
abstract class PaymentMethodView with _$PaymentMethodView {
  const factory PaymentMethodView({
    @JsonKey(unknownEnumValue: PaymentMethodKind.unknown)
    @Default(PaymentMethodKind.unknown)
    PaymentMethodKind kind,
    @Default('') String brand,
    String? last4,
    String? expiry,
  }) = _PaymentMethodView;

  const PaymentMethodView._();

  factory PaymentMethodView.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodViewFromJson(json);

  /// "Visa •••• 4242", or the brand alone.
  String get label => last4 == null || last4!.isEmpty ? brand : '$brand •••• $last4';
}

/// The academy's subscription. Its status is the academy's word for it, never derived here.
@freezed
abstract class SubscriptionView with _$SubscriptionView {
  const factory SubscriptionView({
    @Default('') String id,
    @Default(BillingCustomer()) BillingCustomer customer,
    @Default('') String planId,
    @JsonKey(unknownEnumValue: SubscriptionStatus.unknown)
    @Default(SubscriptionStatus.unknown)
    SubscriptionStatus status,
    @JsonKey(unknownEnumValue: BillingCycle.unknown)
    @Default(BillingCycle.unknown)
    BillingCycle cycle,

    /// Minor units, charged each cycle.
    @Default(0) int amount,
    @Default('INR') String currency,
    @UtcDateTimeConverter() required DateTime startedAt,

    /// When the period ends: the renewal date, or the last day of a cancelling subscription.
    @UtcDateTimeConverter() required DateTime renewsAt,
    @NullableUtcDateTimeConverter() DateTime? trialStartedAt,
    @NullableUtcDateTimeConverter() DateTime? trialEndsAt,
    @NullableUtcDateTimeConverter() DateTime? canceledAt,
    String? cancelReason,
    String? cancelAt,
    @NullableUtcDateTimeConverter() DateTime? pausedAt,
    @NullableUtcDateTimeConverter() DateTime? resumesAt,
    @Default(PaymentMethodView()) PaymentMethodView paymentMethod,
    @NullableUtcDateTimeConverter() DateTime? lastPaymentAt,
    @JsonKey(unknownEnumValue: InvoiceStatus.unknown) InvoiceStatus? lastPaymentStatus,

    /// Past-due only: what is owed, in minor units, and when the next retry runs.
    int? amountDue,
    @NullableUtcDateTimeConverter() DateTime? nextRetryAt,

    /// Past-due only: when access closes if nothing is paid.
    @NullableUtcDateTimeConverter() DateTime? graceEndsAt,
    int? retriesUsed,
    String? notes,
  }) = _SubscriptionView;

  const SubscriptionView._();

  factory SubscriptionView.fromJson(Map<String, dynamic> json) => _$SubscriptionViewFromJson(json);

  bool get isTrial => status == SubscriptionStatus.trial;

  bool get isPastDue => status == SubscriptionStatus.pastDue;

  /// Cancelled at the end of the period: still running until [renewsAt], and resumable until then.
  bool get isCanceling => status == SubscriptionStatus.canceling;

  bool get isPaused => status == SubscriptionStatus.paused;

  /// How many whole days of the trial are left at [now]; `null` when this is not a trial.
  int? trialDaysLeft(DateTime now) {
    final ends = trialEndsAt;
    if (!isTrial || ends == null) return null;
    final left = ends.difference(now).inDays;
    return left < 0 ? 0 : left;
  }
}

/// A plan as the academy is served it: its own version's prices, limits and features.
@freezed
abstract class PlanView with _$PlanView {
  const factory PlanView({
    @Default('') String id,
    @Default('') String name,
    @Default('') String description,
    @Default('') String code,

    /// Minor units.
    @Default(0) int monthlyPrice,
    @Default(0) int annualPrice,
    @Default('INR') String currency,
    @Default(<String>[]) List<String> cycles,
    @Default(false) bool trialEnabled,
    @Default(0) int trialDays,

    /// `null` for a limit with no ceiling.
    @Default(<String, int?>{}) Map<String, int?> limits,
    @Default(<String>[]) List<String> features,
    @Default('') String status,
    @Default(0) int order,
  }) = _PlanView;

  const PlanView._();

  factory PlanView.fromJson(Map<String, dynamic> json) => _$PlanViewFromJson(json);

  /// A `PlanRecord` row of `GET /tenant/plans` (`apps/api/src/lib/plans.ts` `toRecord`). Unlike the
  /// plans `/tenant/billing` serves, its prices, cycles, trial, features and limits sit under
  /// `current` — the version new subscriptions are sold on — and its order is `displayOrder`. A cycle
  /// the version does not sell has a `null` price there, read as 0 as the billing page sends it.
  factory PlanView.fromPlanRecord(Map<String, dynamic> json) {
    final current = json['current'] is Map<String, dynamic>
        ? json['current'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final trialDays = (current['trialDays'] as num?)?.toInt() ?? 0;
    return PlanView.fromJson({
      'id': json['id'],
      'name': json['name'],
      'description': json['description'],
      'code': json['code'],
      'status': json['status'],
      'order': json['displayOrder'] ?? 0,
      'monthlyPrice': current['monthlyPrice'] ?? 0,
      'annualPrice': current['annualPrice'] ?? 0,
      'currency': current['currency'] ?? 'INR',
      'cycles': current['cycles'] ?? const <String>[],
      'trialEnabled': trialDays > 0,
      'trialDays': trialDays,
      'limits': current['limits'] ?? const <String, Object?>{},
      'features': current['features'] ?? const <String>[],
    });
  }

  /// Whether the plan offers a free trial at all — whether *this* academy may start it is
  /// [TenantBilling.trialAvailable].
  bool get offersTrial => trialEnabled && trialDays > 0;

  /// Whether the plan includes the feature whose wire key is [featureKey].
  bool includesFeature(String featureKey) => features.contains(featureKey);

  bool get sellsAnnual => cycles.contains('annual');

  bool get sellsMonthly => cycles.contains('monthly');

  /// What this plan costs on [cycle], in minor units.
  int priceFor(BillingCycle cycle) => cycle == BillingCycle.annual ? annualPrice : monthlyPrice;
}

/// One limit and how much of it the academy has used. `allowed` and `remaining` are `null` for a
/// limit with no ceiling — shown as "Unlimited", never as nought.
@freezed
abstract class UsageLine with _$UsageLine {
  const factory UsageLine({
    @Default('') String limit,
    @Default('') String label,
    @Default(0) int used,
    int? allowed,
    int? remaining,
  }) = _UsageLine;

  const UsageLine._();

  factory UsageLine.fromJson(Map<String, dynamic> json) => _$UsageLineFromJson(json);

  bool get isUnlimited => allowed == null;

  /// How full this limit is, 0–1; `null` without a ceiling to measure against.
  double? get share {
    final ceiling = allowed;
    if (ceiling == null || ceiling <= 0) return null;
    final share = used / ceiling;
    return share > 1 ? 1 : share;
  }

  /// Whether the academy is at or past this limit — the academy's own figures say so.
  bool get isFull => allowed != null && (remaining ?? 0) <= 0;
}

/// One feature and whether the academy's plan includes it.
@freezed
abstract class FeatureLine with _$FeatureLine {
  const factory FeatureLine({
    @Default('') String key,
    @Default('') String label,
    @Default(false) bool included,
    @JsonKey(unknownEnumValue: FeatureEnforcement.unknown)
    @Default(FeatureEnforcement.unknown)
    FeatureEnforcement enforcement,
  }) = _FeatureLine;

  const FeatureLine._();

  factory FeatureLine.fromJson(Map<String, dynamic> json) => _$FeatureLineFromJson(json);

  /// Sold but not built yet, so its absence is not a refusal to explain.
  bool get isPlanned => enforcement == FeatureEnforcement.planned;
}

/// A plan change asked for that has not happened yet: an upgrade waiting for its payment, or a
/// downgrade waiting for the period to end.
@freezed
abstract class OpenPlanChange with _$OpenPlanChange {
  const factory OpenPlanChange({
    @Default('') String id,
    @Default('') String direction,
    @Default('') String status,
    @Default('') String toPlanId,
    @Default('') String toPlanName,
    @JsonKey(unknownEnumValue: BillingCycle.unknown)
    @Default(BillingCycle.unknown)
    BillingCycle toCycle,

    /// Minor units: the unused value credited, and what is charged now. Both 0 for a downgrade.
    @Default(0) int credit,
    @Default(0) int charge,
    @Default('INR') String currency,
    @NullableUtcDateTimeConverter() DateTime? effectiveAt,
    @UtcDateTimeConverter() required DateTime quotedAt,
  }) = _OpenPlanChange;

  const OpenPlanChange._();

  factory OpenPlanChange.fromJson(Map<String, dynamic> json) => _$OpenPlanChangeFromJson(json);

  bool get isUpgrade => direction == 'upgrade';

  /// Waiting for its payment, so the academy can still pay it — or give it up.
  bool get awaitsPayment => status == 'pending_payment';

  /// Waiting for the period to end.
  bool get isScheduled => status == 'scheduled';
}

/// A payment of the academy's.
@freezed
abstract class TenantPayment with _$TenantPayment {
  const factory TenantPayment({
    @Default('') String id,
    String? invoiceNumber,
    @Default(0) int amount,
    @Default('INR') String currency,
    @JsonKey(unknownEnumValue: TenantPaymentStatus.unknown)
    @Default(TenantPaymentStatus.unknown)
    TenantPaymentStatus status,
    @Default(0) int refunded,

    /// "Visa •••• 4242", "UPI" — never more.
    String? method,
    @UtcDateTimeConverter() required DateTime at,
    String? failureMessage,
  }) = _TenantPayment;

  factory TenantPayment.fromJson(Map<String, dynamic> json) => _$TenantPaymentFromJson(json);
}

/// One line of an invoice. `unitAmount` is in minor units.
@freezed
abstract class InvoiceLine with _$InvoiceLine {
  const factory InvoiceLine({
    @Default('') String description,
    @Default(1) int quantity,
    @Default(0) int unitAmount,
  }) = _InvoiceLine;

  factory InvoiceLine.fromJson(Map<String, dynamic> json) => _$InvoiceLineFromJson(json);
}

/// The figures the academy fixed when it issued the invoice, in minor units. A screen shows these
/// and never recalculates them.
@freezed
abstract class InvoiceAmounts with _$InvoiceAmounts {
  const factory InvoiceAmounts({
    @Default(0) int subtotal,
    @Default(0) int tax,
    @Default(0) int total,
  }) = _InvoiceAmounts;

  factory InvoiceAmounts.fromJson(Map<String, dynamic> json) => _$InvoiceAmountsFromJson(json);
}

/// An invoice as the academy sees it.
@freezed
abstract class InvoiceView with _$InvoiceView {
  const factory InvoiceView({
    @Default('') String id,

    /// Human-facing, e.g. "INV-2026-0148".
    @Default('') String number,
    @Default('') String subscriptionId,
    @Default('') String customerId,
    @Default('') String customerName,
    @Default('') String planName,
    @JsonKey(unknownEnumValue: BillingCycle.unknown)
    @Default(BillingCycle.unknown)
    BillingCycle cycle,
    @UtcDateTimeConverter() required DateTime issuedAt,
    @UtcDateTimeConverter() required DateTime periodStart,
    @UtcDateTimeConverter() required DateTime periodEnd,
    @Default(<InvoiceLine>[]) List<InvoiceLine> lines,

    /// Per cent of the subtotal, e.g. 18 for GST.
    @Default(0) num taxPercent,
    @Default('INR') String currency,
    @JsonKey(unknownEnumValue: InvoiceStatus.unknown)
    @Default(InvoiceStatus.unknown)
    InvoiceStatus status,
    @NullableUtcDateTimeConverter() DateTime? paidAt,
    @Default(PaymentMethodView()) PaymentMethodView method,

    /// Why a payment failed or was refunded — shown in place of a paid date.
    String? note,
    @Default(<String>[]) List<String> billingAddress,

    /// Present on every invoice the billing API serves.
    InvoiceAmounts? amounts,
  }) = _InvoiceView;

  const InvoiceView._();

  factory InvoiceView.fromJson(Map<String, dynamic> json) => _$InvoiceViewFromJson(json);

  /// Still open, so it is one the academy could pay.
  bool get isPayable => status == InvoiceStatus.pending;

  bool get isPaid => status == InvoiceStatus.paid;
}

/// `GET /tenant/billing` — everything the billing screen shows.
@freezed
abstract class TenantBilling with _$TenantBilling {
  const factory TenantBilling({
    @Default(BillingAcademy()) BillingAcademy academy,

    /// The live subscription, or the most recent one; `null` when the academy has never subscribed.
    SubscriptionView? subscription,
    PlanView? plan,

    /// No plan is served: the academy keeps what it has and cannot add to it until it renews.
    @Default(false) bool restricted,

    /// Whether the platform enforces plans yet. While it does not, nothing is refused for a limit or
    /// a missing plan, so the screen does not warn of a block that will not happen.
    @Default(false) bool enforced,
    OpenPlanChange? openChange,
    @Default(<UsageLine>[]) List<UsageLine> usage,
    @Default(<FeatureLine>[]) List<FeatureLine> features,
    @Default(<InvoiceView>[]) List<InvoiceView> invoices,
    @Default(<TenantPayment>[]) List<TenantPayment> payments,
    @Default(<PlanView>[]) List<PlanView> plans,

    /// Whether online payment is connected. Until it is, an upgrade can be quoted but not paid.
    @Default(false) bool checkoutAvailable,

    /// Whether the academy may start a free trial now: no live subscription, and none had before
    /// (`trialAvailable` in `apps/api/src/lib/subscriptions.ts`). The academy's word, never inferred.
    @Default(false) bool trialAvailable,
  }) = _TenantBilling;

  const TenantBilling._();

  factory TenantBilling.fromJson(Map<String, dynamic> json) => _$TenantBillingFromJson(json);

  /// The academy has never been on a plan.
  bool get hasNoPlan => subscription == null;

  /// Whether the academy is running on a subscription it can change — anything but none, cancelled
  /// or expired (`liveSubscription` in `apps/api/src/lib/subscriptions.ts`). Without one, a plan is
  /// bought with a first purchase rather than asked for as a change.
  bool get hasLiveSubscription => switch (subscription?.status) {
    null || SubscriptionStatus.canceled || SubscriptionStatus.expired => false,
    _ => true,
  };

  /// Whether a plan is bought with a first purchase rather than asked for as a change: with no live
  /// subscription, or on a free trial — which the academy may buy out of with any plan (D33); the
  /// trial ends only once the payment is verified.
  bool get buysPlan => !hasLiveSubscription || (subscription?.isTrial ?? false);

  /// The limits the academy is at or past, as its own figures report them.
  List<UsageLine> get limitsReached => [
    for (final line in usage)
      if (line.isFull) line,
  ];

  /// The plans whose free trial this academy could start now, in the academy's order.
  List<PlanView> get trialPlans => [
    if (trialAvailable)
      for (final plan in plans)
        if (plan.offersTrial) plan,
  ];

  /// Invoices still open, newest first as the route sends them.
  List<InvoiceView> get openInvoices => [
    for (final i in invoices)
      if (i.isPayable) i,
  ];
}

/// The subscription a free trial started, as `POST /tenant/billing/trial` answers (`201
/// {subscription}`, the raw `SubscriptionRecord` of `apps/api/src/lib/subscriptions.ts`). Only what
/// the onboarding screen says is read: never the tenant, the amount or the provider.
@freezed
abstract class StartedTrial with _$StartedTrial {
  const factory StartedTrial({
    @Default('') String id,
    @Default('') String planId,
    @JsonKey(unknownEnumValue: SubscriptionState.unknown)
    @Default(SubscriptionState.unknown)
    SubscriptionState status,
    @JsonKey(name: 'billingCycle', unknownEnumValue: BillingCycle.unknown)
    @Default(BillingCycle.unknown)
    BillingCycle cycle,
    @NullableUtcDateTimeConverter() DateTime? trialStartAt,
    @NullableUtcDateTimeConverter() DateTime? trialEndAt,
  }) = _StartedTrial;

  factory StartedTrial.fromJson(Map<String, dynamic> json) => _$StartedTrialFromJson(json);
}

@freezed
abstract class BillingAcademy with _$BillingAcademy {
  const factory BillingAcademy({@Default('') String id, @Default('') String name}) =
      _BillingAcademy;

  factory BillingAcademy.fromJson(Map<String, dynamic> json) => _$BillingAcademyFromJson(json);
}

/// `CheckoutParams` — what the gateway needs, exactly as the academy pinned it. `keyId` is the
/// provider's **publishable** key; it is held for the one checkout in flight and never stored.
@freezed
abstract class CheckoutParams with _$CheckoutParams {
  const factory CheckoutParams({
    @Default('') String provider,
    String? keyId,
    @Default('') String orderId,

    /// Minor units — the academy's figure, never the app's.
    @Default(0) int amount,
    @Default('INR') String currency,
    String? redirectUrl,
  }) = _CheckoutParams;

  factory CheckoutParams.fromJson(Map<String, dynamic> json) => _$CheckoutParamsFromJson(json);
}

/// What an invoice is, for the checkout in flight.
@freezed
abstract class CheckoutInvoice with _$CheckoutInvoice {
  const factory CheckoutInvoice({
    @Default('') String id,
    @Default('') String number,
    @Default(0) int total,
    @Default('INR') String currency,
  }) = _CheckoutInvoice;

  factory CheckoutInvoice.fromJson(Map<String, dynamic> json) => _$CheckoutInvoiceFromJson(json);
}

/// `201 CheckoutStart` — the academy has issued the invoice and opened an order with its gateway.
@freezed
abstract class CheckoutStart with _$CheckoutStart {
  const factory CheckoutStart({
    @Default(CheckoutParams()) CheckoutParams checkout,
    @Default(CheckoutInvoice()) CheckoutInvoice invoice,
  }) = _CheckoutStart;

  factory CheckoutStart.fromJson(Map<String, dynamic> json) => _$CheckoutStartFromJson(json);
}

/// `CheckoutOutcome` — what the academy made of the provider's result. **The app never decides that a
/// payment succeeded:** `settled` and `applied` are the academy's words, and only a re-read of
/// `/tenant/billing` shows a plan as active.
@freezed
abstract class CheckoutOutcome with _$CheckoutOutcome {
  const factory CheckoutOutcome({
    @JsonKey(unknownEnumValue: ProviderPaymentStatus.unknown)
    @Default(ProviderPaymentStatus.unknown)
    ProviderPaymentStatus status,

    /// Whether this call settled the invoice.
    @Default(false) bool settled,

    /// Whether the subscription moved as the invoice was for.
    @Default(false) bool applied,
    @Default('') String message,
  }) = _CheckoutOutcome;

  const CheckoutOutcome._();

  factory CheckoutOutcome.fromJson(Map<String, dynamic> json) => _$CheckoutOutcomeFromJson(json);

  /// Still with the bank: worth asking the academy again in a moment.
  bool get isPending =>
      status == ProviderPaymentStatus.pending || status == ProviderPaymentStatus.authorized;
}

/// One tax line of a quote.
@freezed
abstract class TaxLine with _$TaxLine {
  const factory TaxLine({
    @Default('') String code,
    @Default('') String label,
    @Default(0) int rateBps,
    @Default(0) int amount,
  }) = _TaxLine;

  factory TaxLine.fromJson(Map<String, dynamic> json) => _$TaxLineFromJson(json);
}

/// What a plan change would cost, quoted by the academy. Every figure is its own.
@freezed
abstract class PayableQuote with _$PayableQuote {
  const factory PayableQuote({
    @Default('INR') String currency,
    @Default(0) int net,
    @Default(<TaxLine>[]) List<TaxLine> lines,
    @Default(0) int tax,
    @Default(0) int gross,
    @Default(false) bool inclusive,
    @Default('') String purpose,
  }) = _PayableQuote;

  factory PayableQuote.fromJson(Map<String, dynamic> json) => _$PayableQuoteFromJson(json);
}

/// `201` from `POST /tenant/subscription/change` — the change, and what it costs when it costs
/// anything. A downgrade is quoted at nothing and simply waits for the period to end.
@freezed
abstract class PlanChangeStart with _$PlanChangeStart {
  const factory PlanChangeStart({required OpenPlanChange change, PayableQuote? payable}) =
      _PlanChangeStart;

  factory PlanChangeStart.fromJson(Map<String, dynamic> json) => _$PlanChangeStartFromJson(json);
}

/// `PlanChangeKind` (`packages/domain/src/planChange.ts`): the academy's word for what a move is.
enum PlanChangeKind {
  upgrade,
  @JsonValue('cycle_upgrade')
  cycleUpgrade,
  downgrade,
  @JsonValue('scheduled_change')
  scheduledChange,
  unknown,
}

/// When a previewed change would apply: once it is paid for, or at the end of the period.
enum PlanChangeTiming {
  @JsonValue('on_payment')
  onPayment,
  @JsonValue('period_end')
  periodEnd,
  unknown,
}

/// The plan and cycle a previewed change moves to, with that cycle's price (minor units).
@freezed
abstract class PreviewTarget with _$PreviewTarget {
  const factory PreviewTarget({
    @Default('') String planId,
    @Default('') String planName,
    @JsonKey(unknownEnumValue: BillingCycle.unknown)
    @Default(BillingCycle.unknown)
    BillingCycle cycle,
    @Default(0) int amount,
  }) = _PreviewTarget;

  factory PreviewTarget.fromJson(Map<String, dynamic> json) => _$PreviewTargetFromJson(json);
}

/// What a previewed charge comes to with tax, at the academy's billing address. Minor units.
@freezed
abstract class PreviewPayable with _$PreviewPayable {
  const factory PreviewPayable({@Default(0) int net, @Default(0) int tax, @Default(0) int gross}) =
      _PreviewPayable;

  factory PreviewPayable.fromJson(Map<String, dynamic> json) => _$PreviewPayableFromJson(json);
}

/// A limit the academy already uses more of than the new plan allows (`LimitConflict`).
@freezed
abstract class LimitConflict with _$LimitConflict {
  const factory LimitConflict({
    @Default('') String limit,
    @Default(0) int usage,
    @Default(0) int newLimit,
  }) = _LimitConflict;

  factory LimitConflict.fromJson(Map<String, dynamic> json) => _$LimitConflictFromJson(json);
}

/// `POST /tenant/subscription/preview` (`PlanChangePreview`, `apps/api/src/lib/planChanges.ts`) —
/// what asking for a change would do, before it is asked for. It writes nothing. Every figure is the
/// academy's: the credit, the charge, the tax and the total are shown, never worked out here.
@freezed
abstract class PlanChangePreview with _$PlanChangePreview {
  const factory PlanChangePreview({
    @JsonKey(unknownEnumValue: PlanChangeKind.unknown)
    @Default(PlanChangeKind.unknown)
    PlanChangeKind kind,
    @JsonKey(name: 'when', unknownEnumValue: PlanChangeTiming.unknown)
    @Default(PlanChangeTiming.unknown)
    PlanChangeTiming timing,
    @UtcDateTimeConverter() required DateTime appliesAt,
    @Default(PreviewTarget()) PreviewTarget to,
    @Default('INR') String currency,
    @Default(0) int credit,
    @Default(0) int charge,
    @Default(0) int forfeited,

    /// `null` when nothing is charged now, or when the academy has no billing address to tax it by.
    PreviewPayable? payable,

    /// The change is charged, and its tax needs the academy's billing address first.
    @Default(false) bool needsBillingAddress,
    @Default(<LimitConflict>[]) List<LimitConflict> conflicts,
  }) = _PlanChangePreview;

  const PlanChangePreview._();

  factory PlanChangePreview.fromJson(Map<String, dynamic> json) =>
      _$PlanChangePreviewFromJson(json);

  /// Charged now and applied once paid, rather than waiting for the period to end.
  bool get appliesOnPayment => timing == PlanChangeTiming.onPayment;
}

/// `GET|PUT /tenant/billing-profile` — where the academy's invoices are addressed
/// (`BillingDetails`, `packages/domain/src/billingViews.ts`). A first purchase and a charged upgrade
/// need it: tax is worked out from the country and region. The server validates it again.
@freezed
abstract class BillingDetails with _$BillingDetails {
  const factory BillingDetails({
    @Default('') String legalName,
    @Default('') String email,
    @Default('') String addressLine1,
    String? addressLine2,
    @Default('') String city,
    String? region,
    @Default('') String postalCode,

    /// ISO 3166-1 alpha-2, e.g. `IN`.
    @Default('IN') String country,
    String? taxRegistration,
  }) = _BillingDetails;

  const BillingDetails._();

  factory BillingDetails.fromJson(Map<String, dynamic> json) => _$BillingDetailsFromJson(json);

  /// The body `PUT /tenant/billing-profile` reads — these keys and no others, an optional one only
  /// when it was given.
  Map<String, Object?> toRequest() {
    String? optional(String? value) {
      final trimmed = value?.trim();
      return trimmed == null || trimmed.isEmpty ? null : trimmed;
    }

    return {
      'legalName': legalName.trim(),
      'email': email.trim(),
      'addressLine1': addressLine1.trim(),
      'addressLine2': ?optional(addressLine2),
      'city': city.trim(),
      'region': ?optional(region),
      'postalCode': postalCode.trim(),
      'country': country.trim().toUpperCase(),
      'taxRegistration': ?optional(taxRegistration),
    };
  }
}

/// The field a billing details form could not send as it stands, and why — the same checks the
/// server makes (`billingDetailsIssues`), so the form can say what is missing before it is sent.
enum BillingDetailsField {
  legalName,
  email,
  addressLine1,
  city,
  region,
  postalCode,
  country,
  taxRegistration,
}

final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _country = RegExp(r'^[A-Za-z]{2}$');
final _region = RegExp(r'^[A-Za-z0-9-]{1,10}$');
final _taxRegistration = RegExp(r'^[A-Za-z0-9-]{3,32}$');

/// The fields of [details] the academy would refuse, in form order.
Set<BillingDetailsField> billingDetailsIssues(BillingDetails details) {
  final region = details.region?.trim() ?? '';
  final tax = (details.taxRegistration ?? '').trim().replaceAll(RegExp(r'\s+'), '');
  return {
    if (details.legalName.trim().length < 2) BillingDetailsField.legalName,
    if (!_email.hasMatch(details.email.trim())) BillingDetailsField.email,
    if (details.addressLine1.trim().length < 3) BillingDetailsField.addressLine1,
    if (details.city.trim().length < 2) BillingDetailsField.city,
    if (region.isNotEmpty && !_region.hasMatch(region)) BillingDetailsField.region,
    if (details.postalCode.trim().length < 2) BillingDetailsField.postalCode,
    if (!_country.hasMatch(details.country.trim())) BillingDetailsField.country,
    if (tax.isNotEmpty && !_taxRegistration.hasMatch(tax)) BillingDetailsField.taxRegistration,
  };
}

/// The shortest and longest cancellation reason `POST /tenant/subscription/cancel` will take.
const minCancelReason = 3;
const maxCancelReason = 500;

/// Whether a cancellation reason is one the academy will accept.
bool cancelReasonIsEnough(String reason) {
  final trimmed = reason.trim();
  return trimmed.length >= minCancelReason && trimmed.length <= maxCancelReason;
}
