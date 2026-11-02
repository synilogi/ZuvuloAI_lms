// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'certificate_register.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CertificateRegisterRow _$CertificateRegisterRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CertificateRegisterRow', json, ($checkedConvert) {
      final val = _CertificateRegisterRow(
        certificate: $checkedConvert(
          'certificate',
          (v) => IssuedCertificate.fromJson(v as Map<String, dynamic>),
        ),
        studentName: $checkedConvert('studentName', (v) => v as String? ?? ''),
        studentEmail: $checkedConvert('studentEmail', (v) => v as String? ?? ''),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$CertificateRegisterRowToJson(_CertificateRegisterRow instance) =>
    <String, dynamic>{
      'certificate': instance.certificate.toJson(),
      'studentName': instance.studentName,
      'studentEmail': instance.studentEmail,
      'courseTitle': instance.courseTitle,
    };

_CertificateRegister _$CertificateRegisterFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CertificateRegister', json, ($checkedConvert) {
      final val = _CertificateRegister(
        rows: $checkedConvert(
          'rows',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CertificateRegisterRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <CertificateRegisterRow>[],
        ),
        total: $checkedConvert('total', (v) => (v as num?)?.toInt() ?? 0),
        counts: $checkedConvert(
          'counts',
          (v) =>
              (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, (e as num).toInt())) ??
              const <String, int>{},
        ),
      );
      return val;
    });

Map<String, dynamic> _$CertificateRegisterToJson(_CertificateRegister instance) =>
    <String, dynamic>{
      'rows': instance.rows.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'counts': instance.counts,
    };

_RegisterLearner _$RegisterLearnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_RegisterLearner', json, ($checkedConvert) {
      final val = _RegisterLearner(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        email: $checkedConvert('email', (v) => v as String? ?? ''),
        city: $checkedConvert('city', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$RegisterLearnerToJson(_RegisterLearner instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'city': instance.city,
};

_StaffCertificateDetail _$StaffCertificateDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StaffCertificateDetail', json, ($checkedConvert) {
      final val = _StaffCertificateDetail(
        certificate: $checkedConvert(
          'certificate',
          (v) => IssuedCertificate.fromJson(v as Map<String, dynamic>),
        ),
        student: $checkedConvert(
          'student',
          (v) => v == null
              ? const RegisterLearner()
              : RegisterLearner.fromJson(v as Map<String, dynamic>),
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

Map<String, dynamic> _$StaffCertificateDetailToJson(_StaffCertificateDetail instance) =>
    <String, dynamic>{
      'certificate': instance.certificate.toJson(),
      'student': instance.student.toJson(),
      'courseTitle': instance.courseTitle,
      'levelTitle': instance.levelTitle,
      'template': instance.template?.toJson(),
      'verifyUrl': instance.verifyUrl,
    };
