import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/core/network/token_store.dart';
import 'package:syniastrolms_mobile/features/certificates/data/certificates_api.dart';
import 'package:syniastrolms_mobile/features/course_learning/data/course_learning_api.dart';
import 'package:syniastrolms_mobile/features/verify/data/verify_api.dart';
import 'package:syniastrolms_mobile/shared/domain/certificate.dart';

/// Certificates and ranks against the **real** API on the scratch database
/// (`tool/contract_server.sh start`). The academy issues; the app only asks.
const _password = 'syniastrolms123';

/// The seeded learners, and the short courses that award a certificate without a quiz to pass.
/// A certificate is created once per learner and course and can never go back to pending, so each
/// run of the claim test takes the next pair that has none yet.
/// `priya`, `sneha` and `ananya` are left out: `enrollment_test.dart` needs a course they have
/// **not** joined, and this test enrols whoever it picks.
const _learners = [
  'meera@syniastrolms.test',
  'rohit@syniastrolms.test',
  'vikram@syniastrolms.test',
  'karan@syniastrolms.test',
  'arjun@syniastrolms.test',
];
const _shortCourses = ['reet-maths-pedagogy', 'rajasthan-economy', 'rpsc-answer-writing'];

class _Token implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppConfig config;
  final clients = <String, ApiClient>{};

  ApiClient clientFor(TokenStore store) => ApiClient(
    config: config,
    tokenStore: store,
    logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
    logRequests: false,
  );

  Future<ApiClient> signIn(String email) async {
    final cached = clients[email];
    if (cached != null) return cached;
    final store = _Token();
    final body = await clientFor(
      _Token(),
    ).post('/auth/login', body: {'email': email, 'password': _password});
    store.token = (body! as Map)['token'] as String;
    return clients[email] = clientFor(store);
  }

  setUpAll(() => config = AppConfig.fromEnvironment(Flavor.dev));

  Future<String> courseIdOf(String slug) async {
    final course =
        (await clientFor(_Token()).get('/catalog/courses/$slug'))! as Map<String, dynamic>;
    return course['id']! as String;
  }

  testWidgets('the wallet is this learner\'s own, with the template each is printed from', (
    tester,
  ) async {
    final client = await signIn('ananya@syniastrolms.test');

    final wallet = await CertificatesApi(client).wallet();

    expect(wallet.issued, isNotEmpty, reason: 'the seed issues this learner one certificate');
    final detail = wallet.issued.first;
    expect(detail.certificate.status, CertificateStatus.issued);
    expect(detail.certificate.credentialId, startsWith('SA-'));
    expect(detail.verifyUrl, '/verify/${detail.certificate.credentialId}');
    expect(detail.template, isNotNull);
    expect(detail.template!.heading, isNotEmpty);
    expect(detail.template!.signatories, isNotEmpty);
    expect(detail.student.name, isNotEmpty);

    // Read on its own, it is the same certificate.
    final alone = await CertificatesApi(client).certificate(detail.certificate.id);
    expect(alone.certificate.credentialId, detail.certificate.credentialId);

    // Every course still being worked through carries the academy's own criteria.
    for (final record in wallet.working) {
      expect(record.criteria, isNotEmpty);
      expect(record.criteria.every((c) => c.needed > 0), isTrue);
      expect(record.issued, isFalse);
    }
  });

  testWidgets('a course completed while the academy auto-issues nothing waits to be claimed', (
    tester,
  ) async {
    // The academy's own setting decides this; the test reads it rather than setting it.
    final admin = await signIn('admin@syniastrolms.test');
    final settings =
        ((await admin.get('/settings'))! as Map<String, dynamic>)['settings']!
            as Map<String, dynamic>;
    final certificates = settings['certificates']! as Map<String, dynamic>;
    expect(certificates['enabled'], isTrue);
    expect(
      certificates['autoIssue'],
      isFalse,
      reason: 'this academy hands certificates over to be claimed',
    );

    // Find a learner and a course with no certificate yet: one can never be made pending again.
    String? email;
    String? slug;
    String? courseId;
    for (final candidate in _learners) {
      final client = await signIn(candidate);
      final wallet = await CertificatesApi(client).wallet();
      final held = {
        for (final d in [...wallet.issued, ...wallet.pending]) d.certificate.courseId,
      };
      for (final course in _shortCourses) {
        final id = await courseIdOf(course);
        if (!held.contains(id)) {
          email = candidate;
          slug = course;
          courseId = id;
          break;
        }
      }
      if (email != null) break;
    }
    if (email == null) {
      markTestSkipped(
        'Every seeded learner already holds a certificate for every short course on this scratch '
        'database, and a certificate cannot be made pending again. Re-seed with '
        '`tool/contract_server.sh seed` to run this again.',
      );
      return;
    }

    final client = await signIn(email);
    final id = courseId!;
    final courses = CourseLearningApi(client);
    try {
      final enrolled = await courses.enroll(id);
      // Given back through the academy's own route, so a run leaves the scratch database's
      // enrolments as it found them. The certificate itself stays, as the academy's record.
      addTearDown(() async => admin.delete('/students/enrollments/${enrolled.enrollment.id}'));
    } on ApiException catch (e) {
      if (e.failure is! ConflictFailure) rethrow;
    }

    // Complete the course the way a learner does: lesson by lesson, in the academy's own order.
    final course = await courses.course(id);
    for (final chapter in course.learner.course.chapters) {
      for (final lesson in chapter.lessons) {
        if (lesson.type == 'video') {
          await courses.reportPosition(
            courseId: id,
            lessonId: lesson.id,
            positionSec: lesson.durationMin * 60,
            fraction: 1,
          );
        } else {
          await courses.complete(courseId: id, lessonId: lesson.id);
        }
      }
    }

    // The academy created it, as pending — the app asked for nothing of the sort.
    final wallet = await CertificatesApi(client).wallet();
    final pending = wallet.pending.firstWhere(
      (d) => d.certificate.courseId == id,
      orElse: () => throw StateError('no pending certificate for $slug'),
    );
    expect(pending.certificate.isPending, isTrue);
    expect(pending.certificate.issuedAt, isNull);
    expect(pending.certificate.completedAt, isNotNull);

    // Claiming it: the academy issues it, and answers with the issued certificate.
    final issued = await CertificatesApi(client).claim(pending.certificate.id);

    expect(issued.certificate.status, CertificateStatus.issued);
    expect(issued.certificate.issuedAt, isNotNull);
    expect(issued.certificate.credentialId, startsWith('SA-'));
    expect(issued.verifyUrl, '/verify/${issued.certificate.credentialId}');
    expect(issued.template, isNotNull);

    // And the wallet has moved it across.
    final after = await CertificatesApi(client).wallet();
    expect(after.pending.map((d) => d.certificate.id), isNot(contains(pending.certificate.id)));
    expect(after.issued.map((d) => d.certificate.id), contains(pending.certificate.id));

    // The link that would be shared resolves publicly, with no one signed in.
    final verified = await VerifyApi(clientFor(_Token())).verify(issued.certificate.credentialId);
    expect(verified.isValid, isTrue);
    expect(verified.certificate.credentialId, issued.certificate.credentialId);
    expect(
      verificationLinkFor(config, issued.certificate.credentialId),
      '${config.webBaseUrl}/verify/${issued.certificate.credentialId}',
    );

    // Claiming it again is refused: it is not pending any more.
    await expectLater(
      CertificatesApi(client).claim(pending.certificate.id),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
    );
  });

  testWidgets('a certificate that is not the learner\'s own is not found', (tester) async {
    final owner = await signIn('ananya@syniastrolms.test');
    final other = await signIn('rohit@syniastrolms.test');
    final theirs = (await CertificatesApi(owner).wallet()).issued.first;

    await expectLater(
      CertificatesApi(other).certificate(theirs.certificate.id),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
    );
  });

  testWidgets('the rank ladder and the standing on it are the academy\'s', (tester) async {
    final client = await signIn('ananya@syniastrolms.test');

    final ladder = await CertificatesApi(client).rankLadder();

    expect(ladder.ranks, isNotEmpty);
    expect(ladder.ordered.map((r) => r.order), [for (var i = 1; i <= ladder.ranks.length; i++) i]);
    expect(ladder.standing.rankId, isNotEmpty);
    expect(ladder.current, isNotNull);
    expect(
      ladder.ranks.map((r) => r.id),
      contains(ladder.standing.rankId),
      reason: 'the standing names a rank on the ladder',
    );
  });
}

/// The link the share sheet is handed, as a string.
String verificationLinkFor(AppConfig config, String credentialId) =>
    config.webBaseUrl.replace(path: '/verify/$credentialId').toString();
