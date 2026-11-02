// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BillingCustomer _$BillingCustomerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_BillingCustomer', json, ($checkedConvert) {
      final val = _BillingCustomer(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        email: $checkedConvert('email', (v) => v as String? ?? ''),
        city: $checkedConvert('city', (v) => v as String? ?? ''),
        country: $checkedConvert('country', (v) => v as String? ?? ''),
        learners: $checkedConvert('learners', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$BillingCustomerToJson(_BillingCustomer instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'city': instance.city,
  'country': instance.country,
  'learners': instance.learners,
};

_PaymentMethodView _$PaymentMethodViewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_PaymentMethodView', json, ($checkedConvert) {
      final val = _PaymentMethodView(
        kind: $checkedConvert(
          'kind',
          (v) =>
              $enumDecodeNullable(
                _$PaymentMethodKindEnumMap,
                v,
                unknownValue: PaymentMethodKind.unknown,
              ) ??
              PaymentMethodKind.unknown,
        ),
        brand: $checkedConvert('brand', (v) => v as String? ?? ''),
        last4: $checkedConvert('last4', (v) => v as String?),
        expiry: $checkedConvert('expiry', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$PaymentMethodViewToJson(_PaymentMethodView instance) => <String, dynamic>{
  'kind': _$PaymentMethodKindEnumMap[instance.kind]!,
  'brand': instance.brand,
  'last4': instance.last4,
  'expiry': instance.expiry,
};

const _$PaymentMethodKindEnumMap = {
  PaymentMethodKind.card: 'card',
  PaymentMethodKind.upi: 'upi',
  PaymentMethodKind.netbanking: 'netbanking',
  PaymentMethodKind.mandate: 'mandate',
  PaymentMethodKind.invoice: 'invoice',
  PaymentMethodKind.unknown: 'unknown',
};

_SubscriptionView _$SubscriptionViewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_SubscriptionView', json, ($checkedConvert) {
      final val = _SubscriptionView(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        customer: $checkedConvert(
          'customer',
          (v) => v == null
              ? const BillingCustomer()
              : BillingCustomer.fromJson(v as Map<String, dynamic>),
        ),
        planId: $checkedConvert('planId', (v) => v as String? ?? ''),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(
                _$SubscriptionStatusEnumMap,
                v,
                unknownValue: SubscriptionStatus.unknown,
              ) ??
              SubscriptionStatus.unknown,
        ),
        cycle: $checkedConvert(
          'cycle',
          (v) =>
              $enumDecodeNullable(_$BillingCycleEnumMap, v, unknownValue: BillingCycle.unknown) ??
              BillingCycle.unknown,
        ),
        amount: $checkedConvert('amount', (v) => (v as num?)?.toInt() ?? 0),
        currency: $checkedConvert('currency', (v) => v as String? ?? 'INR'),
        startedAt: $checkedConvert(
          'startedAt',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
        renewsAt: $checkedConvert(
          'renewsAt',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
        trialStartedAt: $checkedConvert(
          'trialStartedAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        trialEndsAt: $checkedConvert(
          'trialEndsAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        canceledAt: $checkedConvert(
          'canceledAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        cancelReason: $checkedConvert('cancelReason', (v) => v as String?),
        cancelAt: $checkedConvert('cancelAt', (v) => v as String?),
        pausedAt: $checkedConvert(
          'pausedAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        resumesAt: $checkedConvert(
          'resumesAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        paymentMethod: $checkedConvert(
          'paymentMethod',
          (v) => v == null
              ? const PaymentMethodView()
              : PaymentMethodView.fromJson(v as Map<String, dynamic>),
        ),
        lastPaymentAt: $checkedConvert(
          'lastPaymentAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        lastPaymentStatus: $checkedConvert(
          'lastPaymentStatus',
          (v) =>
              $enumDecodeNullable(_$InvoiceStatusEnumMap, v, unknownValue: InvoiceStatus.unknown),
        ),
        amountDue: $checkedConvert('amountDue', (v) => (v as num?)?.toInt()),
        nextRetryAt: $checkedConvert(
          'nextRetryAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        graceEndsAt: $checkedConvert(
          'graceEndsAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        retriesUsed: $checkedConvert('retriesUsed', (v) => (v as num?)?.toInt()),
        notes: $checkedConvert('notes', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$SubscriptionViewToJson(_SubscriptionView instance) => <String, dynamic>{
  'id': instance.id,
  'customer': instance.customer.toJson(),
  'planId': instance.planId,
  'status': _$SubscriptionStatusEnumMap[instance.status]!,
  'cycle': _$BillingCycleEnumMap[instance.cycle]!,
  'amount': instance.amount,
  'currency': instance.currency,
  'startedAt': const UtcDateTimeConverter().toJson(instance.startedAt),
  'renewsAt': const UtcDateTimeConverter().toJson(instance.renewsAt),
  'trialStartedAt': const NullableUtcDateTimeConverter().toJson(instance.trialStartedAt),
  'trialEndsAt': const NullableUtcDateTimeConverter().toJson(instance.trialEndsAt),
  'canceledAt': const NullableUtcDateTimeConverter().toJson(instance.canceledAt),
  'cancelReason': instance.cancelReason,
  'cancelAt': instance.cancelAt,
  'pausedAt': const NullableUtcDateTimeConverter().toJson(instance.pausedAt),
  'resumesAt': const NullableUtcDateTimeConverter().toJson(instance.resumesAt),
  'paymentMethod': instance.paymentMethod.toJson(),
  'lastPaymentAt': const NullableUtcDateTimeConverter().toJson(instance.lastPaymentAt),
  'lastPaymentStatus': _$InvoiceStatusEnumMap[instance.lastPaymentStatus],
  'amountDue': instance.amountDue,
  'nextRetryAt': const NullableUtcDateTimeConverter().toJson(instance.nextRetryAt),
  'graceEndsAt': const NullableUtcDateTimeConverter().toJson(instance.graceEndsAt),
  'retriesUsed': instance.retriesUsed,
  'notes': instance.notes,
};

const _$SubscriptionStatusEnumMap = {
  SubscriptionStatus.trial: 'trial',
  SubscriptionStatus.active: 'active',
  SubscriptionStatus.pastDue: 'past-due',
  SubscriptionStatus.canceling: 'canceling',
  SubscriptionStatus.canceled: 'canceled',
  SubscriptionStatus.paused: 'paused',
  SubscriptionStatus.expired: 'expired',
  SubscriptionStatus.unknown: 'unknown',
};

const _$BillingCycleEnumMap = {
  BillingCycle.monthly: 'monthly',
  BillingCycle.annual: 'annual',
  BillingCycle.unknown: 'unknown',
};

const _$InvoiceStatusEnumMap = {
  InvoiceStatus.paid: 'paid',
  InvoiceStatus.pending: 'pending',
  InvoiceStatus.failed: 'failed',
  InvoiceStatus.refunded: 'refunded',
  InvoiceStatus.voided: 'void',
  InvoiceStatus.unknown: 'unknown',
};

_PlanView _$PlanViewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_PlanView', json, ($checkedConvert) {
      final val = _PlanView(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        description: $checkedConvert('description', (v) => v as String? ?? ''),
        code: $checkedConvert('code', (v) => v as String? ?? ''),
        monthlyPrice: $checkedConvert('monthlyPrice', (v) => (v as num?)?.toInt() ?? 0),
        annualPrice: $checkedConvert('annualPrice', (v) => (v as num?)?.toInt() ?? 0),
        currency: $checkedConvert('currency', (v) => v as String? ?? 'INR'),
        cycles: $checkedConvert(
          'cycles',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        trialEnabled: $checkedConvert('trialEnabled', (v) => v as bool? ?? false),
        trialDays: $checkedConvert('trialDays', (v) => (v as num?)?.toInt() ?? 0),
        limits: $checkedConvert(
          'limits',
          (v) =>
              (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, (e as num?)?.toInt())) ??
              const <String, int?>{},
        ),
        features: $checkedConvert(
          'features',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        status: $checkedConvert('status', (v) => v as String? ?? ''),
        order: $checkedConvert('order', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$PlanViewToJson(_PlanView instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'code': instance.code,
  'monthlyPrice': instance.monthlyPrice,
  'annualPrice': instance.annualPrice,
  'currency': instance.currency,
  'cycles': instance.cycles,
  'trialEnabled': instance.trialEnabled,
  'trialDays': instance.trialDays,
  'limits': instance.limits,
  'features': instance.features,
  'status': instance.status,
  'order': instance.order,
};

_UsageLine _$UsageLineFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_UsageLine', json, ($checkedConvert) {
      final val = _UsageLine(
        limit: $checkedConvert('limit', (v) => v as String? ?? ''),
        label: $checkedConvert('label', (v) => v as String? ?? ''),
        used: $checkedConvert('used', (v) => (v as num?)?.toInt() ?? 0),
        allowed: $checkedConvert('allowed', (v) => (v as num?)?.toInt()),
        remaining: $checkedConvert('remaining', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$UsageLineToJson(_UsageLine instance) => <String, dynamic>{
  'limit': instance.limit,
  'label': instance.label,
  'used': instance.used,
  'allowed': instance.allowed,
  'remaining': instance.remaining,
};

_FeatureLine _$FeatureLineFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_FeatureLine', json, ($checkedConvert) {
      final val = _FeatureLine(
        key: $checkedConvert('key', (v) => v as String? ?? ''),
        label: $checkedConvert('label', (v) => v as String? ?? ''),
        included: $checkedConvert('included', (v) => v as bool? ?? false),
        enforcement: $checkedConvert(
          'enforcement',
          (v) =>
              $enumDecodeNullable(
                _$FeatureEnforcementEnumMap,
                v,
                unknownValue: FeatureEnforcement.unknown,
              ) ??
              FeatureEnforcement.unknown,
        ),
      );
      return val;
    });

Map<String, dynamic> _$FeatureLineToJson(_FeatureLine instance) => <String, dynamic>{
  'key': instance.key,
  'label': instance.label,
  'included': instance.included,
  'enforcement': _$FeatureEnforcementEnumMap[instance.enforcement]!,
};

const _$FeatureEnforcementEnumMap = {
  FeatureEnforcement.route: 'route',
  FeatureEnforcement.service: 'service',
  FeatureEnforcement.planned: 'planned',
  FeatureEnforcement.unknown: 'unknown',
};

_OpenPlanChange _$OpenPlanChangeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_OpenPlanChange', json, ($checkedConvert) {
      final val = _OpenPlanChange(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        direction: $checkedConvert('direction', (v) => v as String? ?? ''),
        status: $checkedConvert('status', (v) => v as String? ?? ''),
        toPlanId: $checkedConvert('toPlanId', (v) => v as String? ?? ''),
        toPlanName: $checkedConvert('toPlanName', (v) => v as String? ?? ''),
        toCycle: $checkedConvert(
          'toCycle',
          (v) =>
              $enumDecodeNullable(_$BillingCycleEnumMap, v, unknownValue: BillingCycle.unknown) ??
              BillingCycle.unknown,
        ),
        credit: $checkedConvert('credit', (v) => (v as num?)?.toInt() ?? 0),
        charge: $checkedConvert('charge', (v) => (v as num?)?.toInt() ?? 0),
        currency: $checkedConvert('currency', (v) => v as String? ?? 'INR'),
        effectiveAt: $checkedConvert(
          'effectiveAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        quotedAt: $checkedConvert(
          'quotedAt',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$OpenPlanChangeToJson(_OpenPlanChange instance) => <String, dynamic>{
  'id': instance.id,
  'direction': instance.direction,
  'status': instance.status,
  'toPlanId': instance.toPlanId,
  'toPlanName': instance.toPlanName,
  'toCycle': _$BillingCycleEnumMap[instance.toCycle]!,
  'credit': instance.credit,
  'charge': instance.charge,
  'currency': instance.currency,
  'effectiveAt': const NullableUtcDateTimeConverter().toJson(instance.effectiveAt),
  'quotedAt': const UtcDateTimeConverter().toJson(instance.quotedAt),
};

_TenantPayment _$TenantPaymentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_TenantPayment', json, ($checkedConvert) {
      final val = _TenantPayment(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        invoiceNumber: $checkedConvert('invoiceNumber', (v) => v as String?),
        amount: $checkedConvert('amount', (v) => (v as num?)?.toInt() ?? 0),
        currency: $checkedConvert('currency', (v) => v as String? ?? 'INR'),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(
                _$TenantPaymentStatusEnumMap,
                v,
                unknownValue: TenantPaymentStatus.unknown,
              ) ??
              TenantPaymentStatus.unknown,
        ),
        refunded: $checkedConvert('refunded', (v) => (v as num?)?.toInt() ?? 0),
        method: $checkedConvert('method', (v) => v as String?),
        at: $checkedConvert('at', (v) => const UtcDateTimeConverter().fromJson(v as String)),
        failureMessage: $checkedConvert('failureMessage', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$TenantPaymentToJson(_TenantPayment instance) => <String, dynamic>{
  'id': instance.id,
  'invoiceNumber': instance.invoiceNumber,
  'amount': instance.amount,
  'currency': instance.currency,
  'status': _$TenantPaymentStatusEnumMap[instance.status]!,
  'refunded': instance.refunded,
  'method': instance.method,
  'at': const UtcDateTimeConverter().toJson(instance.at),
  'failureMessage': instance.failureMessage,
};

const _$TenantPaymentStatusEnumMap = {
  TenantPaymentStatus.pending: 'pending',
  TenantPaymentStatus.paid: 'paid',
  TenantPaymentStatus.failed: 'failed',
  TenantPaymentStatus.refunded: 'refunded',
  TenantPaymentStatus.partiallyRefunded: 'partially_refunded',
  TenantPaymentStatus.unknown: 'unknown',
};

_InvoiceLine _$InvoiceLineFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_InvoiceLine', json, ($checkedConvert) {
      final val = _InvoiceLine(
        description: $checkedConvert('description', (v) => v as String? ?? ''),
        quantity: $checkedConvert('quantity', (v) => (v as num?)?.toInt() ?? 1),
        unitAmount: $checkedConvert('unitAmount', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$InvoiceLineToJson(_InvoiceLine instance) => <String, dynamic>{
  'description': instance.description,
  'quantity': instance.quantity,
  'unitAmount': instance.unitAmount,
};

_InvoiceAmounts _$InvoiceAmountsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_InvoiceAmounts', json, ($checkedConvert) {
      final val = _InvoiceAmounts(
        subtotal: $checkedConvert('subtotal', (v) => (v as num?)?.toInt() ?? 0),
        tax: $checkedConvert('tax', (v) => (v as num?)?.toInt() ?? 0),
        total: $checkedConvert('total', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$InvoiceAmountsToJson(_InvoiceAmounts instance) => <String, dynamic>{
  'subtotal': instance.subtotal,
  'tax': instance.tax,
  'total': instance.total,
};

_InvoiceView _$InvoiceViewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_InvoiceView', json, ($checkedConvert) {
      final val = _InvoiceView(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        number: $checkedConvert('number', (v) => v as String? ?? ''),
        subscriptionId: $checkedConvert('subscriptionId', (v) => v as String? ?? ''),
        customerId: $checkedConvert('customerId', (v) => v as String? ?? ''),
        customerName: $checkedConvert('customerName', (v) => v as String? ?? ''),
        planName: $checkedConvert('planName', (v) => v as String? ?? ''),
        cycle: $checkedConvert(
          'cycle',
          (v) =>
              $enumDecodeNullable(_$BillingCycleEnumMap, v, unknownValue: BillingCycle.unknown) ??
              BillingCycle.unknown,
        ),
        issuedAt: $checkedConvert(
          'issuedAt',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
        periodStart: $checkedConvert(
          'periodStart',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
        periodEnd: $checkedConvert(
          'periodEnd',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
        lines: $checkedConvert(
          'lines',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => InvoiceLine.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <InvoiceLine>[],
        ),
        taxPercent: $checkedConvert('taxPercent', (v) => v as num? ?? 0),
        currency: $checkedConvert('currency', (v) => v as String? ?? 'INR'),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(_$InvoiceStatusEnumMap, v, unknownValue: InvoiceStatus.unknown) ??
              InvoiceStatus.unknown,
        ),
        paidAt: $checkedConvert(
          'paidAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        method: $checkedConvert(
          'method',
          (v) => v == null
              ? const PaymentMethodView()
              : PaymentMethodView.fromJson(v as Map<String, dynamic>),
        ),
        note: $checkedConvert('note', (v) => v as String?),
        billingAddress: $checkedConvert(
          'billingAddress',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        amounts: $checkedConvert(
          'amounts',
          (v) => v == null ? null : InvoiceAmounts.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$InvoiceViewToJson(_InvoiceView instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'subscriptionId': instance.subscriptionId,
  'customerId': instance.customerId,
  'customerName': instance.customerName,
  'planName': instance.planName,
  'cycle': _$BillingCycleEnumMap[instance.cycle]!,
  'issuedAt': const UtcDateTimeConverter().toJson(instance.issuedAt),
  'periodStart': const UtcDateTimeConverter().toJson(instance.periodStart),
  'periodEnd': const UtcDateTimeConverter().toJson(instance.periodEnd),
  'lines': instance.lines.map((e) => e.toJson()).toList(),
  'taxPercent': instance.taxPercent,
  'currency': instance.currency,
  'status': _$InvoiceStatusEnumMap[instance.status]!,
  'paidAt': const NullableUtcDateTimeConverter().toJson(instance.paidAt),
  'method': instance.method.toJson(),
  'note': instance.note,
  'billingAddress': instance.billingAddress,
  'amounts': instance.amounts?.toJson(),
};

_TenantBilling _$TenantBillingFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_TenantBilling',
  json,
  ($checkedConvert) {
    final val = _TenantBilling(
      academy: $checkedConvert(
        'academy',
        (v) =>
            v == null ? const BillingAcademy() : BillingAcademy.fromJson(v as Map<String, dynamic>),
      ),
      subscription: $checkedConvert(
        'subscription',
        (v) => v == null ? null : SubscriptionView.fromJson(v as Map<String, dynamic>),
      ),
      plan: $checkedConvert(
        'plan',
        (v) => v == null ? null : PlanView.fromJson(v as Map<String, dynamic>),
      ),
      restricted: $checkedConvert('restricted', (v) => v as bool? ?? false),
      enforced: $checkedConvert('enforced', (v) => v as bool? ?? false),
      openChange: $checkedConvert(
        'openChange',
        (v) => v == null ? null : OpenPlanChange.fromJson(v as Map<String, dynamic>),
      ),
      usage: $checkedConvert(
        'usage',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => UsageLine.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <UsageLine>[],
      ),
      features: $checkedConvert(
        'features',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => FeatureLine.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <FeatureLine>[],
      ),
      invoices: $checkedConvert(
        'invoices',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => InvoiceView.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <InvoiceView>[],
      ),
      payments: $checkedConvert(
        'payments',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => TenantPayment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <TenantPayment>[],
      ),
      plans: $checkedConvert(
        'plans',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => PlanView.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <PlanView>[],
      ),
      checkoutAvailable: $checkedConvert('checkoutAvailable', (v) => v as bool? ?? false),
      trialAvailable: $checkedConvert('trialAvailable', (v) => v as bool? ?? false),
    );
    return val;
  },
);

Map<String, dynamic> _$TenantBillingToJson(_TenantBilling instance) => <String, dynamic>{
  'academy': instance.academy.toJson(),
  'subscription': instance.subscription?.toJson(),
  'plan': instance.plan?.toJson(),
  'restricted': instance.restricted,
  'enforced': instance.enforced,
  'openChange': instance.openChange?.toJson(),
  'usage': instance.usage.map((e) => e.toJson()).toList(),
  'features': instance.features.map((e) => e.toJson()).toList(),
  'invoices': instance.invoices.map((e) => e.toJson()).toList(),
  'payments': instance.payments.map((e) => e.toJson()).toList(),
  'plans': instance.plans.map((e) => e.toJson()).toList(),
  'checkoutAvailable': instance.checkoutAvailable,
  'trialAvailable': instance.trialAvailable,
};

_StartedTrial _$StartedTrialFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StartedTrial', json, ($checkedConvert) {
      final val = _StartedTrial(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        planId: $checkedConvert('planId', (v) => v as String? ?? ''),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(
                _$SubscriptionStateEnumMap,
                v,
                unknownValue: SubscriptionState.unknown,
              ) ??
              SubscriptionState.unknown,
        ),
        cycle: $checkedConvert(
          'billingCycle',
          (v) =>
              $enumDecodeNullable(_$BillingCycleEnumMap, v, unknownValue: BillingCycle.unknown) ??
              BillingCycle.unknown,
        ),
        trialStartAt: $checkedConvert(
          'trialStartAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        trialEndAt: $checkedConvert(
          'trialEndAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
      );
      return val;
    }, fieldKeyMap: const {'cycle': 'billingCycle'});

Map<String, dynamic> _$StartedTrialToJson(_StartedTrial instance) => <String, dynamic>{
  'id': instance.id,
  'planId': instance.planId,
  'status': _$SubscriptionStateEnumMap[instance.status]!,
  'billingCycle': _$BillingCycleEnumMap[instance.cycle]!,
  'trialStartAt': const NullableUtcDateTimeConverter().toJson(instance.trialStartAt),
  'trialEndAt': const NullableUtcDateTimeConverter().toJson(instance.trialEndAt),
};

const _$SubscriptionStateEnumMap = {
  SubscriptionState.trialing: 'trialing',
  SubscriptionState.active: 'active',
  SubscriptionState.pastDue: 'past_due',
  SubscriptionState.paused: 'paused',
  SubscriptionState.canceling: 'canceling',
  SubscriptionState.canceled: 'canceled',
  SubscriptionState.expired: 'expired',
  SubscriptionState.unknown: 'unknown',
};

_BillingAcademy _$BillingAcademyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_BillingAcademy', json, ($checkedConvert) {
      final val = _BillingAcademy(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        name: $checkedConvert('name', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$BillingAcademyToJson(_BillingAcademy instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

_CheckoutParams _$CheckoutParamsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CheckoutParams', json, ($checkedConvert) {
      final val = _CheckoutParams(
        provider: $checkedConvert('provider', (v) => v as String? ?? ''),
        keyId: $checkedConvert('keyId', (v) => v as String?),
        orderId: $checkedConvert('orderId', (v) => v as String? ?? ''),
        amount: $checkedConvert('amount', (v) => (v as num?)?.toInt() ?? 0),
        currency: $checkedConvert('currency', (v) => v as String? ?? 'INR'),
        redirectUrl: $checkedConvert('redirectUrl', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CheckoutParamsToJson(_CheckoutParams instance) => <String, dynamic>{
  'provider': instance.provider,
  'keyId': instance.keyId,
  'orderId': instance.orderId,
  'amount': instance.amount,
  'currency': instance.currency,
  'redirectUrl': instance.redirectUrl,
};

_CheckoutInvoice _$CheckoutInvoiceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CheckoutInvoice', json, ($checkedConvert) {
      final val = _CheckoutInvoice(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        number: $checkedConvert('number', (v) => v as String? ?? ''),
        total: $checkedConvert('total', (v) => (v as num?)?.toInt() ?? 0),
        currency: $checkedConvert('currency', (v) => v as String? ?? 'INR'),
      );
      return val;
    });

Map<String, dynamic> _$CheckoutInvoiceToJson(_CheckoutInvoice instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'total': instance.total,
  'currency': instance.currency,
};

_CheckoutStart _$CheckoutStartFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_CheckoutStart', json, ($checkedConvert) {
  final val = _CheckoutStart(
    checkout: $checkedConvert(
      'checkout',
      (v) =>
          v == null ? const CheckoutParams() : CheckoutParams.fromJson(v as Map<String, dynamic>),
    ),
    invoice: $checkedConvert(
      'invoice',
      (v) =>
          v == null ? const CheckoutInvoice() : CheckoutInvoice.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$CheckoutStartToJson(_CheckoutStart instance) => <String, dynamic>{
  'checkout': instance.checkout.toJson(),
  'invoice': instance.invoice.toJson(),
};

_CheckoutOutcome _$CheckoutOutcomeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CheckoutOutcome', json, ($checkedConvert) {
      final val = _CheckoutOutcome(
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(
                _$ProviderPaymentStatusEnumMap,
                v,
                unknownValue: ProviderPaymentStatus.unknown,
              ) ??
              ProviderPaymentStatus.unknown,
        ),
        settled: $checkedConvert('settled', (v) => v as bool? ?? false),
        applied: $checkedConvert('applied', (v) => v as bool? ?? false),
        message: $checkedConvert('message', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$CheckoutOutcomeToJson(_CheckoutOutcome instance) => <String, dynamic>{
  'status': _$ProviderPaymentStatusEnumMap[instance.status]!,
  'settled': instance.settled,
  'applied': instance.applied,
  'message': instance.message,
};

const _$ProviderPaymentStatusEnumMap = {
  ProviderPaymentStatus.pending: 'pending',
  ProviderPaymentStatus.authorized: 'authorized',
  ProviderPaymentStatus.paid: 'paid',
  ProviderPaymentStatus.failed: 'failed',
  ProviderPaymentStatus.refunded: 'refunded',
  ProviderPaymentStatus.unknown: 'unknown',
};

_TaxLine _$TaxLineFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_TaxLine', json, ($checkedConvert) {
      final val = _TaxLine(
        code: $checkedConvert('code', (v) => v as String? ?? ''),
        label: $checkedConvert('label', (v) => v as String? ?? ''),
        rateBps: $checkedConvert('rateBps', (v) => (v as num?)?.toInt() ?? 0),
        amount: $checkedConvert('amount', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$TaxLineToJson(_TaxLine instance) => <String, dynamic>{
  'code': instance.code,
  'label': instance.label,
  'rateBps': instance.rateBps,
  'amount': instance.amount,
};

_PayableQuote _$PayableQuoteFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_PayableQuote', json, ($checkedConvert) {
      final val = _PayableQuote(
        currency: $checkedConvert('currency', (v) => v as String? ?? 'INR'),
        net: $checkedConvert('net', (v) => (v as num?)?.toInt() ?? 0),
        lines: $checkedConvert(
          'lines',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => TaxLine.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <TaxLine>[],
        ),
        tax: $checkedConvert('tax', (v) => (v as num?)?.toInt() ?? 0),
        gross: $checkedConvert('gross', (v) => (v as num?)?.toInt() ?? 0),
        inclusive: $checkedConvert('inclusive', (v) => v as bool? ?? false),
        purpose: $checkedConvert('purpose', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$PayableQuoteToJson(_PayableQuote instance) => <String, dynamic>{
  'currency': instance.currency,
  'net': instance.net,
  'lines': instance.lines.map((e) => e.toJson()).toList(),
  'tax': instance.tax,
  'gross': instance.gross,
  'inclusive': instance.inclusive,
  'purpose': instance.purpose,
};

_PlanChangeStart _$PlanChangeStartFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_PlanChangeStart',
  json,
  ($checkedConvert) {
    final val = _PlanChangeStart(
      change: $checkedConvert('change', (v) => OpenPlanChange.fromJson(v as Map<String, dynamic>)),
      payable: $checkedConvert(
        'payable',
        (v) => v == null ? null : PayableQuote.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$PlanChangeStartToJson(_PlanChangeStart instance) => <String, dynamic>{
  'change': instance.change.toJson(),
  'payable': instance.payable?.toJson(),
};

_PreviewTarget _$PreviewTargetFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_PreviewTarget', json, ($checkedConvert) {
      final val = _PreviewTarget(
        planId: $checkedConvert('planId', (v) => v as String? ?? ''),
        planName: $checkedConvert('planName', (v) => v as String? ?? ''),
        cycle: $checkedConvert(
          'cycle',
          (v) =>
              $enumDecodeNullable(_$BillingCycleEnumMap, v, unknownValue: BillingCycle.unknown) ??
              BillingCycle.unknown,
        ),
        amount: $checkedConvert('amount', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$PreviewTargetToJson(_PreviewTarget instance) => <String, dynamic>{
  'planId': instance.planId,
  'planName': instance.planName,
  'cycle': _$BillingCycleEnumMap[instance.cycle]!,
  'amount': instance.amount,
};

_PreviewPayable _$PreviewPayableFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_PreviewPayable', json, ($checkedConvert) {
      final val = _PreviewPayable(
        net: $checkedConvert('net', (v) => (v as num?)?.toInt() ?? 0),
        tax: $checkedConvert('tax', (v) => (v as num?)?.toInt() ?? 0),
        gross: $checkedConvert('gross', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$PreviewPayableToJson(_PreviewPayable instance) => <String, dynamic>{
  'net': instance.net,
  'tax': instance.tax,
  'gross': instance.gross,
};

_LimitConflict _$LimitConflictFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LimitConflict', json, ($checkedConvert) {
      final val = _LimitConflict(
        limit: $checkedConvert('limit', (v) => v as String? ?? ''),
        usage: $checkedConvert('usage', (v) => (v as num?)?.toInt() ?? 0),
        newLimit: $checkedConvert('newLimit', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$LimitConflictToJson(_LimitConflict instance) => <String, dynamic>{
  'limit': instance.limit,
  'usage': instance.usage,
  'newLimit': instance.newLimit,
};

_PlanChangePreview _$PlanChangePreviewFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_PlanChangePreview',
  json,
  ($checkedConvert) {
    final val = _PlanChangePreview(
      kind: $checkedConvert(
        'kind',
        (v) =>
            $enumDecodeNullable(_$PlanChangeKindEnumMap, v, unknownValue: PlanChangeKind.unknown) ??
            PlanChangeKind.unknown,
      ),
      timing: $checkedConvert(
        'when',
        (v) =>
            $enumDecodeNullable(
              _$PlanChangeTimingEnumMap,
              v,
              unknownValue: PlanChangeTiming.unknown,
            ) ??
            PlanChangeTiming.unknown,
      ),
      appliesAt: $checkedConvert(
        'appliesAt',
        (v) => const UtcDateTimeConverter().fromJson(v as String),
      ),
      to: $checkedConvert(
        'to',
        (v) =>
            v == null ? const PreviewTarget() : PreviewTarget.fromJson(v as Map<String, dynamic>),
      ),
      currency: $checkedConvert('currency', (v) => v as String? ?? 'INR'),
      credit: $checkedConvert('credit', (v) => (v as num?)?.toInt() ?? 0),
      charge: $checkedConvert('charge', (v) => (v as num?)?.toInt() ?? 0),
      forfeited: $checkedConvert('forfeited', (v) => (v as num?)?.toInt() ?? 0),
      payable: $checkedConvert(
        'payable',
        (v) => v == null ? null : PreviewPayable.fromJson(v as Map<String, dynamic>),
      ),
      needsBillingAddress: $checkedConvert('needsBillingAddress', (v) => v as bool? ?? false),
      conflicts: $checkedConvert(
        'conflicts',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => LimitConflict.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <LimitConflict>[],
      ),
    );
    return val;
  },
  fieldKeyMap: const {'timing': 'when'},
);

Map<String, dynamic> _$PlanChangePreviewToJson(_PlanChangePreview instance) => <String, dynamic>{
  'kind': _$PlanChangeKindEnumMap[instance.kind]!,
  'when': _$PlanChangeTimingEnumMap[instance.timing]!,
  'appliesAt': const UtcDateTimeConverter().toJson(instance.appliesAt),
  'to': instance.to.toJson(),
  'currency': instance.currency,
  'credit': instance.credit,
  'charge': instance.charge,
  'forfeited': instance.forfeited,
  'payable': instance.payable?.toJson(),
  'needsBillingAddress': instance.needsBillingAddress,
  'conflicts': instance.conflicts.map((e) => e.toJson()).toList(),
};

const _$PlanChangeKindEnumMap = {
  PlanChangeKind.upgrade: 'upgrade',
  PlanChangeKind.cycleUpgrade: 'cycle_upgrade',
  PlanChangeKind.downgrade: 'downgrade',
  PlanChangeKind.scheduledChange: 'scheduled_change',
  PlanChangeKind.unknown: 'unknown',
};

const _$PlanChangeTimingEnumMap = {
  PlanChangeTiming.onPayment: 'on_payment',
  PlanChangeTiming.periodEnd: 'period_end',
  PlanChangeTiming.unknown: 'unknown',
};

_BillingDetails _$BillingDetailsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_BillingDetails', json, ($checkedConvert) {
      final val = _BillingDetails(
        legalName: $checkedConvert('legalName', (v) => v as String? ?? ''),
        email: $checkedConvert('email', (v) => v as String? ?? ''),
        addressLine1: $checkedConvert('addressLine1', (v) => v as String? ?? ''),
        addressLine2: $checkedConvert('addressLine2', (v) => v as String?),
        city: $checkedConvert('city', (v) => v as String? ?? ''),
        region: $checkedConvert('region', (v) => v as String?),
        postalCode: $checkedConvert('postalCode', (v) => v as String? ?? ''),
        country: $checkedConvert('country', (v) => v as String? ?? 'IN'),
        taxRegistration: $checkedConvert('taxRegistration', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$BillingDetailsToJson(_BillingDetails instance) => <String, dynamic>{
  'legalName': instance.legalName,
  'email': instance.email,
  'addressLine1': instance.addressLine1,
  'addressLine2': instance.addressLine2,
  'city': instance.city,
  'region': instance.region,
  'postalCode': instance.postalCode,
  'country': instance.country,
  'taxRegistration': instance.taxRegistration,
};
