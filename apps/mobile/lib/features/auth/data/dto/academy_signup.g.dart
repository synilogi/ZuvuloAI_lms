// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_signup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SignupPending _$SignupPendingFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_SignupPending', json, ($checkedConvert) {
      final val = _SignupPending(
        signupId: $checkedConvert('signupId', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
        expiresAt: $checkedConvert(
          'expiresAt',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
        resendAvailableAt: $checkedConvert(
          'resendAvailableAt',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SignupPendingToJson(_SignupPending instance) => <String, dynamic>{
  'signupId': instance.signupId,
  'email': instance.email,
  'expiresAt': const UtcDateTimeConverter().toJson(instance.expiresAt),
  'resendAvailableAt': const UtcDateTimeConverter().toJson(instance.resendAvailableAt),
};
