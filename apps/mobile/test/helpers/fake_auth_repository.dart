import 'dart:async';

import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/errors/result.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/auth/data/auth_repository.dart';

/// A scriptable stand-in for [AuthRepository]: the session controller and the screens run for
/// real, the network does not.
class FakeAuthRepository implements AuthRepository {
  /// The account the server would return.
  UserProfile? profile;

  /// The token in secure storage at launch.
  String? token;

  /// Set to make the next call fail.
  AppFailure? failure;

  /// Fails only `GET /auth/me` (session restore), leaving sign-in working.
  AppFailure? meFailure;

  bool resetTokenValid = true;

  /// Hold `GET /auth/me` open, to observe the restoring state.
  Completer<void>? meGate;
  final List<String> calls = [];

  @override
  Future<AppResult<UserProfile>> signIn({required String email, required String password}) async {
    calls.add('signIn:$email');
    if (failure != null) return Err(failure!);
    token = 'token-for-$email';
    return Ok(profile!);
  }

  /* ── A learner's or instructor's own registration ─────────────────── */

  /// Whether the doors wait for an emailed code (the server's default) rather than answering with
  /// the account at once, as a deployment with verification off does.
  bool accountVerification = false;

  /// Fails only `POST /public/verifications/verify`, leaving the doors working.
  AppFailure? verifyFailure;

  /// Fails only `POST /public/verifications/resend`.
  AppFailure? resendFailure;

  /// The door the open registration came through: `learner`, `course` or `instructor`.
  String? _door;
  String? _doorEmail;

  VerificationPending _pendingFor(String email, {String role = 'student'}) => VerificationPending(
    verificationId: 'verification-1',
    email: email,
    role: role,
    lms: joinPage?.name ?? invitationView?.lms.name ?? courseLinkView?.lms.name ?? 'Jyotish Vidya',
    expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
    resendAvailableAt: DateTime.utc(2020),
  );

  /// The door's answer: a code to wait for, or — verification off — the account itself.
  AppResult<RegistrationStep> _answer(String door, String email, RegistrationStep Function() now) {
    if (failure != null) return Err(failure!);
    if (!accountVerification) return Ok(now());
    _door = door;
    _doorEmail = email;
    return Ok(
      RegistrationNeedsCode(
        _pendingFor(email, role: door == 'instructor' ? 'instructor' : 'student'),
      ),
    );
  }

  RegistrationStep _signedIn(String email, {bool course = false}) {
    token = 'token-for-$email';
    return course
        ? RegistrationSignedIn(
            profile!,
            enrolled: courseJoinEnrolled,
            enrolment: courseJoinEnrolment,
          )
        : RegistrationSignedIn(profile!);
  }

  @override
  Future<AppResult<RegistrationStep>> register({
    required String name,
    required String email,
    required String password,
    required String workspace,
  }) async {
    calls.add('register:$email@$workspace');
    return _answer('learner', email, () => _signedIn(email));
  }

  @override
  Future<AppResult<VerificationPending>> resendAccountCode(String verificationId) async {
    calls.add('resendAccountCode:$verificationId');
    if (resendFailure != null) return Err(resendFailure!);
    return Ok(
      _pendingFor(_doorEmail ?? '', role: _door == 'instructor' ? 'instructor' : 'student'),
    );
  }

  @override
  Future<AppResult<RegistrationStep>> verifyAccount({
    required String verificationId,
    required String code,
  }) async {
    calls.add('verifyAccount:$verificationId:$code');
    if (verifyFailure != null) return Err(verifyFailure!);
    return Ok(switch (_door) {
      'instructor' => const RegistrationAwaitingApproval(
        'Your instructor account is pending Admin approval.',
      ),
      'course' => _signedIn(_doorEmail ?? '', course: true),
      _ => _signedIn(_doorEmail ?? ''),
    });
  }

  /* ── Registering as an instructor (D34) ───────────────────────────── */

  @override
  Future<AppResult<RegistrationStep>> requestInstructorAccess({
    required String workspace,
    required String name,
    required String email,
    required String password,
    String? title,
  }) async {
    calls.add('requestInstructorAccess:$email@$workspace');
    return _answer(
      'instructor',
      email,
      () =>
          const RegistrationAwaitingApproval('Your instructor account is pending Admin approval.'),
    );
  }

  /* ── Registering an academy ───────────────────────────────────────── */

  /// What `POST /signup/start` answers: waits for a code unless verification is off.
  bool signupVerificationOff = false;

  static final _pending = SignupPending(
    signupId: 'signup-1',
    email: 'owner@example.com',
    expiresAt: DateTime.utc(2030),
    resendAvailableAt: DateTime.utc(2020),
  );

  @override
  Future<AppResult<AcademySignupStep>> startAcademy({
    required String academyName,
    required String name,
    required String email,
    required String password,
    String? slug,
  }) async {
    calls.add('startAcademy:$email@${slug ?? ''}');
    if (failure != null) return Err(failure!);
    if (!signupVerificationOff) return Ok(SignupNeedsCode(_pending.copyWith(email: email)));
    token = 'token-for-$email';
    return Ok(SignupDone(profile!));
  }

  @override
  Future<AppResult<SignupPending>> resendSignupCode(String signupId) async {
    calls.add('resendSignupCode:$signupId');
    if (failure != null) return Err(failure!);
    return Ok(_pending);
  }

  @override
  Future<AppResult<UserProfile>> verifyAcademy({
    required String signupId,
    required String code,
  }) async {
    calls.add('verifyAcademy:$signupId:$code');
    if (failure != null) return Err(failure!);
    token = 'token-for-academy';
    return Ok(profile!);
  }

  /* ── Links into an LMS ─────────────────────────────────────────────── */

  /// What `GET /public/academies/:slug` answers; null answers 404.
  LmsJoinPage? joinPage;

  /// What `GET /public/invitations/:token` answers; null answers 404 `INVITE_INVALID`.
  InvitationView? invitationView;

  /// What `GET /public/courses/:courseId/enroll` answers; null answers 404.
  CourseLinkView? courseLinkView;

  /// Fails only the read of a link (`GET /public/…`), leaving the forms working.
  AppFailure? linkFailure;

  /// Whether a course link's Create account was enrolled, and the server's reason when not.
  bool courseJoinEnrolled = true;
  String? courseJoinEnrolment;

  static const _notFound = NotFoundFailure(message: 'Not found.');

  @override
  Future<AppResult<LmsJoinPage>> lmsJoinPage(String slug) async {
    calls.add('lmsJoinPage:$slug');
    if (linkFailure != null) return Err(linkFailure!);
    return joinPage == null ? const Err(_notFound) : Ok(joinPage!);
  }

  @override
  Future<AppResult<InvitationView>> invitation(String token) async {
    calls.add('invitation');
    if (linkFailure != null) return Err(linkFailure!);
    return invitationView == null
        ? const Err(
            NotFoundFailure(
              message:
                  'This invitation link isn’t valid. It may have expired, been used or been '
                  'withdrawn — ask your teacher or school for a new one.',
            ),
          )
        : Ok(invitationView!);
  }

  @override
  Future<AppResult<CourseLinkView>> courseLink(String courseId) async {
    calls.add('courseLink:$courseId');
    if (linkFailure != null) return Err(linkFailure!);
    return courseLinkView == null ? const Err(_notFound) : Ok(courseLinkView!);
  }

  @override
  Future<AppResult<RegistrationStep>> registerWithInvitation({
    required String token,
    required String name,
    required String email,
    required String password,
  }) async {
    calls.add('registerWithInvitation:$email');
    return _answer('learner', email, () => _signedIn(email));
  }

  @override
  Future<AppResult<UserProfile>> signInWithInvitation({
    required String token,
    required String email,
    required String password,
  }) async {
    calls.add('signInWithInvitation:$email');
    if (failure != null) return Err(failure!);
    this.token = 'token-for-$email';
    return Ok(profile!);
  }

  @override
  Future<AppResult<RegistrationStep>> joinFromCourseLink({
    required String courseId,
    required String name,
    required String email,
    required String password,
  }) async {
    calls.add('joinFromCourseLink:$courseId:$email');
    return _answer('course', email, () => _signedIn(email, course: true));
  }

  @override
  Future<AppResult<UserProfile>> currentUser() async {
    calls.add('me');
    await meGate?.future;
    final problem = meFailure ?? failure;
    if (problem != null) return Err(problem);
    final user = profile;
    return user == null ? const Err(UnauthenticatedFailure()) : Ok(user);
  }

  /// Set to make only `POST /auth/logout` fail (offline, or a token the server already refused).
  AppFailure? logoutFailure;

  /// Runs while `POST /auth/logout` is in flight (e.g. the client's 401 handling).
  Future<void> Function()? onLogout;

  @override
  Future<AppResult<void>> endServerSession() async {
    calls.add('logout');
    await onLogout?.call();
    return logoutFailure == null ? const Ok(null) : Err(logoutFailure!);
  }

  @override
  Future<AppResult<void>> forgotPassword(String email) async {
    calls.add('forgotPassword:$email');
    return failure == null ? const Ok(null) : Err(failure!);
  }

  @override
  Future<AppResult<bool>> isResetTokenValid(String token) async {
    calls.add('isResetTokenValid');
    return failure == null ? Ok(resetTokenValid) : Err(failure!);
  }

  @override
  Future<AppResult<void>> resetPassword({required String token, required String password}) async {
    calls.add('resetPassword');
    return failure == null ? const Ok(null) : Err(failure!);
  }

  @override
  Future<AppResult<void>> deleteAccount(String password) async {
    calls.add('deleteAccount');
    return failure == null ? const Ok(null) : Err(failure!);
  }

  @override
  Future<AppResult<bool>> serverReachable() async =>
      failure == null ? const Ok(true) : Err(failure!);

  @override
  Future<String?> readToken() async {
    calls.add('readToken');
    return token;
  }

  @override
  Future<void> clearToken() async {
    calls.add('clearToken');
    token = null;
  }
}
