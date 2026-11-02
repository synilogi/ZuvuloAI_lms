// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'certificate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CertificateCriterion _$CertificateCriterionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CertificateCriterion', json, ($checkedConvert) {
      final val = _CertificateCriterion(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        label: $checkedConvert('label', (v) => v as String? ?? ''),
        current: $checkedConvert('current', (v) => (v as num?)?.toDouble() ?? 0),
        needed: $checkedConvert('required', (v) => (v as num?)?.toDouble() ?? 0),
        unit: $checkedConvert('unit', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'needed': 'required'});

Map<String, dynamic> _$CertificateCriterionToJson(_CertificateCriterion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'current': instance.current,
      'required': instance.needed,
      'unit': instance.unit,
    };

_CertificateRecord _$CertificateRecordFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CertificateRecord', json, ($checkedConvert) {
      final val = _CertificateRecord(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        courseId: $checkedConvert('courseId', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        criteria: $checkedConvert(
          'criteria',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CertificateCriterion.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <CertificateCriterion>[],
        ),
        issuedAt: $checkedConvert(
          'issuedAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        credentialId: $checkedConvert('credentialId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CertificateRecordToJson(_CertificateRecord instance) => <String, dynamic>{
  'id': instance.id,
  'courseId': instance.courseId,
  'title': instance.title,
  'criteria': instance.criteria.map((e) => e.toJson()).toList(),
  'issuedAt': const NullableUtcDateTimeConverter().toJson(instance.issuedAt),
  'credentialId': instance.credentialId,
};

_TemplateSignatory _$TemplateSignatoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_TemplateSignatory', json, ($checkedConvert) {
      final val = _TemplateSignatory(
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$TemplateSignatoryToJson(_TemplateSignatory instance) => <String, dynamic>{
  'name': instance.name,
  'title': instance.title,
};

_CertificateTemplateInfo _$CertificateTemplateInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CertificateTemplateInfo', json, ($checkedConvert) {
      final val = _CertificateTemplateInfo(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        style: $checkedConvert('style', (v) => v as String? ?? 'classic'),
        accent: $checkedConvert('accent', (v) => v as String? ?? 'indigo'),
        heading: $checkedConvert('heading', (v) => v as String? ?? ''),
        statement: $checkedConvert('statement', (v) => v as String? ?? ''),
        signatories: $checkedConvert(
          'signatories',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => TemplateSignatory.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <TemplateSignatory>[],
        ),
        showScore: $checkedConvert('showScore', (v) => v as bool? ?? false),
        showHours: $checkedConvert('showHours', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$CertificateTemplateInfoToJson(_CertificateTemplateInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'style': instance.style,
      'accent': instance.accent,
      'heading': instance.heading,
      'statement': instance.statement,
      'signatories': instance.signatories.map((e) => e.toJson()).toList(),
      'showScore': instance.showScore,
      'showHours': instance.showHours,
    };

_IssuedCertificate _$IssuedCertificateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_IssuedCertificate', json, ($checkedConvert) {
      final val = _IssuedCertificate(
        id: $checkedConvert('id', (v) => v as String),
        credentialId: $checkedConvert('credentialId', (v) => v as String? ?? ''),
        courseId: $checkedConvert('courseId', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(
                _$CertificateStatusEnumMap,
                v,
                unknownValue: CertificateStatus.unknown,
              ) ??
              CertificateStatus.unknown,
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
        verifications: $checkedConvert('verifications', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$IssuedCertificateToJson(_IssuedCertificate instance) => <String, dynamic>{
  'id': instance.id,
  'credentialId': instance.credentialId,
  'courseId': instance.courseId,
  'title': instance.title,
  'status': _$CertificateStatusEnumMap[instance.status]!,
  'completedAt': const UtcDateTimeConverter().toJson(instance.completedAt),
  'issuedAt': const NullableUtcDateTimeConverter().toJson(instance.issuedAt),
  'revokedAt': const NullableUtcDateTimeConverter().toJson(instance.revokedAt),
  'revokedReason': instance.revokedReason,
  'finalScore': instance.finalScore,
  'hours': instance.hours,
  'verifications': instance.verifications,
};

const _$CertificateStatusEnumMap = {
  CertificateStatus.issued: 'issued',
  CertificateStatus.pending: 'pending',
  CertificateStatus.revoked: 'revoked',
  CertificateStatus.unknown: 'unknown',
};

_CertificateLearner _$CertificateLearnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CertificateLearner', json, ($checkedConvert) {
      final val = _CertificateLearner(
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        city: $checkedConvert('city', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$CertificateLearnerToJson(_CertificateLearner instance) => <String, dynamic>{
  'name': instance.name,
  'city': instance.city,
};

_CertificateDetail _$CertificateDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CertificateDetail', json, ($checkedConvert) {
      final val = _CertificateDetail(
        certificate: $checkedConvert(
          'certificate',
          (v) => IssuedCertificate.fromJson(v as Map<String, dynamic>),
        ),
        student: $checkedConvert(
          'student',
          (v) => v == null
              ? const CertificateLearner()
              : CertificateLearner.fromJson(v as Map<String, dynamic>),
        ),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
        levelTitle: $checkedConvert('levelTitle', (v) => v as String? ?? ''),
        template: $checkedConvert(
          'template',
          (v) => v == null ? null : CertificateTemplateInfo.fromJson(v as Map<String, dynamic>),
        ),
        verifyUrl: $checkedConvert('verifyUrl', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$CertificateDetailToJson(_CertificateDetail instance) => <String, dynamic>{
  'certificate': instance.certificate.toJson(),
  'student': instance.student.toJson(),
  'courseTitle': instance.courseTitle,
  'levelTitle': instance.levelTitle,
  'template': instance.template?.toJson(),
  'verifyUrl': instance.verifyUrl,
};

_CertificateWallet _$CertificateWalletFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CertificateWallet', json, ($checkedConvert) {
      final val = _CertificateWallet(
        issued: $checkedConvert(
          'issued',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CertificateDetail.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <CertificateDetail>[],
        ),
        pending: $checkedConvert(
          'pending',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CertificateDetail.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <CertificateDetail>[],
        ),
        working: $checkedConvert(
          'working',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CertificateRecord.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <CertificateRecord>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$CertificateWalletToJson(_CertificateWallet instance) => <String, dynamic>{
  'issued': instance.issued.map((e) => e.toJson()).toList(),
  'pending': instance.pending.map((e) => e.toJson()).toList(),
  'working': instance.working.map((e) => e.toJson()).toList(),
};
