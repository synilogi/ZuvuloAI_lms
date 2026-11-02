// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_verification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VerificationPending _$VerificationPendingFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_VerificationPending', json, ($checkedConvert) {
      final val = _VerificationPending(
        verificationId: $checkedConvert('verificationId', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
        role: $checkedConvert('role', (v) => v as String? ?? 'student'),
        lms: $checkedConvert('lms', (v) => v as String? ?? ''),
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

Map<String, dynamic> _$VerificationPendingToJson(_VerificationPending instance) =>
    <String, dynamic>{
      'verificationId': instance.verificationId,
      'email': instance.email,
      'role': instance.role,
      'lms': instance.lms,
      'expiresAt': const UtcDateTimeConverter().toJson(instance.expiresAt),
      'resendAvailableAt': const UtcDateTimeConverter().toJson(instance.resendAvailableAt),
    };
