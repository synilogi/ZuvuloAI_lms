// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verified_certificate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CertificateSignatoryDto _$CertificateSignatoryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CertificateSignatoryDto', json, ($checkedConvert) {
      final val = _CertificateSignatoryDto(
        name: $checkedConvert('name', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$CertificateSignatoryDtoToJson(_CertificateSignatoryDto instance) =>
    <String, dynamic>{'name': instance.name, 'title': instance.title};

_CertificateTemplateDto _$CertificateTemplateDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CertificateTemplateDto', json, ($checkedConvert) {
      final val = _CertificateTemplateDto(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        heading: $checkedConvert('heading', (v) => v as String? ?? ''),
        statement: $checkedConvert('statement', (v) => v as String? ?? ''),
        accent: $checkedConvert(
          'accent',
          (v) =>
              $enumDecodeNullable(
                _$CertificateAccentValueEnumMap,
                v,
                unknownValue: CertificateAccentValue.unknown,
              ) ??
              CertificateAccentValue.emerald,
        ),
        signatories: $checkedConvert(
          'signatories',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CertificateSignatoryDto.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <CertificateSignatoryDto>[],
        ),
        showScore: $checkedConvert('showScore', (v) => v as bool? ?? false),
        showHours: $checkedConvert('showHours', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$CertificateTemplateDtoToJson(_CertificateTemplateDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'heading': instance.heading,
      'statement': instance.statement,
      'accent': _$CertificateAccentValueEnumMap[instance.accent]!,
      'signatories': instance.signatories.map((e) => e.toJson()).toList(),
      'showScore': instance.showScore,
      'showHours': instance.showHours,
    };

const _$CertificateAccentValueEnumMap = {
  CertificateAccentValue.emerald: 'emerald',
  CertificateAccentValue.saffron: 'saffron',
  CertificateAccentValue.indigo: 'indigo',
  CertificateAccentValue.unknown: 'unknown',
};

_IssuedCertificateDto _$IssuedCertificateDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_IssuedCertificateDto', json, ($checkedConvert) {
      final val = _IssuedCertificateDto(
        id: $checkedConvert('id', (v) => v as String),
        credentialId: $checkedConvert('credentialId', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(
                _$IssuedCertificateStatusEnumMap,
                v,
                unknownValue: IssuedCertificateStatus.unknown,
              ) ??
              IssuedCertificateStatus.issued,
        ),
        completedAt: $checkedConvert(
          'completedAt',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
        issuedAt: $checkedConvert(
          'issuedAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        revokedAt: $checkedConvert(
          'revokedAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        revokedReason: $checkedConvert('revokedReason', (v) => v as String?),
        finalScore: $checkedConvert('finalScore', (v) => (v as num?)?.toInt()),
        hours: $checkedConvert('hours', (v) => v as num? ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$IssuedCertificateDtoToJson(_IssuedCertificateDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'credentialId': instance.credentialId,
      'title': instance.title,
      'status': _$IssuedCertificateStatusEnumMap[instance.status]!,
      'completedAt': const UtcDateTimeConverter().toJson(instance.completedAt),
      'issuedAt': const NullableUtcDateTimeConverter().toJson(instance.issuedAt),
      'revokedAt': const NullableUtcDateTimeConverter().toJson(instance.revokedAt),
      'revokedReason': instance.revokedReason,
      'finalScore': instance.finalScore,
      'hours': instance.hours,
    };

const _$IssuedCertificateStatusEnumMap = {
  IssuedCertificateStatus.issued: 'issued',
  IssuedCertificateStatus.pending: 'pending',
  IssuedCertificateStatus.revoked: 'revoked',
  IssuedCertificateStatus.unknown: 'unknown',
};

_CertificateHolder _$CertificateHolderFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CertificateHolder', json, ($checkedConvert) {
      final val = _CertificateHolder(
        name: $checkedConvert('name', (v) => v as String),
        city: $checkedConvert('city', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$CertificateHolderToJson(_CertificateHolder instance) => <String, dynamic>{
  'name': instance.name,
  'city': instance.city,
};

_VerifiedCertificate _$VerifiedCertificateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_VerifiedCertificate', json, ($checkedConvert) {
      final val = _VerifiedCertificate(
        certificate: $checkedConvert(
          'certificate',
          (v) => IssuedCertificateDto.fromJson(v as Map<String, dynamic>),
        ),
        student: $checkedConvert(
          'student',
          (v) => CertificateHolder.fromJson(v as Map<String, dynamic>),
        ),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
        levelTitle: $checkedConvert('levelTitle', (v) => v as String? ?? ''),
        template: $checkedConvert(
          'template',
          (v) => v == null ? null : CertificateTemplateDto.fromJson(v as Map<String, dynamic>),
        ),
        validUntil: $checkedConvert(
          'validUntil',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        expired: $checkedConvert('expired', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$VerifiedCertificateToJson(_VerifiedCertificate instance) =>
    <String, dynamic>{
      'certificate': instance.certificate.toJson(),
      'student': instance.student.toJson(),
      'courseTitle': instance.courseTitle,
      'levelTitle': instance.levelTitle,
      'template': instance.template?.toJson(),
      'validUntil': const NullableUtcDateTimeConverter().toJson(instance.validUntil),
      'expired': instance.expired,
    };
