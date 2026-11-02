import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/links/deep_link.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/auth/data/auth_api.dart';
import 'package:syniastrolms_mobile/features/auth/data/dto/account_verification.dart';
import 'package:syniastrolms_mobile/features/auth/presentation/auth_messages.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/test_config.dart';

/// Learners and instructors who register themselves verify their email before any account exists:
/// every door answers `202 {status: 'verify', …}`, and `POST /public/verifications/verify` makes the
/// account. A deployment with verification off still answers the old shapes, so both are read.
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
    'email': 'asha@b.test',
    'role': 'student',
    'descriptor': 'Learner',
    'permissions': <String>[],
  };

  Map<String, Object> pendingJson({String role = 'student'}) => {
    'status': 'verify',
    'verificationId': 'ckverification1',
    'email': 'asha@b.test',
    'role': role,
    'lms': 'Saraswati Coaching',
    'expiresAt': '2026-10-23T10:15:00.000Z',
    'resendAvailableAt': '2026-10-23T10:01:00.000Z',
  };

  group('a door answers', () {
    test('the code it now waits for: a pending body, not a token', () async {
      adapter.enqueueJson(pendingJson(), status: 202);

      final reply = await api.register(
        name: 'Asha Verma',
        email: 'asha@b.test',
        password: 'password1',
        workspace: 'saraswati-coaching',
      );

      expect(reply, isA<AccountNeedsCode>());
      final pending = (reply as AccountNeedsCode).pending;
      expect(pending.verificationId, 'ckverification1');
      expect(pending.email, 'asha@b.test');
      expect(pending.role, 'student');
      expect(pending.lms, 'Saraswati Coaching');
      expect(pending.expiresAt, DateTime.utc(2026, 10, 23, 10, 15));
      expect(pending.resendAvailableAt, DateTime.utc(2026, 10, 23, 10, 1));
    });

    test('the account at once where verification is off: the old token body', () async {
      adapter.enqueueJson({'token': 'jwt', 'user': profileJson}, status: 201);

      final reply = await api.registerWithInvitation(
        token: 'a' * 64,
        name: 'Asha Verma',
        email: 'asha@b.test',
        password: 'password1',
      );

      expect(reply, isA<AccountCreated>());
      expect((reply as AccountCreated).auth.token, 'jwt');
      expect(reply.enrolled, isNull, reason: 'only a course link says whether it enrolled');
    });

    test('a course link waits for the code too', () async {
      adapter.enqueueJson(pendingJson(), status: 202);

      final reply = await api.joinFromCourseLink(
        courseId: 'cmudqd8g30035mmgzwtgr0mcl',
        name: 'Asha Verma',
        email: 'asha@b.test',
        password: 'password1',
      );

      expect(reply, isA<AccountNeedsCode>());
    });

    test(
      'a request to teach sends the title, and reads both the code and the old answer',
      () async {
        adapter
          ..enqueueJson(pendingJson(role: 'instructor'), status: 202)
          ..enqueueJson({
            'status': 'pending',
            'message': 'Your instructor account is pending Admin approval.',
          }, status: 202);

        final waiting = await api.requestInstructorAccess(
          workspace: 'saraswati-coaching',
          name: 'Ravi Shastri',
          email: 'Ravi@B.test',
          password: 'password1',
          title: ' Physics lecturer ',
        );
        expect(
          adapter.lastRequest.path,
          '/public/academies/saraswati-coaching/instructor-requests',
        );
        expect(bodyOf(), {
          'name': 'Ravi Shastri',
          'email': 'ravi@b.test',
          'password': 'password1',
          'title': 'Physics lecturer',
        });
        expect((waiting as AccountNeedsCode).pending.role, 'instructor');

        final old = await api.requestInstructorAccess(
          workspace: 'saraswati-coaching',
          name: 'Ravi Shastri',
          email: 'ravi@b.test',
          password: 'password1',
        );
        expect(old, isA<AccountAwaitingApproval>());
        expect(
          (old as AccountAwaitingApproval).message,
          'Your instructor account is pending Admin approval.',
        );
      },
    );

    test('anything else is a contract failure, not a crash', () async {
      adapter.enqueueJson({'status': 'verify', 'email': 'asha@b.test'}, status: 202);

      await expectLater(
        api.register(name: 'A', email: 'a@b.test', password: 'password1', workspace: 'abc'),
        throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<ContractFailure>())),
      );
    });

    test('an invitation-only LMS refuses with its own failure', () async {
      adapter.enqueueStatus(
        403,
        body: {
          'message':
              'This LMS adds learners by invitation only. Ask your teacher or school for an '
              'invitation link.',
          'code': 'INVITATION_REQUIRED',
        },
      );

      await expectLater(
        api.register(name: 'A', email: 'a@b.test', password: 'password1', workspace: 'abc'),
        throwsA(
          isA<ApiException>().having((e) => e.failure, 'failure', isA<InvitationRequiredFailure>()),
        ),
      );
    });
  });

  group('the code', () {
    test('verify posts only the registration and the code', () async {
      adapter.enqueueJson({
        'status': 'created',
        'token': 'jwt',
        'user': profileJson,
        'enrolled': false,
        'enrolment': 'Enrolment in this LMS needs approval.',
      }, status: 201);

      final reply = await api.verifyAccount(verificationId: 'ckverification1', code: ' 123456 ');

      expect(adapter.lastRequest.path, '/public/verifications/verify');
      expect(adapter.lastRequest.method, 'POST');
      expect(bodyOf(), {'verificationId': 'ckverification1', 'code': '123456'});
      final created = reply as AccountCreated;
      expect(created.auth.token, 'jwt');
      expect(created.enrolled, isFalse);
      expect(created.enrolment, 'Enrolment in this LMS needs approval.');
    });

    test(
      'a paid course\'s link makes the account and says the course is bought, not joined',
      () async {
        adapter.enqueueJson({
          'status': 'created',
          'token': 'jwt',
          'user': profileJson,
          'enrolled': false,
          'enrolment': 'This is a paid course. Buy it to start learning.',
          'enrolmentCode': 'COURSE_PURCHASE_REQUIRED',
        }, status: 201);

        final reply = await api.verifyAccount(verificationId: 'ckverification1', code: '123456');

        final created = reply as AccountCreated;
        expect(created.enrolled, isFalse);
        expect(created.enrolmentCode, 'COURSE_PURCHASE_REQUIRED');
        expect(
          RegistrationSignedIn(
            const UserProfile(
              id: 'u1',
              name: 'A',
              email: 'a@b.test',
              role: UserRole.student,
              descriptor: '',
            ),
            enrolled: created.enrolled,
            enrolmentCode: created.enrolmentCode,
          ).purchaseRequired,
          isTrue,
        );
      },
    );

    test('an instructor\'s code signs nobody in', () async {
      adapter.enqueueJson({
        'status': 'pending',
        'message': 'Your instructor account is pending Admin approval.',
      }, status: 202);

      final reply = await api.verifyAccount(verificationId: 'ckverification1', code: '123456');

      expect(reply, isA<AccountAwaitingApproval>());
    });

    test('resend posts the registration and reads its new timings', () async {
      adapter.enqueueJson(pendingJson());

      final pending = await api.resendVerification('ckverification1');

      expect(adapter.lastRequest.path, '/public/verifications/resend');
      expect(bodyOf(), {'verificationId': 'ckverification1'});
      expect(pending.resendAvailableAt, DateTime.utc(2026, 10, 23, 10, 1));
    });

    test('a wrong code is a field issue on `code`; a closed registration is not found', () async {
      adapter
        ..enqueueStatus(
          400,
          body: {
            'message': 'That code is not right. 4 tries left.',
            'code': 'VERIFICATION_FAILED',
            'issues': [
              {'field': 'code', 'message': 'That code is not right. 4 tries left.'},
            ],
          },
        )
        ..enqueueStatus(
          404,
          body: {
            'message': 'This registration is no longer open. Start again.',
            'code': 'VERIFICATION_FAILED',
          },
        );

      final wrong = await api
          .verifyAccount(verificationId: 'x', code: '000000')
          .then<AppFailure?>((_) => null, onError: (Object e) => (e as ApiException).failure);
      expect(AuthFormState.issuesOf(wrong!), {'code': 'That code is not right. 4 tries left.'});

      final closed = await api
          .verifyAccount(verificationId: 'x', code: '000000')
          .then<AppFailure?>((_) => null, onError: (Object e) => (e as ApiException).failure);
      expect(closed, isA<NotFoundFailure>());
    });
  });

  group('naming the LMS', () {
    test('a pasted join link, a teaching link or the address itself gives the address', () {
      expect(
        AuthValidators.workspaceFrom('https://zuviloai.com/join/saraswati-coaching'),
        'saraswati-coaching',
      );
      expect(
        AuthValidators.workspaceFrom('https://zuviloai.com/join/Saraswati-Coaching/teach'),
        'saraswati-coaching',
      );
      expect(AuthValidators.workspaceFrom(' saraswati-coaching '), 'saraswati-coaching');
    });

    test('a teaching link opens the instructor form for its LMS, and nothing else', () {
      const route = '/register?workspace=saraswati-coaching&as=instructor';
      expect(resolveDeepLink('https://zuviloai.com/join/saraswati-coaching/teach').route, route);
      expect(deepLinkReplacement('/join/saraswati-coaching/teach'), route);
      expect(resolveDeepLink('https://zuviloai.com/join/Not_An/teach').isFollowed, isFalse);
      expect(deepLinkReplacement('/join/x/teach'), unroutableLocation);
    });

    test('no build registers anyone into a default LMS', () {
      for (final flavor in ['dev', 'staging', 'prod']) {
        final values =
            jsonDecode(File('config/$flavor.json').readAsStringSync()) as Map<String, dynamic>;
        expect(values.keys, isNot(contains('DEFAULT_WORKSPACE')), reason: 'config/$flavor.json');
      }
    });

    // Launch decision (2026-10-23): plans are bought on the website, never in the app — Google Play's payments policy
    // would otherwise apply. Every build that talks to the production API keeps in-app checkout off.
    test('no build that reaches production sells a plan in the app', () {
      for (final file in Directory(
        'config',
      ).listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
        final values = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        if ('${values['API_BASE_URL']}'.contains('zuviloai.com')) {
          expect(values['BILLING_CHECKOUT_ENABLED'], isNot(true), reason: file.path);
        }
      }
    });

    // Store policy (2026-10-23): online courses are digital content, which Google Play and the App Store sell only
    // through their own billing. Every build that talks to the production API keeps in-app course buying off; the
    // dev configs, where the flow is built and tried, have it on.
    test('no build that reaches production sells a course in the app', () {
      for (final file in Directory(
        'config',
      ).listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
        final values = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        if ('${values['API_BASE_URL']} ${values['WEB_BASE_URL']}'.contains('zuviloai.com')) {
          expect(values['COURSE_CHECKOUT_ENABLED'], isNot(true), reason: file.path);
        }
      }
      for (final name in ['prod', 'staging']) {
        final values =
            jsonDecode(File('config/$name.json').readAsStringSync()) as Map<String, dynamic>;
        expect(values['COURSE_CHECKOUT_ENABLED'], isFalse, reason: 'config/$name.json');
      }
      for (final name in ['dev', 'dev_device']) {
        final values =
            jsonDecode(File('config/$name.json').readAsStringSync()) as Map<String, dynamic>;
        expect(values['COURSE_CHECKOUT_ENABLED'], isTrue, reason: 'config/$name.json');
      }
    });
  });
}
