import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syniastrolms_mobile/core/auth/session_cleanup.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/errors/result.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/storage/preferences.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/auth/data/auth_repository.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/test_config.dart';

const _learner = UserProfile(
  id: 'u1',
  name: 'Asha Verma',
  email: 'asha@syniastrolms.test',
  role: UserRole.student,
  descriptor: 'Learner',
);

const _other = UserProfile(
  id: 'u2',
  name: 'Ravi Kumar',
  email: 'ravi@syniastrolms.test',
  role: UserRole.student,
  descriptor: 'Learner',
);

const _superAdmin = UserProfile(
  id: 'sa',
  name: 'Platform',
  email: 'ops@syniastrolms.test',
  role: UserRole.superadmin,
  descriptor: 'Super admin',
);

void main() {
  late FakeAuthRepository repository;
  late ProviderContainer container;
  late Preferences preferences;

  Future<ProviderContainer> makeContainer({Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    preferences = Preferences(await SharedPreferences.getInstance());
    return ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(testConfig()),
        preferencesProvider.overrideWithValue(preferences),
        tokenStoreProvider.overrideWithValue(FakeTokenStore()),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

  setUp(() async {
    repository = FakeAuthRepository();
    container = await makeContainer();
    addTearDown(container.dispose);
  });

  SessionController controller() => container.read(sessionControllerProvider.notifier);
  SessionState state() => container.read(sessionControllerProvider);

  group('restore at launch', () {
    test('no token → signed out, and /auth/me is not called', () async {
      await controller().restore();

      expect(state(), isA<SessionSignedOut>());
      expect((state() as SessionSignedOut).reason, SignedOutReason.none);
      expect(repository.calls, ['readToken']);
    });

    test('a valid token → signed in with the profile from the server', () async {
      repository
        ..token = 'stored'
        ..profile = _learner;

      await controller().restore();

      expect(state(), isA<SessionSignedIn>());
      expect(state().user, _learner);
      expect(repository.calls, contains('me'));
    });

    test('a 401 → signed out as expired, token cleared', () async {
      repository
        ..token = 'stale'
        ..meFailure = const UnauthenticatedFailure();

      await controller().restore();

      expect((state() as SessionSignedOut).reason, SignedOutReason.expired);
      expect(repository.token, isNull);
    });

    test('a 403 → signed out with the server\'s own message', () async {
      repository
        ..token = 'stored'
        ..meFailure = const ForbiddenFailure(
          message: 'This account is suspended. Contact your admin to continue.',
        );

      await controller().restore();

      final signedOut = state() as SessionSignedOut;
      expect(signedOut.reason, SignedOutReason.refused);
      expect(signedOut.message, 'This account is suspended. Contact your admin to continue.');
      expect(repository.token, isNull);
    });

    test('offline → unavailable, and the token is kept', () async {
      repository
        ..token = 'stored'
        ..meFailure = const NetworkFailure(NetworkProblem.offline);

      await controller().restore();

      expect(state(), isA<SessionUnavailable>());
      expect(repository.token, 'stored', reason: 'nobody is signed out for being offline');

      // Retry once the server is reachable again.
      repository
        ..meFailure = null
        ..profile = _learner;
      await controller().restore();
      expect(state(), isA<SessionSignedIn>());
    });

    test('a server fault → unavailable, token kept', () async {
      repository
        ..token = 'stored'
        ..meFailure = const ServerFailure(status: 503);

      await controller().restore();

      expect(state(), isA<SessionUnavailable>());
      expect(repository.token, 'stored');
    });

    test('a 404 (account gone) → signed out', () async {
      repository
        ..token = 'stored'
        ..meFailure = const NotFoundFailure(message: 'Account not found.');

      await controller().restore();

      expect((state() as SessionSignedOut).reason, SignedOutReason.refused);
      expect(repository.token, isNull);
    });
  });

  group('sign in', () {
    test('signs in and returns the profile', () async {
      repository.profile = _learner;

      final result = await controller().signIn(email: 'asha@b.test', password: 'x');

      expect(result, isA<Ok<UserProfile, AppFailure>>());
      expect(state(), isA<SessionSignedIn>());
    });

    test('a refusal leaves the session signed out and hands the failure back', () async {
      repository.failure = const UnauthenticatedFailure(message: 'Incorrect email or password.');

      final result = await controller().signIn(email: 'asha@b.test', password: 'x');

      expect(result.failureOrNull, isA<UnauthenticatedFailure>());
      expect(state(), isA<SessionUnknown>(), reason: 'the session itself did not change');
    });

    test('a super admin gets no session and no token', () async {
      repository.profile = _superAdmin;

      await controller().signIn(email: 'ops@b.test', password: 'x');

      expect(state(), isA<SessionUnsupportedRole>());
      expect(repository.token, isNull);
      expect(repository.calls, contains('clearToken'));
    });
  });

  test('register signs the new learner in', () async {
    repository.profile = _learner;

    await controller().register(
      name: 'Asha',
      email: 'asha@b.test',
      password: 'password1',
      workspace: 'jyotish-vidya',
    );

    expect(state(), isA<SessionSignedIn>());
    expect(repository.calls, contains('register:asha@b.test@jyotish-vidya'));
  });

  group('joining from a link', () {
    const token = '3f9a1c7e20b84d65af0e2d19c8b73540e6a92f14bc385d70a1fe6b29d4c80713';

    test('an invitation starts the session exactly as registering does', () async {
      repository.profile = _learner;

      await controller().registerWithInvitation(
        token: token,
        name: 'Asha',
        email: 'asha@b.test',
        password: 'password1',
      );

      expect(state(), isA<SessionSignedIn>());
      expect(state().user?.id, _learner.id);
      expect(repository.token, isNotNull);
    });

    test('a refused invitation sign-in leaves the device signed out, holding nothing', () async {
      repository.failure = const ConflictFailure(message: 'This account belongs to another LMS.');
      await controller().restore();

      final result = await controller().signInWithInvitation(
        token: token,
        email: 'asha@b.test',
        password: 'x',
      );

      expect(result, isA<Err<UserProfile, AppFailure>>());
      expect(state(), isA<SessionSignedOut>());
      expect(repository.token, isNull);
    });

    test('a course link\'s account replaces whoever was here, and their data with them', () async {
      repository
        ..token = 'stored'
        ..profile = _other;
      await controller().restore();
      await preferences.setLastTab('review', 'overdue');
      var cleaned = 0;
      container.read(sessionCleanupProvider).register(() async => cleaned++);

      repository
        ..profile = _learner
        ..courseJoinEnrolled = false
        ..courseJoinEnrolment = 'Needs approval.';
      final result = await controller().joinFromCourseLink(
        courseId: 'cmudqd8g30035mmgzwtgr0mcl',
        name: 'Asha',
        email: 'asha@b.test',
        password: 'password1',
      );

      expect(state().user?.id, _learner.id);
      expect(preferences.lastTab('review'), isNull, reason: 'nothing of the last person remains');
      expect(cleaned, 1);
      expect(switch (result) {
        Ok(value: RegistrationSignedIn(:final enrolment)) => enrolment,
        _ => 'refused',
      }, 'Needs approval.');
    });
  });

  group('sign out', () {
    test('clears the token, the user-scoped preferences and the registered cleanups', () async {
      repository
        ..token = 'stored'
        ..profile = _learner;
      await controller().restore();
      await preferences.setLastTab('review', 'overdue');
      var cleaned = 0;
      container.read(sessionCleanupProvider).register(() async => cleaned++);

      await controller().signOut();

      expect(state(), isA<SessionSignedOut>());
      expect((state() as SessionSignedOut).reason, SignedOutReason.signedOut);
      expect(repository.token, isNull);
      expect(preferences.lastTab('review'), isNull);
      expect(cleaned, 1);
    });

    test('ends the server session before the token is forgotten', () async {
      repository.profile = _learner;
      await controller().signIn(email: 'a@b.test', password: 'x');
      repository.calls.clear();

      await controller().signOut();

      expect(repository.calls, ['logout', 'clearToken']);
      expect((state() as SessionSignedOut).reason, SignedOutReason.signedOut);
    });

    test('a server that cannot be reached still leaves the device signed out', () async {
      repository
        ..profile = _learner
        ..logoutFailure = const NetworkFailure(NetworkProblem.offline);
      await controller().signIn(email: 'a@b.test', password: 'x');

      await controller().signOut();

      expect(state(), isA<SessionSignedOut>());
      expect((state() as SessionSignedOut).reason, SignedOutReason.signedOut);
      expect(repository.token, isNull);
    });

    test('a 401 from the logout call itself is not reported as an expired session', () async {
      repository
        ..profile = _learner
        ..logoutFailure = const UnauthenticatedFailure();
      await controller().signIn(email: 'a@b.test', password: 'x');
      // What the API client does on that 401, while the sign-out is still running.
      repository.onLogout = () => controller().handleSessionExpired();

      await controller().signOut();

      expect((state() as SessionSignedOut).reason, SignedOutReason.signedOut);
    });

    test('a failing cleanup does not stop the sign-out', () async {
      repository.profile = _learner;
      await controller().signIn(email: 'a@b.test', password: 'x');
      container.read(sessionCleanupProvider).register(() async => throw StateError('cache'));

      await controller().signOut();

      expect(state(), isA<SessionSignedOut>());
    });

    test('an expired session signs out with the expired reason', () async {
      repository.profile = _learner;
      await controller().signIn(email: 'a@b.test', password: 'x');

      await controller().handleSessionExpired();

      expect((state() as SessionSignedOut).reason, SignedOutReason.expired);
      expect(repository.token, isNull);
      // The token is already refused; there is no server session left to end.
      expect(repository.calls, isNot(contains('logout')));
    });
  });

  group('delete account', () {
    test('clears the device at once — the server has already ended every session', () async {
      repository.profile = _learner;
      await controller().signIn(email: 'a@b.test', password: 'x');
      repository.calls.clear();

      final result = await controller().deleteAccount('x');

      expect(result, isA<Ok<void, AppFailure>>());
      expect(repository.calls, ['deleteAccount', 'clearToken']);
      expect((state() as SessionSignedOut).reason, SignedOutReason.deleted);
      expect(repository.token, isNull);
    });

    test('a refusal (a wrong password) leaves the session as it was', () async {
      repository.profile = _learner;
      await controller().signIn(email: 'a@b.test', password: 'x');
      repository.failure = const ForbiddenFailure(message: 'Your password is not correct.');

      final result = await controller().deleteAccount('wrong');

      expect(result, isA<Err<void, AppFailure>>());
      expect(state().user, _learner);
      expect(repository.token, isNotNull);
    });
  });

  group('refreshProfile', () {
    test('picks up changed permissions', () async {
      repository.profile = _learner;
      await controller().signIn(email: 'a@b.test', password: 'x');

      repository.profile = _learner.copyWith(descriptor: 'Beginner · Ardra');
      await controller().refreshProfile();

      expect(state().user?.descriptor, 'Beginner · Ardra');
    });

    test('a transient failure leaves the session alone', () async {
      repository.profile = _learner;
      await controller().signIn(email: 'a@b.test', password: 'x');

      repository.meFailure = const NetworkFailure(NetworkProblem.timeout);
      await controller().refreshProfile();

      expect(state(), isA<SessionSignedIn>());
    });

    test('a refusal ends the session with the server message', () async {
      repository.profile = _learner;
      await controller().signIn(email: 'a@b.test', password: 'x');

      repository.meFailure = const ForbiddenFailure(message: 'This account has been deactivated.');
      await controller().refreshProfile();

      expect((state() as SessionSignedOut).message, 'This account has been deactivated.');
    });

    test('does nothing when signed out', () async {
      await controller().refreshProfile();
      expect(repository.calls, isEmpty);
    });
  });

  test('a different person on the same device purges what the last one left', () async {
    repository.profile = _learner;
    await controller().signIn(email: 'asha@b.test', password: 'x');
    await preferences.setLastTab('students', 'at-risk');

    repository.profile = _other;
    await controller().signIn(email: 'ravi@b.test', password: 'x');

    expect(state().user, _other);
    expect(preferences.lastTab('students'), isNull);
  });

  group('an LMS the platform suspended or closed', () {
    test('ends the session with the server’s words, and forgets the token', () async {
      repository
        ..token = 'stored'
        ..profile = _learner;
      await controller().restore();
      expect(state(), isA<SessionSignedIn>());

      await controller().handleAccountClosed(
        const AccountClosedFailure(
          archived: false,
          message: 'This account is suspended. Contact ZuviloAI support to restore access.',
        ),
      );

      final signedOut = state() as SessionSignedOut;
      expect(signedOut.reason, SignedOutReason.refused);
      expect(signedOut.message, contains('suspended'));
      expect(repository.token, isNull);
    });

    test('changes nothing when nobody is signed in', () async {
      await controller().restore();
      await controller().handleAccountClosed(const AccountClosedFailure(archived: true));
      expect((state() as SessionSignedOut).reason, SignedOutReason.none);
    });
  });

  test('a late 401 after signing out does not turn the sign-out into an expired session', () async {
    repository
      ..token = 'stored'
      ..profile = _learner;
    await controller().restore();
    await controller().signOut();
    expect((state() as SessionSignedOut).reason, SignedOutReason.signedOut);

    await controller().handleSessionExpired();

    expect((state() as SessionSignedOut).reason, SignedOutReason.signedOut);
  });
}
