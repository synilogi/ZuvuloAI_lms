import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/verify/verify.dart';

/// Contract tests (§23) for public certificate verification, against what the real API returned.
Map<String, dynamic> _json(String path) =>
    jsonDecode(File('test/fixtures/$path').readAsStringSync()) as Map<String, dynamic>;

void main() {
  test('a seeded issued certificate parses and reads as valid', () {
    final raw = _json('certificates/verify-valid.json');
    final result = VerifiedCertificate.fromJson(raw);

    expect(result.certificate.credentialId, 'SA-JY-2026-00142');
    expect(result.certificate.status, IssuedCertificateStatus.issued);
    expect(result.student.name, 'Ananya Rao');
    expect(result.courseTitle, 'The 27 Nakshatras in Depth');
    expect(result.levelTitle, 'Intermediate');
    expect(result.certificate.finalScore, 91);
    expect(result.certificate.hours, 6);
    expect(result.certificate.issuedAt, isNotNull);
    expect(result.isValid, isTrue);
    expect(result.isRevoked, isFalse);
  });

  test("the learner's email is sent and is not modelled — it can never be displayed", () {
    final raw = _json('certificates/verify-valid.json');
    final result = VerifiedCertificate.fromJson(raw);

    expect((raw['student']! as Map<String, dynamic>).containsKey('email'), isTrue);
    expect(result.student.toJson().containsKey('email'), isFalse);
    expect(result.student.city, 'Bengaluru');
  });

  test('the template the certificate was printed from parses', () {
    final result = VerifiedCertificate.fromJson(_json('certificates/verify-valid.json'));

    expect(result.template?.heading, 'Certificate of Completion');
    expect(result.template?.accent, CertificateAccentValue.emerald);
    expect(result.template?.signatories, isNotEmpty);
  });

  test('a pending certificate and an unknown ID answer the same 404 message', () {
    // Unknown, pending and "the academy switched verification off" are deliberately the same.
    expect(
      _json('errors/verify-pending.json')['message'],
      'No certificate matches this credential ID.',
    );
    expect(
      _json('errors/verify-not-found.json')['message'],
      _json('errors/verify-pending.json')['message'],
    );
  });

  test('revoked and expired are the server\'s verdict, never a date the app compares', () {
    final valid = VerifiedCertificate.fromJson(_json('certificates/verify-valid.json'));

    final revoked = valid.copyWith(
      certificate: valid.certificate.copyWith(
        status: IssuedCertificateStatus.revoked,
        revokedReason: 'Issued in error.',
      ),
    );
    expect(revoked.isRevoked, isTrue);
    expect(revoked.isValid, isFalse);

    // `expired` comes from the academy's validity setting; a `validUntil` alone decides nothing.
    final expired = valid.copyWith(expired: true, validUntil: DateTime.utc(2026, 1, 1));
    expect(expired.isValid, isFalse);
    final stillValid = valid.copyWith(validUntil: DateTime.utc(2020));
    expect(stillValid.isValid, isTrue);
  });

  test('a status this build does not know decodes to unknown', () {
    final result = VerifiedCertificate.fromJson({
      ..._json('certificates/verify-valid.json'),
      'certificate': {
        ...(_json('certificates/verify-valid.json')['certificate']! as Map<String, dynamic>),
        'status': 'superseded',
      },
    });

    expect(result.certificate.status, IssuedCertificateStatus.unknown);
  });
}
