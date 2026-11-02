// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_purchase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CoursePurchase _$CoursePurchaseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CoursePurchase', json, ($checkedConvert) {
      final val = _CoursePurchase(
        id: $checkedConvert('id', (v) => v as String),
        courseId: $checkedConvert('courseId', (v) => v as String? ?? ''),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(
                _$CoursePurchaseStatusEnumMap,
                v,
                unknownValue: CoursePurchaseStatus.unknown,
              ) ??
              CoursePurchaseStatus.unknown,
        ),
        amount: $checkedConvert('amount', (v) => (v as num?)?.toInt() ?? 0),
        currency: $checkedConvert('currency', (v) => v as String? ?? 'INR'),
        listPrice: $checkedConvert('listPrice', (v) => (v as num?)?.toInt() ?? 0),
        enrolled: $checkedConvert('enrolled', (v) => v as bool? ?? false),
        failureMessage: $checkedConvert('failureMessage', (v) => v as String?),
        needsReview: $checkedConvert('needsReview', (v) => v as bool? ?? false),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        paidAt: $checkedConvert(
          'paidAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CoursePurchaseToJson(_CoursePurchase instance) => <String, dynamic>{
  'id': instance.id,
  'courseId': instance.courseId,
  'courseTitle': instance.courseTitle,
  'status': _$CoursePurchaseStatusEnumMap[instance.status]!,
  'amount': instance.amount,
  'currency': instance.currency,
  'listPrice': instance.listPrice,
  'enrolled': instance.enrolled,
  'failureMessage': instance.failureMessage,
  'needsReview': instance.needsReview,
  'createdAt': const NullableUtcDateTimeConverter().toJson(instance.createdAt),
  'paidAt': const NullableUtcDateTimeConverter().toJson(instance.paidAt),
};

const _$CoursePurchaseStatusEnumMap = {
  CoursePurchaseStatus.created: 'created',
  CoursePurchaseStatus.paid: 'paid',
  CoursePurchaseStatus.failed: 'failed',
  CoursePurchaseStatus.expired: 'expired',
  CoursePurchaseStatus.unknown: 'unknown',
};

_CheckoutPrefill _$CheckoutPrefillFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CheckoutPrefill', json, ($checkedConvert) {
      final val = _CheckoutPrefill(
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        email: $checkedConvert('email', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$CheckoutPrefillToJson(_CheckoutPrefill instance) => <String, dynamic>{
  'name': instance.name,
  'email': instance.email,
};

_CourseCheckout _$CourseCheckoutFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CourseCheckout', json, ($checkedConvert) {
      final val = _CourseCheckout(
        provider: $checkedConvert('provider', (v) => v as String? ?? ''),
        keyId: $checkedConvert('keyId', (v) => v as String?),
        orderId: $checkedConvert('orderId', (v) => v as String? ?? ''),
        amount: $checkedConvert('amount', (v) => (v as num?)?.toInt() ?? 0),
        currency: $checkedConvert('currency', (v) => v as String? ?? 'INR'),
        redirectUrl: $checkedConvert('redirectUrl', (v) => v as String?),
        description: $checkedConvert('description', (v) => v as String? ?? ''),
        prefill: $checkedConvert(
          'prefill',
          (v) => v == null ? null : CheckoutPrefill.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CourseCheckoutToJson(_CourseCheckout instance) => <String, dynamic>{
  'provider': instance.provider,
  'keyId': instance.keyId,
  'orderId': instance.orderId,
  'amount': instance.amount,
  'currency': instance.currency,
  'redirectUrl': instance.redirectUrl,
  'description': instance.description,
  'prefill': instance.prefill?.toJson(),
};

_CoursePurchaseStart _$CoursePurchaseStartFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CoursePurchaseStart', json, ($checkedConvert) {
      final val = _CoursePurchaseStart(
        purchase: $checkedConvert(
          'purchase',
          (v) => CoursePurchase.fromJson(v as Map<String, dynamic>),
        ),
        checkout: $checkedConvert(
          'checkout',
          (v) => CourseCheckout.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CoursePurchaseStartToJson(_CoursePurchaseStart instance) =>
    <String, dynamic>{
      'purchase': instance.purchase.toJson(),
      'checkout': instance.checkout.toJson(),
    };

_PurchaseOutcome _$PurchaseOutcomeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_PurchaseOutcome', json, ($checkedConvert) {
      final val = _PurchaseOutcome(
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(
                _$PurchaseOutcomeStatusEnumMap,
                v,
                unknownValue: PurchaseOutcomeStatus.unknown,
              ) ??
              PurchaseOutcomeStatus.unknown,
        ),
        enrolled: $checkedConvert('enrolled', (v) => v as bool? ?? false),
        message: $checkedConvert('message', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$PurchaseOutcomeToJson(_PurchaseOutcome instance) => <String, dynamic>{
  'status': _$PurchaseOutcomeStatusEnumMap[instance.status]!,
  'enrolled': instance.enrolled,
  'message': instance.message,
};

const _$PurchaseOutcomeStatusEnumMap = {
  PurchaseOutcomeStatus.paid: 'paid',
  PurchaseOutcomeStatus.failed: 'failed',
  PurchaseOutcomeStatus.pending: 'pending',
  PurchaseOutcomeStatus.created: 'created',
  PurchaseOutcomeStatus.unknown: 'unknown',
};

_PurchaseConfirmation _$PurchaseConfirmationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_PurchaseConfirmation', json, ($checkedConvert) {
      final val = _PurchaseConfirmation(
        purchase: $checkedConvert(
          'purchase',
          (v) => CoursePurchase.fromJson(v as Map<String, dynamic>),
        ),
        outcome: $checkedConvert(
          'outcome',
          (v) => PurchaseOutcome.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PurchaseConfirmationToJson(_PurchaseConfirmation instance) =>
    <String, dynamic>{'purchase': instance.purchase.toJson(), 'outcome': instance.outcome.toJson()};
