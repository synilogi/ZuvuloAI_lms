// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entitlements.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TenantEntitlements _$TenantEntitlementsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_TenantEntitlements', json, ($checkedConvert) {
      final val = _TenantEntitlements(
        status: $checkedConvert(
          'status',
          (v) => $enumDecodeNullable(
            _$SubscriptionStateEnumMap,
            v,
            unknownValue: SubscriptionState.unknown,
          ),
        ),
        planVersionId: $checkedConvert('planVersionId', (v) => v as String?),
        plan: $checkedConvert(
          'plan',
          (v) => v == null ? null : PlanSummary.fromJson(v as Map<String, dynamic>),
        ),
        features: $checkedConvert(
          'features',
          (v) => v == null ? const [] : const _FeatureKeysConverter().fromJson(v as List?),
        ),
        limits: $checkedConvert(
          'limits',
          (v) =>
              v == null ? const {} : const _LimitsConverter().fromJson(v as Map<String, dynamic>?),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TenantEntitlementsToJson(_TenantEntitlements instance) => <String, dynamic>{
  'status': _$SubscriptionStateEnumMap[instance.status],
  'planVersionId': instance.planVersionId,
  'plan': instance.plan?.toJson(),
  'features': const _FeatureKeysConverter().toJson(instance.features),
  'limits': const _LimitsConverter().toJson(instance.limits),
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

_PlanSummary _$PlanSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_PlanSummary', json, ($checkedConvert) {
      final val = _PlanSummary(
        id: $checkedConvert('id', (v) => v as String),
        code: $checkedConvert('code', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PlanSummaryToJson(_PlanSummary instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
};

_UsageLine _$UsageLineFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_UsageLine', json, ($checkedConvert) {
      final val = _UsageLine(
        limit: $checkedConvert('limit', (v) => LimitKey.parse(v)),
        label: $checkedConvert('label', (v) => v as String),
        used: $checkedConvert('used', (v) => (v as num).toInt()),
        allowed: $checkedConvert('allowed', (v) => (v as num?)?.toInt()),
        remaining: $checkedConvert('remaining', (v) => (v as num?)?.toInt()),
        counts: $checkedConvert('counts', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$UsageLineToJson(_UsageLine instance) => <String, dynamic>{
  'limit': _limitToJson(instance.limit),
  'label': instance.label,
  'used': instance.used,
  'allowed': instance.allowed,
  'remaining': instance.remaining,
  'counts': instance.counts,
};

_UsageSummary _$UsageSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_UsageSummary', json, ($checkedConvert) {
      final val = _UsageSummary(
        status: $checkedConvert(
          'status',
          (v) => $enumDecodeNullable(
            _$SubscriptionStateEnumMap,
            v,
            unknownValue: SubscriptionState.unknown,
          ),
        ),
        restricted: $checkedConvert('restricted', (v) => v as bool? ?? false),
        plan: $checkedConvert(
          'plan',
          (v) => v == null ? null : PlanSummary.fromJson(v as Map<String, dynamic>),
        ),
        lines: $checkedConvert(
          'lines',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => UsageLine.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const [],
        ),
      );
      return val;
    });

Map<String, dynamic> _$UsageSummaryToJson(_UsageSummary instance) => <String, dynamic>{
  'status': _$SubscriptionStateEnumMap[instance.status],
  'restricted': instance.restricted,
  'plan': instance.plan?.toJson(),
  'lines': instance.lines.map((e) => e.toJson()).toList(),
};

_AcademyPlan _$AcademyPlanFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AcademyPlan', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['enforced', 'status', 'restricted', 'features', 'lastFeatures'],
      );
      final val = _AcademyPlan(
        enforced: $checkedConvert('enforced', (v) => v as bool? ?? false),
        status: $checkedConvert(
          'status',
          (v) => $enumDecodeNullable(
            _$SubscriptionStateEnumMap,
            v,
            unknownValue: SubscriptionState.unknown,
          ),
        ),
        restricted: $checkedConvert('restricted', (v) => v as bool? ?? false),
        plan: $checkedConvert(
          'plan',
          (v) => v == null ? null : PlanSummary.fromJson(v as Map<String, dynamic>),
        ),
        features: $checkedConvert(
          'features',
          (v) => v == null ? const [] : const _FeatureKeysConverter().fromJson(v as List?),
        ),
        lastFeatures: $checkedConvert(
          'lastFeatures',
          (v) => v == null ? const [] : const _FeatureKeysConverter().fromJson(v as List?),
        ),
        trialEndsAt: $checkedConvert(
          'trialEndsAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        renewsAt: $checkedConvert(
          'renewsAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AcademyPlanToJson(_AcademyPlan instance) => <String, dynamic>{
  'enforced': instance.enforced,
  'status': _$SubscriptionStateEnumMap[instance.status],
  'restricted': instance.restricted,
  'plan': instance.plan?.toJson(),
  'features': const _FeatureKeysConverter().toJson(instance.features),
  'lastFeatures': const _FeatureKeysConverter().toJson(instance.lastFeatures),
  'trialEndsAt': const NullableUtcDateTimeConverter().toJson(instance.trialEndsAt),
  'renewsAt': const NullableUtcDateTimeConverter().toJson(instance.renewsAt),
};
