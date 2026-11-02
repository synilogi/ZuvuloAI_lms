import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/certificates/certificates.dart';

/// Contract tests (§23) for the learner's certificates and the academy's rank ladder, against what
/// the real API returned.
Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

void main() {
  group('GET /learning/certificates', () {
    late CertificateWallet wallet;

    setUp(
      () => wallet = CertificateWallet.fromJson(
        _fixture('learning/certificates.json')! as Map<String, dynamic>,
      ),
    );

    test('an issued certificate carries everything it is printed from', () {
      final detail = wallet.issued.single;
      final certificate = detail.certificate;

      expect(certificate.status, CertificateStatus.issued);
      expect(certificate.credentialId, 'SA-JY-2026-00142');
      expect(certificate.issuedAt, isNotNull);
      expect(certificate.issuedAt!.isUtc, isTrue);
      expect(certificate.completedAt.isUtc, isTrue);
      expect(certificate.finalScore, 91);
      expect(certificate.hours, 6);
      expect(certificate.verifications, 5);
      expect(detail.courseTitle, 'The 27 Nakshatras in Depth');
      expect(detail.levelTitle, 'Intermediate');
      expect(detail.student.name, 'Ananya Rao');
      expect(detail.verifyUrl, '/verify/SA-JY-2026-00142');

      final template = detail.template!;
      expect(template.heading, 'Certificate of Completion');
      expect(template.statement, 'has completed the course of study in');
      expect(template.accent, 'emerald');
      expect(template.showScore, isTrue);
      expect(template.showHours, isTrue);
      expect(template.signatories.map((s) => s.name), ['Dr. Meenakshi Iyer', 'Kavita Menon']);
      expect(template.signatories.first.title, 'Director of Studies');
    });

    test('the learner\'s e-mail is dropped even though the route sends it', () {
      final raw =
          ((_fixture('learning/certificates.json')! as Map<String, dynamic>)['issued']!
                      as List<dynamic>)
                  .first
              as Map<String, dynamic>;

      expect((raw['student']! as Map<String, dynamic>).containsKey('email'), isTrue);
      expect(wallet.issued.single.student.toJson().keys, ['name', 'city']);
    });

    test('a course still being worked through carries the academy\'s own criteria', () {
      final record = wallet.working.firstWhere((r) => r.title.contains('Foundations'));

      expect(record.issued, isFalse);
      expect(record.eligible, isFalse);
      final progress = record.criteria.firstWhere((c) => c.id == 'progress');
      expect(progress.label, 'Course progress');
      expect(progress.current, 38);
      expect(progress.needed, 100);
      expect(progress.unit, '%');
      expect(progress.met, isFalse);
      expect(progress.fraction, closeTo(0.38, 0.001));
      // A criterion the learner has already met reads as met, whatever the others say.
      final score = record.criteria.firstWhere((c) => c.id == 'final');
      expect(score.current, 83);
      expect(score.needed, 60);
      expect(score.met, isTrue);
      expect(score.fraction, 1, reason: 'a met criterion is full, never over-full');
    });

    test('a wallet with nothing in it says so', () {
      expect(const CertificateWallet().isEmpty, isTrue);
      expect(wallet.isEmpty, isFalse);
    });
  });

  test('GET /learning/certificates/:id — the same shape, on its own', () {
    final detail = CertificateDetail.fromJson(
      _fixture('learning/certificate-issued.json')! as Map<String, dynamic>,
    );

    expect(detail.certificate.credentialId, 'SA-JY-2026-00142');
    expect(detail.certificate.isPending, isFalse);
    expect(detail.certificate.isRevoked, isFalse);
    expect(detail.template, isNotNull);
  });

  test('a certificate the academy has not issued yet is pending, with no issue date', () {
    // The same shape the route sends, before the learner claims it.
    final raw = Map<String, dynamic>.from(
      _fixture('learning/certificate-issued.json')! as Map<String, dynamic>,
    );
    final certificate = Map<String, dynamic>.from(raw['certificate']! as Map<String, dynamic>)
      ..['status'] = 'pending'
      ..remove('issuedAt');
    final detail = CertificateDetail.fromJson({...raw, 'certificate': certificate});

    expect(detail.certificate.isPending, isTrue);
    expect(detail.certificate.issuedAt, isNull);
    expect(detail.certificate.completedAt, isNotNull);
  });

  group('GET /learning/rank-ladder', () {
    late RankLadder ladder;

    setUp(
      () => ladder = RankLadder.fromJson(
        _fixture('learning/rank-ladder.json')! as Map<String, dynamic>,
      ),
    );

    test('the ladder arrives in the academy\'s own order, with the learner\'s standing', () {
      expect(ladder.ranks.map((r) => r.order), [1, 2, 3]);
      expect(ladder.ordered.first.title, 'Rank I · Beginner');
      expect(ladder.current!.id, ladder.standing.rankId);
      expect(ladder.current!.title, 'Rank I · Beginner');
    });

    test('each step reads against the standing, lowest to highest', () {
      final steps = rankSteps(ladder);

      expect(steps.map((s) => s.state), [
        RankStepState.current,
        RankStepState.next,
        RankStepState.future,
      ]);
      expect(steps[1].rank.criteria.single.label, 'Courses completed');
      expect(steps[1].rank.criteria.single.needed, 2);
    });

    test('the route publishes no achievement dates and no progress — nothing is invented', () {
      expect(ladder.standing.achieved, isEmpty);
      expect(ladder.standing.progress, isEmpty);

      final steps = rankSteps(ladder);
      expect(steps.every((s) => s.achievedAt == null), isTrue);
      // The next rank's criteria keep the academy's own figures; no progress is guessed for them.
      expect(steps[1].criteria!.single.current, 0);
    });

    test('a standing the app has never heard of falls back to the lowest rank', () {
      final unknown = ladder.copyWith(standing: const RankStanding(rankId: 'nope'));

      expect(unknown.current!.order, 1);
      expect(rankSteps(unknown).first.state, RankStepState.current);
    });

    test('an academy with no ladder has no steps', () {
      expect(rankSteps(const RankLadder()), isEmpty);
      expect(const RankLadder().current, isNull);
    });
  });
}
