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
import 'package:syniastrolms_mobile/features/certificates/certificates.dart';
import 'package:syniastrolms_mobile/features/staff_certificates/staff_certificates.dart';
import 'package:syniastrolms_mobile/features/staff_instructors/staff_instructors.dart';

/// The academy's teaching staff and its credential register against the **real** API on the scratch
/// database (FLUTTER-025). An instructor invited here is left inactive rather than removed: there is
/// no route that deletes one, so the run leaves the academy tidy without pretending otherwise.
const _password = 'syniastrolms123';
const _admin = 'admin@syniastrolms.test';
const _instructor = 'meenakshi@syniastrolms.test';
const _learner = 'ananya@syniastrolms.test';

/// The one invited by this suite. Reused run after run, for the same reason.
const _invitedEmail = 'contract.check@syniastrolms.test';

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

  testWidgets('the directory is the academy\'s own, counted its own way', (tester) async {
    final directory = await StaffInstructorsApi(await signIn(_admin)).directory();

    expect(directory.rows, isNotEmpty);
    expect(
      ['active', 'invited', 'inactive'].fold<int>(0, (n, s) => n + directory.countOf(s)),
      directory.countOf('all'),
    );
    for (final row in directory.rows) {
      expect(row.instructor.status, isNot(InstructorStatus.unknown));
      expect(row.instructor.name, isNotEmpty);
      expect(row.instructor.joinedAt.isUtc, isTrue);
    }
    // Every expertise the filter offers is one an instructor actually has.
    final used = {for (final row in directory.rows) ...row.instructor.expertise};
    expect(directory.expertise.toSet(), used);
  });

  testWidgets('a status narrows the directory, and the counts still describe all of it', (
    tester,
  ) async {
    final api = StaffInstructorsApi(await signIn(_admin));
    final all = await api.directory();

    final active = await api.directory(status: 'active');

    expect(active.rows.every((r) => r.instructor.status == InstructorStatus.active), isTrue);
    expect(active.rows, hasLength(all.countOf('active')));
    expect(
      active.countOf('all'),
      all.countOf('all'),
      reason: 'the counts describe the academy, not the page',
    );
  });

  testWidgets('one instructor carries their courses, reach and the academy comparison', (
    tester,
  ) async {
    final api = StaffInstructorsApi(await signIn(_admin));
    final row = (await api.directory()).rows.firstWhere((r) => r.courses.isNotEmpty);

    final detail = await api.instructor(row.instructor.id);

    expect(detail.instructor.id, row.instructor.id);
    expect(detail.courses, isNotEmpty);
    for (final course in detail.courses) {
      expect(course.role, anyOf('lead', 'co'));
      expect(course.activeLearners, lessThanOrEqualTo(course.enrolled));
    }
    // The comparison is the academy's arithmetic; the app only takes the difference.
    expect(detail.performance.academyRating, greaterThan(0));
    if (detail.performance.rating case final rating?) {
      expect(
        detail.performance.ratingGap,
        closeTo(rating - detail.performance.academyRating, 0.001),
      );
    }
    expect(detail.performance.enrollmentsByMonth, hasLength(8));
    expect(detail.performance.enrollmentsByMonth.last.detail, contains('so far'));
  });

  testWidgets('an instructor is invited, edited whole, and made inactive', (tester) async {
    final api = StaffInstructorsApi(await signIn(_admin));
    final existing = (await api.directory(
      search: 'Contract check',
    )).rows.where((r) => r.instructor.email == _invitedEmail).firstOrNull;

    final id =
        existing?.instructor.id ??
        (await api.create(
          const InstructorForm(
            name: 'Contract check instructor',
            title: 'Fixture Teacher',
            email: _invitedEmail,
            bio: 'Added by the mobile app against the real API.',
            expertise: ['Algebra'],
            city: 'Bengaluru',
            languages: ['English'],
          ),
        )).id;

    // Invited: the academy sent them a link to choose a password, and says so.
    final invited = (await api.instructor(id)).instructor;
    expect(invited.email, _invitedEmail);
    expect(invited.awaitsInvite || invited.status == InstructorStatus.inactive, isTrue);

    // Their invitation can be sent again, and the academy answers with where it went.
    if (invited.awaitsInvite) {
      expect(await api.resendInvite(id), _invitedEmail);
    }

    // A save sends the whole record, and the academy keeps every field.
    final saved = await api.save(
      id,
      InstructorForm.of(
        invited,
      ).copyWith(title: 'Fixture Teacher II', expertise: ['Algebra', 'Geometry'], yearsTeaching: 7),
    );
    expect(saved.title, 'Fixture Teacher II');
    expect(saved.expertise, ['Algebra', 'Geometry']);
    expect(saved.yearsTeaching, 7);
    expect(saved.city, invited.city, reason: 'a field not touched is not cleared');

    // Made inactive, they take no seat on the plan and cannot sign in.
    final inactive = await api.setStatus(id, InstructorStatus.inactive);
    expect(inactive.status, InstructorStatus.inactive);
    await expectLater(
      clientFor(_Token()).post('/auth/login', body: {'email': _invitedEmail, 'password': 'x'}),
      throwsA(isA<ApiException>()),
    );
  });

  testWidgets('the academy refuses an instructor it will not take, field by field', (tester) async {
    final api = StaffInstructorsApi(await signIn(_admin));
    const bad = InstructorForm(
      name: 'No',
      title: 'X',
      email: 'not-an-address',
      bio: 'Too short to publish.',
      status: InstructorStatus.active,
    );

    try {
      await api.create(bad);
      fail('the academy should have refused this instructor');
    } on ApiException catch (e) {
      final failure = e.failure;
      expect(failure, isA<ConflictFailure>());
      final fields = (failure as ConflictFailure).issues.map((i) => i.key).toSet();
      expect(fields, containsAll(['name', 'title', 'email', 'bio', 'expertise', 'languages']));
      // The app's own reading names the same fields, so a button is never offered for it.
      expect(instructorFormProblems(bad).toSet(), fields);
    }
  });

  testWidgets('an e-mail another instructor already uses is refused on that field', (tester) async {
    final api = StaffInstructorsApi(await signIn(_admin));
    final taken = (await api.directory()).rows.first.instructor;

    await expectLater(
      api.create(
        InstructorForm(
          name: 'Contract check duplicate',
          title: 'Fixture Teacher',
          email: taken.email,
          bio: 'A bio long enough for the academy to publish it on a course page for learners.',
          expertise: const ['Algebra'],
          city: 'Bengaluru',
          languages: const ['English'],
        ),
      ),
      throwsA(isA<ApiException>()),
    );
  });

  testWidgets('an instructor may read the directory but never change it', (tester) async {
    final api = StaffInstructorsApi(await signIn(_instructor));

    expect((await api.directory()).rows, isNotEmpty);

    await expectLater(
      api.setStatus((await api.directory()).rows.first.instructor.id, InstructorStatus.inactive),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          anyOf(isA<ForbiddenFailure>(), isA<PermissionFailure>()),
        ),
      ),
    );
  });

  testWidgets('a learner has no instructor directory at all', (tester) async {
    await expectLater(
      StaffInstructorsApi(await signIn(_learner)).directory(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          anyOf(isA<ForbiddenFailure>(), isA<PermissionFailure>()),
        ),
      ),
    );
  });

  testWidgets('the credential register counts every certificate the academy has', (tester) async {
    final register = await StaffCertificatesApi(await signIn(_admin)).register();

    expect(register.rows, isNotEmpty);
    expect(
      ['issued', 'pending', 'revoked'].fold<int>(0, (n, s) => n + register.countOf(s)),
      register.countOf('all'),
    );
    expect(register.countOf('all'), register.total);
    for (final row in register.rows) {
      expect(row.certificate.credentialId, isNotEmpty);
      expect(row.studentName, isNotEmpty);
      expect(row.courseTitle, isNotEmpty);
    }
  });

  testWidgets('a certificate already issued cannot be issued again', (tester) async {
    final api = StaffCertificatesApi(await signIn(_admin));
    final issued = (await api.register()).rows.firstWhere(
      (r) => r.certificate.status == CertificateStatus.issued,
    );

    await expectLater(
      api.issue(issued.certificate.id),
      throwsA(
        isA<ApiException>().having(
          (e) => (e.failure as ConflictFailure).message,
          'the academy\'s words',
          contains('pending'),
        ),
      ),
    );
  });

  testWidgets('a certificate is revoked with its reason, and restored', (tester) async {
    final staff = await signIn(_admin);
    final api = StaffCertificatesApi(staff);
    final register = await api.register();
    // Deliberately **not** the academy's pending certificate. Issuing one is a one-way door — there
    // is no route back to pending — and `public_test` needs the seed's pending credential to stay
    // pending, because a certificate not yet issued must not verify (finding 33). Issuing itself is
    // covered by the controller and widget tests, and by the refusal above.
    final row = register.rows.firstWhere((r) => r.certificate.status == CertificateStatus.issued);
    final id = row.certificate.id;

    const reason = 'Contract check — issued against the wrong course.';
    final revoked = await api.revoke(id, reason: reason);
    try {
      expect(revoked.isRevoked, isTrue);
      expect(revoked.revokedReason, reason);
      expect(revoked.revokedAt, isNotNull);

      // The detail says so too, and still prints from the academy's template.
      final detail = await api.certificate(id);
      expect(detail.certificate.isRevoked, isTrue);
      expect(detail.template, isNotNull);
      expect(detail.verifyUrl, '/verify/${detail.certificate.credentialId}');

      // Public verification still answers — and that is the point of it: anyone checking the
      // credential is told it was withdrawn, rather than finding nothing and wondering.
      final public =
          await clientFor(_Token()).get('/certificates/verify/${detail.certificate.credentialId}')
              as Map<String, dynamic>;
      expect((public['certificate']! as Map)['status'], 'revoked');
      expect((public['certificate']! as Map)['revokedReason'], reason);
    } finally {
      // Put it back exactly as it was found.
      final restored = await api.restore(id);
      expect(restored.status, CertificateStatus.issued);
      expect(restored.revokedReason, isNull);
    }
  });

  testWidgets('a revocation reason the academy will not take is refused', (tester) async {
    final api = StaffCertificatesApi(await signIn(_admin));
    final id = (await api.register()).rows.first.certificate.id;

    // The route answers 400 with no field for this, which is why the app checks the length itself.
    expect(revokeReasonIsEnough('no'), isFalse);
    await expectLater(api.revoke(id, reason: 'no'), throwsA(isA<ApiException>()));
  });

  testWidgets('an instructor may issue a certificate but never revoke one', (tester) async {
    final api = StaffCertificatesApi(await signIn(_instructor));
    final register = await api.register();

    expect(register.rows, isNotEmpty, reason: 'their own courses\' certificates');

    await expectLater(
      api.revoke(register.rows.first.certificate.id, reason: 'Contract check — not theirs to do.'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          anyOf(isA<ForbiddenFailure>(), isA<PermissionFailure>()),
        ),
      ),
    );
  });

  testWidgets('a learner sees their own certificate, and no register', (tester) async {
    final learner = await signIn(_learner);

    // Their own wallet is theirs to read.
    expect((await CertificatesApi(learner).wallet()).issued, isNotEmpty);

    await expectLater(
      StaffCertificatesApi(learner).register(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          anyOf(isA<ForbiddenFailure>(), isA<PermissionFailure>()),
        ),
      ),
    );
  });
}
