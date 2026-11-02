import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';

part 'verified_certificate.freezed.dart';
part 'verified_certificate.g.dart';

/// `IssuedCertificateStatus`. A `pending` certificate never reaches the app — the route answers
/// 404 for it — but the value is read rather than assumed.
enum IssuedCertificateStatus { issued, pending, revoked, unknown }

/// `CertificateAccent` — the template's colour family.
enum CertificateAccentValue { emerald, saffron, indigo, unknown }

@freezed
abstract class CertificateSignatoryDto with _$CertificateSignatoryDto {
  const factory CertificateSignatoryDto({required String name, @Default('') String title}) =
      _CertificateSignatoryDto;

  factory CertificateSignatoryDto.fromJson(Map<String, dynamic> json) =>
      _$CertificateSignatoryDtoFromJson(json);
}

/// The template the certificate was printed from.
@freezed
abstract class CertificateTemplateDto with _$CertificateTemplateDto {
  const factory CertificateTemplateDto({
    required String id,
    @Default('') String name,
    @Default('') String heading,
    @Default('') String statement,
    @JsonKey(unknownEnumValue: CertificateAccentValue.unknown)
    @Default(CertificateAccentValue.emerald)
    CertificateAccentValue accent,
    @Default(<CertificateSignatoryDto>[]) List<CertificateSignatoryDto> signatories,
    @Default(false) bool showScore,
    @Default(false) bool showHours,
  }) = _CertificateTemplateDto;

  factory CertificateTemplateDto.fromJson(Map<String, dynamic> json) =>
      _$CertificateTemplateDtoFromJson(json);
}

@freezed
abstract class IssuedCertificateDto with _$IssuedCertificateDto {
  const factory IssuedCertificateDto({
    required String id,
    required String credentialId,
    @Default('') String title,
    @JsonKey(unknownEnumValue: IssuedCertificateStatus.unknown)
    @Default(IssuedCertificateStatus.issued)
    IssuedCertificateStatus status,
    @UtcDateTimeConverter() required DateTime completedAt,
    @NullableUtcDateTimeConverter() DateTime? issuedAt,
    @NullableUtcDateTimeConverter() DateTime? revokedAt,
    String? revokedReason,
    int? finalScore,

    /// The academy rounds study hours to the nearest half hour, so this is not always whole.
    @Default(0) num hours,
  }) = _IssuedCertificateDto;

  factory IssuedCertificateDto.fromJson(Map<String, dynamic> json) =>
      _$IssuedCertificateDtoFromJson(json);
}

/// The learner a certificate names. Their email is deliberately not modelled: the route sends it
/// and public verification must never show it (FLUTTER-008 spec, §18).
@freezed
abstract class CertificateHolder with _$CertificateHolder {
  const factory CertificateHolder({required String name, @Default('') String city}) =
      _CertificateHolder;

  factory CertificateHolder.fromJson(Map<String, dynamic> json) =>
      _$CertificateHolderFromJson(json);
}

/// `GET /certificates/verify/:credentialId`. The academy decides validity: `expired` and
/// `validUntil` come from its settings, never from a date the app works out (§18).
@freezed
abstract class VerifiedCertificate with _$VerifiedCertificate {
  const factory VerifiedCertificate({
    required IssuedCertificateDto certificate,
    required CertificateHolder student,
    @Default('') String courseTitle,
    @Default('') String levelTitle,
    CertificateTemplateDto? template,
    @NullableUtcDateTimeConverter() DateTime? validUntil,
    @Default(false) bool expired,
  }) = _VerifiedCertificate;

  const VerifiedCertificate._();

  factory VerifiedCertificate.fromJson(Map<String, dynamic> json) =>
      _$VerifiedCertificateFromJson(json);

  bool get isRevoked => certificate.status == IssuedCertificateStatus.revoked;

  /// Valid means the academy issued it, has not withdrawn it, and its validity has not run out.
  bool get isValid => !isRevoked && !expired;
}
