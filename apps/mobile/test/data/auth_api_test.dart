import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/auth/data/auth_api.dart';
import 'package:syniastrolms_mobile/features/auth/data/dto/account_verification.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/test_config.dart';

void main() {
  late FakeAdapter adapter;
  late AuthApi api;

  setUp(() {
    adapter = FakeAdapter();
    api = AuthApi(
      ApiClient(
        config: testConfig(),
        tokenStore: FakeTokenStore(),
        logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
        adapter: adapter,
        logRequests: false,
      ),
    );
  });

  Map<String, dynamic> bodyOf() => adapter.lastRequest.data! as Map<String, dynamic>;

  const profileJson = {
    'id': 'u1',
    'name': 'Asha Verma',
    'email': 'asha@syniastrolms.test',
    'role': 'student',
    'descriptor': 'Learner',
    'permissions': <String>[],
  };

  group('login', () {
    test('posts only the e-mail and password, trimmed and lower-cased', () async {
      adapter.enqueueJson({'token': 'jwt', 'user': profileJson});

      final response = await api.login(email: '  Asha@Syniastrolms.TEST ', password: ' secret ');

      expect(adapter.lastRequest.path, '/auth/login');
      expect(adapter.lastRequest.method, 'POST');
      expect(bodyOf(), {'email': 'asha@syniastrolms.test', 'password': ' secret '});
      expect(bodyOf().keys, isNot(contains('role')));
      expect(bodyOf().keys, isNot(contains('tenantId')));
      expect(response.token, 'jwt');
      expect(response.user.role, UserRole.student);
    });

    test('a refusal surfaces as a typed failure', () async {
      adapter.enqueueStatus(401, body: {'message': 'Incorrect email or password.'});

      await expectLater(
        api.login(email: 'a@b.test', password: 'x'),
        throwsA(
          isA<ApiException>().having((e) => e.failure, 'failure', isA<UnauthenticatedFailure>()),
        ),
      );
    });
  });

  test(
    'register posts name, e-mail, password and the LMS address only — never a role or tenant id',
    () async {
      adapter.enqueueJson({'token': 'jwt', 'user': profileJson}, status: 201);

      await api.register(
        name: '  Asha Verma ',
        email: 'ASHA@b.test',
        password: 'password1',
        workspace: 'jyotish-vidya',
      );

      expect(adapter.lastRequest.path, '/auth/register');
      expect(bodyOf(), {
        'name': 'Asha Verma',
        'email': 'asha@b.test',
        'password': 'password1',
        'workspace': 'jyotish-vidya',
      });
      expect(bodyOf(), isNot(contains('tenantId')));
      expect(bodyOf(), isNot(contains('role')));
    },
  );

  test('register leaves out an empty LMS address', () async {
    adapter.enqueueJson({'token': 'jwt', 'user': profileJson}, status: 201);

    await api.register(
      name: 'Asha Verma',
      email: 'asha@b.test',
      password: 'password1',
      workspace: '',
    );

    expect(adapter.lastRequest.path, '/auth/register');
    expect(bodyOf(), isNot(contains('workspace')));
  });

  test('logout posts to /auth/logout with no body', () async {
    adapter.enqueueJson({'revoked': 1});

    await api.logout();

    expect(adapter.lastRequest.path, '/auth/logout');
    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.data, isNull);
  });

  test('me reads the profile out of {user}', () async {
    adapter.enqueueJson({'user': profileJson});

    final profile = await api.me();

    expect(adapter.lastRequest.path, '/auth/me');
    expect(adapter.lastRequest.method, 'GET');
    expect(profile.name, 'Asha Verma');
  });

  test('forgot-password lower-cases the address', () async {
    adapter.enqueueJson({'ok': true});

    await api.forgotPassword(' Asha@B.test ');

    expect(adapter.lastRequest.path, '/auth/forgot-password');
    expect(bodyOf(), {'email': 'asha@b.test'});
  });

  group('reset password', () {
    test('checks a token as a path segment, encoded', () async {
      adapter.enqueueJson({'valid': true});

      expect(await api.isResetTokenValid('abc/../def'), isTrue);
      expect(adapter.lastRequest.path, '/auth/reset-password/abc%2F..%2Fdef');
    });

    test('posts the token and the new password', () async {
      adapter.enqueueJson({'ok': true});

      await api.resetPassword(token: 'tok', password: 'password1');

      expect(adapter.lastRequest.path, '/auth/reset-password');
      expect(bodyOf(), {'token': 'tok', 'password': 'password1'});
    });

    test('an expired link is a conflict', () async {
      adapter.enqueueStatus(409, body: {'message': 'This reset link is invalid or has expired.'});

      await expectLater(
        api.resetPassword(token: 'tok', password: 'password1'),
        throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<ConflictFailure>())),
      );
    });
  });

  /// The ways into an Admin's LMS (`routes/publicSite.ts`). The responses below are the route's own
  /// shapes, as `describeInvitation` / `describeCourseLink` and the `/academies/:slug` handler build
  /// them; each request carries only the person's own details — never a role or a tenant.
  group('links into an LMS', () {
    const token = '3f9a1c7e20b84d65af0e2d19c8b73540e6a92f14bc385d70a1fe6b29d4c80713';
    const courseId = 'cmudqd8g30035mmgzwtgr0mcl';

    void expectNoTenantOrRole() {
      expect(bodyOf().keys, isNot(contains('role')));
      expect(bodyOf().keys, isNot(contains('tenantId')));
      expect(bodyOf().keys, isNot(contains('workspace')));
    }

    test('a join link\'s LMS is read by its address', () async {
      adapter.enqueueJson({'name': 'Jyotish Vidya', 'slug': 'jyotish-vidya', 'open': true});

      final page = await api.lmsJoinPage('jyotish-vidya');

      expect(adapter.lastRequest.path, '/public/academies/jyotish-vidya');
      expect(adapter.lastRequest.method, 'GET');
      expect(page, const LmsJoinPage(name: 'Jyotish Vidya', slug: 'jyotish-vidya', open: true));
    });

    test('an invitation reads its LMS, role, bound address and expiry', () async {
      adapter.enqueueJson({
        'lms': {'name': 'Jyotish Vidya', 'slug': 'jyotish-vidya'},
        'role': 'student',
        'email': 'invited@b.test',
        'expiresAt': '2026-10-12T09:30:00.000Z',
        'open': true,
      });

      final invitation = await api.invitation(token);

      expect(adapter.lastRequest.path, '/public/invitations/$token');
      expect(invitation.lms.name, 'Jyotish Vidya');
      expect(invitation.role, 'student');
      expect(invitation.email, 'invited@b.test');
      expect(invitation.expiresAt, DateTime.utc(2026, 10, 12, 9, 30));
      expect(invitation.open, isTrue);
    });

    test('an open invitation carries no address', () async {
      adapter.enqueueJson({
        'lms': {'name': 'Jyotish Vidya', 'slug': 'jyotish-vidya'},
        'role': 'student',
        'email': null,
        'expiresAt': '2026-10-12T09:30:00.000Z',
        'open': false,
      });

      final invitation = await api.invitation(token);

      expect(invitation.email, isNull);
      expect(invitation.open, isFalse);
    });

    test('an invalid invitation is a typed 404', () async {
      adapter.enqueueStatus(
        404,
        body: {'message': 'This invitation link isn’t valid.', 'code': 'INVITE_INVALID'},
      );

      await expectLater(
        api.invitation(token),
        throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
      );
    });

    test('a response missing the LMS is a contract failure, not a crash', () async {
      adapter.enqueueJson({'role': 'student', 'expiresAt': '2026-10-12T09:30:00.000Z'});

      await expectLater(
        api.invitation(token),
        throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<ContractFailure>())),
      );
    });

    test('accepting with a new account posts name, e-mail and password only', () async {
      adapter.enqueueJson({'token': 'jwt', 'user': profileJson}, status: 201);

      final response = await api.registerWithInvitation(
        token: token,
        name: ' Asha Verma ',
        email: ' Asha@B.test',
        password: 'password1',
      );

      expect(adapter.lastRequest.path, '/public/invitations/$token/register');
      expect(adapter.lastRequest.method, 'POST');
      expect(bodyOf(), {'name': 'Asha Verma', 'email': 'asha@b.test', 'password': 'password1'});
      expectNoTenantOrRole();
      expect((response as AccountCreated).auth.token, 'jwt');
    });

    test('accepting by signing in posts the e-mail and password only', () async {
      adapter.enqueueJson({'token': 'jwt', 'user': profileJson});

      await api.signInWithInvitation(token: token, email: 'ASHA@b.test', password: 'secret');

      expect(adapter.lastRequest.path, '/public/invitations/$token/sign-in');
      expect(bodyOf(), {'email': 'asha@b.test', 'password': 'secret'});
      expectNoTenantOrRole();
    });

    test('an account of another LMS is a conflict on sign-in', () async {
      adapter.enqueueStatus(
        409,
        body: {'message': 'This account belongs to another LMS, so this invitation can’t be used.'},
      );

      await expectLater(
        api.signInWithInvitation(token: token, email: 'a@b.test', password: 'secret'),
        throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<ConflictFailure>())),
      );
    });

    test('a course link reads the course and its LMS', () async {
      adapter.enqueueJson({
        'lms': {'name': 'Jyotish Vidya', 'slug': 'jyotish-vidya'},
        'course': {'id': courseId, 'title': 'Foundations', 'slug': 'foundations'},
        'open': true,
      });

      final link = await api.courseLink(courseId);

      expect(adapter.lastRequest.path, '/public/courses/$courseId/enroll');
      expect(adapter.lastRequest.method, 'GET');
      expect(link.course.title, 'Foundations');
      expect(link.lms.slug, 'jyotish-vidya');
    });

    test(
      'joining from a course link says whether the LMS enrolled the account, and why not',
      () async {
        adapter
          ..enqueueJson({'token': 'jwt', 'user': profileJson, 'enrolled': true}, status: 201)
          ..enqueueJson({
            'token': 'jwt',
            'user': profileJson,
            'enrolled': false,
            'enrolment': 'Enrolment in this LMS needs approval.',
          }, status: 201);

        final enrolled = await api.joinFromCourseLink(
          courseId: courseId,
          name: 'Asha Verma',
          email: 'asha@b.test',
          password: 'password1',
        );
        expect(adapter.lastRequest.path, '/public/courses/$courseId/enroll');
        expect(bodyOf(), {'name': 'Asha Verma', 'email': 'asha@b.test', 'password': 'password1'});
        expectNoTenantOrRole();
        expect((enrolled as AccountCreated).enrolled, isTrue);
        expect(enrolled.enrolment, isNull);

        final waiting = await api.joinFromCourseLink(
          courseId: courseId,
          name: 'Asha Verma',
          email: 'asha@b.test',
          password: 'password1',
        );
        expect((waiting as AccountCreated).enrolled, isFalse);
        expect(waiting.enrolment, 'Enrolment in this LMS needs approval.');
      },
    );
  });

  test('health reports reachability', () async {
    adapter
      ..enqueueJson({'ok': true})
      ..enqueueJson({'ok': false});

    expect(await api.health(), isTrue);
    expect(await api.health(), isFalse);
  });
}
