import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import '../../../shared/domain/user_profile.dart';
import 'dto/academy_signup.dart';
import 'dto/account_verification.dart';
import 'dto/auth_response.dart';
import 'dto/join_links.dart';

/// `apps/api/src/routes/auth.ts`. Requests carry only the fields the route's zod schema reads —
/// never `role`, never a tenant (§7, §8).
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<AuthResponse> login({required String email, required String password}) async {
    const endpoint = 'POST /auth/login';
    final body = await _client.post(
      '/auth/login',
      body: {'email': email.trim().toLowerCase(), 'password': password},
    );
    return AuthResponse.fromJson(asJsonObject(endpoint, body));
  }

  /// Always creates a learner; the role is the server's to decide. [workspace] is the address from
  /// a join link, left out of the request when empty. The server ignores it and places every learner
  /// in the platform's one workspace; the account's workspace is read from its row from then on.
  /// An [AccountNeedsCode] while the server waits for the emailed code; an [AccountCreated] where
  /// this deployment skips email verification.
  Future<AccountReply> register({
    required String name,
    required String email,
    required String password,
    required String workspace,
  }) async {
    const endpoint = 'POST /auth/register';
    final body = await _client.post(
      '/auth/register',
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        if (workspace.isNotEmpty) 'workspace': workspace,
      },
    );
    return AccountReply.parse(endpoint, body);
  }

  /* ── Registering an academy and its admin (`apps/api/src/routes/signup.ts`) ────────────────────
   * The registrant is always the new academy's owner admin, and the academy starts with no plan: a
   * trial or a purchase comes next, from the admin's own plan page. Nothing here names a role. */

  /// Starts registering an academy. A [SignupPending] while the server waits for the emailed code;
  /// an [AuthResponse] when this deployment skips email verification and the academy exists.
  Future<Object> signupStart({
    required String academyName,
    required String name,
    required String email,
    required String password,
    String? slug,
  }) async {
    const endpoint = 'POST /signup/start';
    final body = asJsonObject(
      endpoint,
      await _client.post(
        '/signup/start',
        body: {
          'academyName': academyName.trim(),
          if (slug != null && slug.trim().isNotEmpty) 'slug': slug.trim().toLowerCase(),
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'acceptTerms': true,
        },
      ),
    );
    return body['status'] == 'created'
        ? AuthResponse.fromJson(body)
        : parseResponse(endpoint, body, (b) => SignupPending.fromJson(asJsonObject(endpoint, b)));
  }

  /// A new code for an open registration; the old one stops working.
  Future<SignupPending> signupResend(String signupId) async {
    const endpoint = 'POST /signup/resend';
    final body = await _client.post('/signup/resend', body: {'signupId': signupId});
    return parseResponse(endpoint, body, (b) => SignupPending.fromJson(asJsonObject(endpoint, b)));
  }

  /// The emailed code: creates the academy and signs its admin in.
  Future<AuthResponse> signupVerify({required String signupId, required String code}) async {
    const endpoint = 'POST /signup/verify';
    final body = await _client.post(
      '/signup/verify',
      body: {'signupId': signupId, 'code': code.trim()},
    );
    return AuthResponse.fromJson(asJsonObject(endpoint, body));
  }

  /* ── The ways into an Admin's LMS (`apps/api/src/routes/publicSite.ts`) ─────────────────────
   * Each link names the LMS itself — a join link by its address, an invitation by its token, a
   * course link by its course. The server reads the workspace and the role from what the link
   * names; the request carries only the person's own details (§7, §8). */

  /// Asks to teach in the LMS at [workspace] (D34). The account is created pending the LMS admin's
  /// approval: nobody is signed in, and sign-in is refused until then. The role and the LMS are the
  /// server's — the request carries only the person's own details. An [AccountNeedsCode] while the
  /// server waits for the emailed code; an [AccountAwaitingApproval] where verification is off.
  Future<AccountReply> requestInstructorAccess({
    required String workspace,
    required String name,
    required String email,
    required String password,
    String? title,
  }) async {
    const endpoint = 'POST /public/academies/:slug/instructor-requests';
    final body = await _client.post(
      ApiPath.of(['public', 'academies', ApiPath.id(workspace), 'instructor-requests']),
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      },
    );
    return AccountReply.parse(endpoint, body);
  }

  /// The LMS a join link names (`GET /public/academies/:slug`).
  Future<LmsJoinPage> lmsJoinPage(String slug) async {
    const endpoint = 'GET /public/academies/:slug';
    final body = await _client.get(ApiPath.of(['public', 'academies', ApiPath.id(slug)]));
    return parseResponse(endpoint, body, (b) => LmsJoinPage.fromJson(asJsonObject(endpoint, b)));
  }

  /// What an invitation offers. The token is a path segment and is never logged.
  Future<InvitationView> invitation(String token) async {
    const endpoint = 'GET /public/invitations/:token';
    final body = await _client.get(ApiPath.of(['public', 'invitations', ApiPath.id(token)]));
    return parseResponse(endpoint, body, (b) => InvitationView.fromJson(asJsonObject(endpoint, b)));
  }

  /// Creates a learner account in the invitation's LMS and uses the invitation — once the emailed
  /// code is entered, where the deployment verifies email.
  Future<AccountReply> registerWithInvitation({
    required String token,
    required String name,
    required String email,
    required String password,
  }) async {
    const endpoint = 'POST /public/invitations/:token/register';
    final body = await _client.post(
      ApiPath.of(['public', 'invitations', ApiPath.id(token), 'register']),
      body: _newAccount(name: name, email: email, password: password),
    );
    return AccountReply.parse(endpoint, body);
  }

  /// Signs in with an account the learner already has in the invitation's LMS, and uses it. An
  /// account of another LMS, or a staff account, is refused (409) — a link never moves an account.
  Future<AuthResponse> signInWithInvitation({
    required String token,
    required String email,
    required String password,
  }) async {
    const endpoint = 'POST /public/invitations/:token/sign-in';
    final body = await _client.post(
      ApiPath.of(['public', 'invitations', ApiPath.id(token), 'sign-in']),
      body: {'email': email.trim().toLowerCase(), 'password': password},
    );
    return AuthResponse.fromJson(asJsonObject(endpoint, body));
  }

  /// The course a course link names, and its LMS.
  Future<CourseLinkView> courseLink(String courseId) async {
    const endpoint = 'GET /public/courses/:courseId/enroll';
    final body = await _client.get(
      ApiPath.of(['public', 'courses', ApiPath.id(courseId), 'enroll']),
    );
    return parseResponse(endpoint, body, (b) => CourseLinkView.fromJson(asJsonObject(endpoint, b)));
  }

  /// Creates a learner account in the course's LMS and enrols it when the LMS's policy allows — once
  /// the emailed code is entered, where the deployment verifies email. The [AccountCreated] says
  /// whether it was enrolled, and the server's reason when not.
  Future<AccountReply> joinFromCourseLink({
    required String courseId,
    required String name,
    required String email,
    required String password,
  }) async {
    const endpoint = 'POST /public/courses/:courseId/enroll';
    final body = await _client.post(
      ApiPath.of(['public', 'courses', ApiPath.id(courseId), 'enroll']),
      body: _newAccount(name: name, email: email, password: password),
    );
    return AccountReply.parse(endpoint, body);
  }

  /* ── The emailed code for a learner's or instructor's own registration ─────────────────────
   * The id names a registration the server holds in the LMS its link named; nothing here can
   * choose an LMS, a role, an invitation or a course. */

  /// A new code for an open registration; the old one stops working. 429 before
  /// `resendAvailableAt`, and once the registration has had all its codes.
  Future<VerificationPending> resendVerification(String verificationId) async {
    const endpoint = 'POST /public/verifications/resend';
    final body = await _client.post(
      '/public/verifications/resend',
      body: {'verificationId': verificationId},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => VerificationPending.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// The emailed code: a learner's account is created and signed in ([AccountCreated]); an
  /// instructor's request reaches the LMS admin and nobody is signed in ([AccountAwaitingApproval]).
  /// Every rule the door checked is checked again, so a 409 or 403 can still arrive here.
  Future<AccountReply> verifyAccount({required String verificationId, required String code}) async {
    const endpoint = 'POST /public/verifications/verify';
    final body = await _client.post(
      '/public/verifications/verify',
      body: {'verificationId': verificationId, 'code': code.trim()},
    );
    return AccountReply.parse(endpoint, body);
  }

  Map<String, Object> _newAccount({
    required String name,
    required String email,
    required String password,
  }) => {'name': name.trim(), 'email': email.trim().toLowerCase(), 'password': password};

  Future<UserProfile> me() async {
    const endpoint = 'GET /auth/me';
    final body = await _client.get('/auth/me');
    return UserProfile.fromJson(asJsonObject(endpoint, asJsonObject(endpoint, body)['user']));
  }

  /// Ends the session this token belongs to on the server (`POST /auth/logout`, no body). The
  /// token is sent as usual by the client; after this the server refuses it.
  Future<void> logout() async {
    await _client.post('/auth/logout');
  }

  Future<void> forgotPassword(String email) async {
    await _client.post('/auth/forgot-password', body: {'email': email.trim().toLowerCase()});
  }

  /// Whether a reset link is still usable. The token is a path segment and is never logged.
  Future<bool> isResetTokenValid(String token) async {
    const endpoint = 'GET /auth/reset-password/:token';
    final body = await _client.get(ApiPath.of(['auth', 'reset-password', ApiPath.id(token)]));
    return asJsonObject(endpoint, body)['valid'] == true;
  }

  Future<void> resetPassword({required String token, required String password}) async {
    await _client.post('/auth/reset-password', body: {'token': token, 'password': password});
  }

  /// Deletes the signed-in learner's own account (`POST /auth/delete-account`). The server checks
  /// the password, anonymises the account and ends every session; staff are refused with 403.
  Future<void> deleteAccount(String password) async {
    await _client.post('/auth/delete-account', body: {'password': password});
  }

  /// Reachability, to tell "server down" from "signed out" on the splash (§17).
  Future<bool> health() async {
    final body = await _client.get('/health');
    return body is Map && body['ok'] == true;
  }
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));
