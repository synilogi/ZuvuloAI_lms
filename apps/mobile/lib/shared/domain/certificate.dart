import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/json.dart';

part 'certificate.freezed.dart';
part 'certificate.g.dart';

/// `IssuedCertificateStatus` (`packages/domain/src/certificate.ts`).
enum CertificateStatus { issued, pending, revoked, unknown }

/// One step towards a certificate or a rank, as the **academy** counts it
/// (`CertificateCriterion`). Both numbers come from the server; nothing here is worked out by the
/// app (§18).
@freezed
abstract class CertificateCriterion with _$CertificateCriterion {
  const factory CertificateCriterion({
    @Default('') String id,
    @Default('') String label,
    @Default(0) double current,

    /// The route calls this `required`, which is a reserved name here.
    @JsonKey(name: 'required') @Default(0) double needed,

    /// "%", "sessions" — how to read the numbers.
    String? unit,
  }) = _CertificateCriterion;

  const CertificateCriterion._();

  factory CertificateCriterion.fromJson(Map<String, dynamic> json) =>
      _$CertificateCriterionFromJson(json);

  /// 0–1 towards this criterion; a criterion with nothing required is already met.
  double get fraction => needed <= 0 ? 1 : (current / needed).clamp(0.0, 1.0);

  bool get met => current >= needed;
}

/// `CertificateRecord` — a course's certificate as a learner stands with it: issued (with its
/// credential id), or the criteria still to meet.
@freezed
abstract class CertificateRecord with _$CertificateRecord {
  const factory CertificateRecord({
    @Default('') String id,
    @Default('') String courseId,
    @Default('') String title,
    @Default(<CertificateCriterion>[]) List<CertificateCriterion> criteria,
    @NullableUtcDateTimeConverter() DateTime? issuedAt,

    /// Set once the academy has issued it.
    String? credentialId,
  }) = _CertificateRecord;

  const CertificateRecord._();

  factory CertificateRecord.fromJson(Map<String, dynamic> json) =>
      _$CertificateRecordFromJson(json);

  bool get issued => credentialId != null;

  /// Every criterion met — the academy's own verdict on eligibility, not a date this app compares.
  bool get eligible => criteria.every((criterion) => criterion.met);

  /// Mean completion across the criteria, 0–1, for "how close am I" displays
  /// (`criteriaPercent`).
  double get fraction => criteria.isEmpty
      ? 1
      : criteria.fold<double>(0, (sum, c) => sum + c.fraction) / criteria.length;
}

/// A name and title printed under the signature line. Named apart from the design system's own
/// `CertificateSignatory`, which is what the canvas draws.
@freezed
abstract class TemplateSignatory with _$TemplateSignatory {
  const factory TemplateSignatory({@Default('') String name, @Default('') String title}) =
      _TemplateSignatory;

  factory TemplateSignatory.fromJson(Map<String, dynamic> json) =>
      _$TemplateSignatoryFromJson(json);
}

/// The template a certificate is printed on. `accent` and `style` are the academy's design choices
/// and are mapped onto the app's own tokens — never to a colour from the server.
@freezed
abstract class CertificateTemplateInfo with _$CertificateTemplateInfo {
  const factory CertificateTemplateInfo({
    @Default('') String id,
    @Default('') String name,
    @Default('classic') String style,
    @Default('indigo') String accent,
    @Default('') String heading,

    /// The line under the learner's name, before the course title.
    @Default('') String statement,
    @Default(<TemplateSignatory>[]) List<TemplateSignatory> signatories,
    @Default(false) bool showScore,
    @Default(false) bool showHours,
  }) = _CertificateTemplateInfo;

  factory CertificateTemplateInfo.fromJson(Map<String, dynamic> json) =>
      _$CertificateTemplateInfoFromJson(json);
}

/// The certificate itself, as the academy issued it.
@freezed
abstract class IssuedCertificate with _$IssuedCertificate {
  const factory IssuedCertificate({
    required String id,
    @Default('') String credentialId,
    @Default('') String courseId,
    @Default('') String title,
    @JsonKey(unknownEnumValue: CertificateStatus.unknown)
    @Default(CertificateStatus.unknown)
    CertificateStatus status,
    @UtcDateTimeConverter() required DateTime completedAt,
    @NullableUtcDateTimeConverter() DateTime? issuedAt,
    @NullableUtcDateTimeConverter() DateTime? revokedAt,
    String? revokedReason,

    /// 0–100, when the academy prints it.
    int? finalScore,
    @Default(0) num hours,

    /// Times the public verification link has been opened.
    @Default(0) int verifications,
  }) = _IssuedCertificate;

  const IssuedCertificate._();

  factory IssuedCertificate.fromJson(Map<String, dynamic> json) =>
      _$IssuedCertificateFromJson(json);

  bool get isPending => status == CertificateStatus.pending;

  bool get isRevoked => status == CertificateStatus.revoked;
}

/// The learner a certificate names. Their e-mail is deliberately **not** modelled: the route sends
/// it, and nothing about sharing a credential may carry it (§18). Named apart from the verify
/// feature's own holder model, which reads a different route.
@freezed
abstract class CertificateLearner with _$CertificateLearner {
  const factory CertificateLearner({@Default('') String name, @Default('') String city}) =
      _CertificateLearner;

  factory CertificateLearner.fromJson(Map<String, dynamic> json) =>
      _$CertificateLearnerFromJson(json);
}

/// `GET /learning/certificates/:id` — everything the certificate is printed from, plus the public
/// verification path the academy itself built.
@freezed
abstract class CertificateDetail with _$CertificateDetail {
  const factory CertificateDetail({
    required IssuedCertificate certificate,
    @Default(CertificateLearner()) CertificateLearner student,
    @Default('') String courseTitle,
    @Default('') String levelTitle,
    CertificateTemplateInfo? template,

    /// Always `/verify/<credentialId>`, relative to the **web** app (§13).
    @Default('') String verifyUrl,
  }) = _CertificateDetail;

  factory CertificateDetail.fromJson(Map<String, dynamic> json) =>
      _$CertificateDetailFromJson(json);
}

/// `GET /learning/certificates` — the wallet in the academy's own three groups.
@freezed
abstract class CertificateWallet with _$CertificateWallet {
  const factory CertificateWallet({
    @Default(<CertificateDetail>[]) List<CertificateDetail> issued,
    @Default(<CertificateDetail>[]) List<CertificateDetail> pending,
    @Default(<CertificateRecord>[]) List<CertificateRecord> working,
  }) = _CertificateWallet;

  const CertificateWallet._();

  factory CertificateWallet.fromJson(Map<String, dynamic> json) =>
      _$CertificateWalletFromJson(json);

  bool get isEmpty => issued.isEmpty && pending.isEmpty && working.isEmpty;
}
