import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/result.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/domain/user_profile.dart';
import 'auth_api.dart';
import 'dto/academy_signup.dart';
import 'dto/account_verification.dart';
import 'dto/auth_response.dart';
import 'dto/join_links.dart';
import 'secure_token_store.dart';

/// Turns the API's exceptions into `Result`s and owns where the token is kept. It never decides
/// who may do what — it only stores what the server issued.
class AuthRepository {
  AuthRepository({required AuthApi api, required SecureTokenStore tokens})
    : _api = api,
      _tokens = tokens;

  final AuthApi _api;
  final SecureTokenStore _tokens;

  Future<AppResult<UserProfile>> signIn({required String email, required String password}) =>
      _guard(() async {
        final response = await _api.login(email: email, password: password);
        await _tokens.write(response.token);
        return response.user;
      });

  /// Registers a learner: the code the server now waits for, or — where this deployment skips email
  /// verification — the learner, signed in.
  Future<AppResult<RegistrationStep>> register({
    required String name,
    required String email,
    required String password,
    required String workspace,
  }) => _guard(
    () async => _settle(
      await _api.register(name: name, email: email, password: password, workspace: workspace),
    ),
  );

  /// Starts registering an academy: the code it now waits for, or — where this deployment skips
  /// email verification — the new admin, signed in.
  Future<AppResult<AcademySignupStep>> startAcademy({
    required String academyName,
    required String name,
    required String email,
    required String password,
    String? slug,
  }) => _guard(() async {
    final started = await _api.signupStart(
      academyName: academyName,
      slug: slug,
      name: name,
      email: email,
      password: password,
    );
    if (started is SignupPending) return SignupNeedsCode(started);
    await _tokens.write((started as AuthResponse).token);
    return SignupDone(await _api.me());
  });

  Future<AppResult<SignupPending>> resendSignupCode(String signupId) =>
      _guard(() => _api.signupResend(signupId));

  /// The emailed code: the academy is created and its admin signed in; then `/auth/me` once, as
  /// [register] does.
  Future<AppResult<UserProfile>> verifyAcademy({required String signupId, required String code}) =>
      _guard(() async {
        final response = await _api.signupVerify(signupId: signupId, code: code);
        await _tokens.write(response.token);
        return _api.me();
      });

  /// Registers an instructor: the code the server now waits for, or the request waiting for the LMS
  /// admin's approval. Either way no token, nothing stored.
  Future<AppResult<RegistrationStep>> requestInstructorAccess({
    required String workspace,
    required String name,
    required String email,
    required String password,
    String? title,
  }) => _guard(
    () async => _settle(
      await _api.requestInstructorAccess(
        workspace: workspace,
        name: name,
        email: email,
        password: password,
        title: title,
      ),
    ),
  );

  /// A new code for an open learner or instructor registration.
  Future<AppResult<VerificationPending>> resendAccountCode(String verificationId) =>
      _guard(() => _api.resendVerification(verificationId));

  /// The emailed code: a learner is signed in, an instructor's request reaches the LMS admin.
  Future<AppResult<RegistrationStep>> verifyAccount({
    required String verificationId,
    required String code,
  }) => _guard(
    () async => _settle(await _api.verifyAccount(verificationId: verificationId, code: code)),
  );

  Future<AppResult<LmsJoinPage>> lmsJoinPage(String slug) => _guard(() => _api.lmsJoinPage(slug));

  Future<AppResult<InvitationView>> invitation(String token) =>
      _guard(() => _api.invitation(token));

  Future<AppResult<CourseLinkView>> courseLink(String courseId) =>
      _guard(() => _api.courseLink(courseId));

  /// Accepts an invitation with a new account: the code the server now waits for, or the learner,
  /// signed in.
  Future<AppResult<RegistrationStep>> registerWithInvitation({
    required String token,
    required String name,
    required String email,
    required String password,
  }) => _guard(
    () async => _settle(
      await _api.registerWithInvitation(token: token, name: name, email: email, password: password),
    ),
  );

  /// Accepts an invitation with the account the learner already has in that LMS.
  Future<AppResult<UserProfile>> signInWithInvitation({
    required String token,
    required String email,
    required String password,
  }) => _guard(() async {
    final response = await _api.signInWithInvitation(
      token: token,
      email: email,
      password: password,
    );
    await _tokens.write(response.token);
    return _api.me();
  });

  /// Joins the course's LMS from a course link: the code the server now waits for, or the learner,
  /// signed in. The account is made whether or not the LMS's policy enrolled it;
  /// [RegistrationSignedIn] says which, with the server's reason when it did not.
  Future<AppResult<RegistrationStep>> joinFromCourseLink({
    required String courseId,
    required String name,
    required String email,
    required String password,
  }) => _guard(
    () async => _settle(
      await _api.joinFromCourseLink(
        courseId: courseId,
        name: name,
        email: email,
        password: password,
      ),
    ),
  );

  /// Where a registration door's (or the code's) answer leaves the person. A new account's token is
  /// stored, then `/auth/me` read once: the answer carries no `permissions` and the canonical
  /// profile is the one the session runs on (§6).
  Future<RegistrationStep> _settle(AccountReply reply) async {
    switch (reply) {
      case AccountNeedsCode(:final pending):
        return RegistrationNeedsCode(pending);
      case AccountAwaitingApproval(:final message):
        return RegistrationAwaitingApproval(message);
      case AccountCreated(:final auth, :final enrolled, :final enrolment, :final enrolmentCode):
        await _tokens.write(auth.token);
        return RegistrationSignedIn(
          await _api.me(),
          enrolled: enrolled,
          enrolment: enrolment,
          enrolmentCode: enrolmentCode,
        );
    }
  }

  Future<AppResult<UserProfile>> currentUser() => _guard(_api.me);

  /// Ends the server-side session for the stored token. Must run before [clearToken].
  Future<AppResult<void>> endServerSession() => _guard(_api.logout);

  Future<AppResult<void>> forgotPassword(String email) => _guard(() => _api.forgotPassword(email));

  Future<AppResult<bool>> isResetTokenValid(String token) =>
      _guard(() => _api.isResetTokenValid(token));

  Future<AppResult<void>> resetPassword({required String token, required String password}) =>
      _guard(() => _api.resetPassword(token: token, password: password));

  Future<AppResult<void>> deleteAccount(String password) =>
      _guard(() => _api.deleteAccount(password));

  Future<AppResult<bool>> serverReachable() => _guard(_api.health);

  Future<String?> readToken() => _tokens.read();

  Future<void> clearToken() => _tokens.clear();

  Future<AppResult<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Ok(await call());
    } on ApiException catch (e) {
      return Err(e.failure);
    }
  }
}

/// Where registering an academy stands after `POST /signup/start`.
sealed class AcademySignupStep {
  const AcademySignupStep();
}

/// The server emailed a code; nothing exists until it is entered.
final class SignupNeedsCode extends AcademySignupStep {
  const SignupNeedsCode(this.pending);
  final SignupPending pending;
}

/// Email verification is off for this deployment: the academy exists and its admin is signed in.
final class SignupDone extends AcademySignupStep {
  const SignupDone(this.profile);
  final UserProfile profile;
}

/// Where a learner's or instructor's own registration stands — after its door (a join link, an
/// invitation, a course link, a request to teach) or after the emailed code.
sealed class RegistrationStep {
  const RegistrationStep();
}

/// The server emailed a code; nothing that can sign in exists until it is entered.
final class RegistrationNeedsCode extends RegistrationStep {
  const RegistrationNeedsCode(this.pending);
  final VerificationPending pending;
}

/// A learner's account exists and they are signed in. For a course link, [enrolled] says whether the
/// LMS's policy enrolled it and [enrolment] is the server's reason when not; both are null elsewhere.
/// [enrolmentCode] is that reason's code (`COURSE_PURCHASE_REQUIRED`: the course is bought, not joined).
final class RegistrationSignedIn extends RegistrationStep {
  const RegistrationSignedIn(this.profile, {this.enrolled, this.enrolment, this.enrolmentCode});
  final UserProfile profile;
  final bool? enrolled;
  final String? enrolment;
  final String? enrolmentCode;

  /// The course is a paid one: the learner goes on to its page to buy it.
  bool get purchaseRequired => enrolmentCode == 'COURSE_PURCHASE_REQUIRED';
}

/// An instructor's request waits for the LMS admin's approval (D34): nobody is signed in. [message]
/// is the server's own words.
final class RegistrationAwaitingApproval extends RegistrationStep {
  const RegistrationAwaitingApproval(this.message);
  final String? message;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) =>
      AuthRepository(api: ref.watch(authApiProvider), tokens: ref.watch(secureTokenStoreProvider)),
);
