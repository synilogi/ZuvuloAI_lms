import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/domain/certificate.dart';

part 'certificate_register.freezed.dart';
part 'certificate_register.g.dart';

/// `apps/api/src/routes/certificates.ts` — the academy's credential register as staff read it. The
/// certificate itself, its template and the learner it names are the shared models FLUTTER-014
/// already reads; a register row adds what only staff are served: the learner's e-mail, which the
/// search matches on and which never travels with a shared credential (§18).

/// One row of `GET /certificates`.
@freezed
abstract class CertificateRegisterRow with _$CertificateRegisterRow {
  const factory CertificateRegisterRow({
    required IssuedCertificate certificate,
    @Default('') String studentName,
    @Default('') String studentEmail,
    @Default('') String courseTitle,
  }) = _CertificateRegisterRow;

  factory CertificateRegisterRow.fromJson(Map<String, dynamic> json) =>
      _$CertificateRegisterRowFromJson(json);
}

/// `GET /certificates` — one page of the register, with the academy's own counts for the whole of it.
@freezed
abstract class CertificateRegister with _$CertificateRegister {
  const factory CertificateRegister({
    @Default(<CertificateRegisterRow>[]) List<CertificateRegisterRow> rows,
    @Default(0) int total,
    @Default(<String, int>{}) Map<String, int> counts,
  }) = _CertificateRegister;

  const CertificateRegister._();

  factory CertificateRegister.fromJson(Map<String, dynamic> json) =>
      _$CertificateRegisterFromJson(json);

  /// The count behind a status tab, or behind `all`.
  int countOf(String status) => counts[status] ?? 0;

  /// The rows whose certificate is waiting to be issued.
  List<CertificateRegisterRow> get pending =>
      rows.where((r) => r.certificate.isPending).toList(growable: false);
}

/// The learner a certificate names, as **staff** are served them. The learner-facing
/// `CertificateLearner` deliberately carries no e-mail address, because nothing about sharing a
/// credential may carry one (§18); the register's search matches on it, so staff get their own model
/// rather than the shared one being widened.
@freezed
abstract class RegisterLearner with _$RegisterLearner {
  const factory RegisterLearner({
    @Default('') String id,
    @Default('') String name,
    @Default('') String email,
    @Default('') String city,
  }) = _RegisterLearner;

  factory RegisterLearner.fromJson(Map<String, dynamic> json) => _$RegisterLearnerFromJson(json);
}

/// `GET /certificates/:id` — everything the certificate is printed from, the learner it names, and
/// the public verification path the academy itself built.
@freezed
abstract class StaffCertificateDetail with _$StaffCertificateDetail {
  const factory StaffCertificateDetail({
    required IssuedCertificate certificate,
    @Default(RegisterLearner()) RegisterLearner student,
    @Default('') String courseTitle,
    @Default('') String levelTitle,
    CertificateTemplateInfo? template,

    /// Always `/verify/<credentialId>`, relative to the **web** app (§13).
    @Default('') String verifyUrl,
  }) = _StaffCertificateDetail;

  const StaffCertificateDetail._();

  factory StaffCertificateDetail.fromJson(Map<String, dynamic> json) =>
      _$StaffCertificateDetailFromJson(json);

  /// The learner-facing detail this certificate prints as, so the canvas FLUTTER-014 already draws
  /// renders the staff copy without a second implementation — and without the e-mail reaching it.
  CertificateDetail get asPrinted => CertificateDetail(
    certificate: certificate,
    student: CertificateLearner(name: student.name, city: student.city),
    courseTitle: courseTitle,
    levelTitle: levelTitle,
    template: template,
    verifyUrl: verifyUrl,
  );
}

/// The shortest revocation reason `POST /certificates/:id/revoke` will take. Below it the route
/// answers **400 with a message and no field**, so the screen checks the length itself and never
/// sends a reason it knows will be refused (finding 31).
const minRevokeReason = 3;

/// The longest the route's schema will take.
const maxRevokeReason = 1000;

/// Whether a revocation reason is one the academy will accept.
bool revokeReasonIsEnough(String reason) {
  final trimmed = reason.trim();
  return trimmed.length >= minRevokeReason && trimmed.length <= maxRevokeReason;
}
