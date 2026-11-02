import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_cleanup.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/result.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/preferences.dart';
import '../../../shared/domain/user_profile.dart';
import '../data/auth_repository.dart';
import 'session_state.dart';

/// Owns the session (§6): restore at launch, sign in, register, sign out, and the single path a
/// 401 takes. It never decides authorization — it holds what the server said about the account.
class SessionController extends Notifier<SessionState> {
  /// When the profile was last confirmed with the server; permission changes apply on the next
  /// call anyway, so re-reading more often than this buys nothing (§7).
  DateTime? _profileReadAt;

  static const refreshProfileEvery = Duration(minutes: 5);

  @override
  SessionState build() {
    return const SessionUnknown();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Reads the stored token and confirms it with `GET /auth/me`.
  Future<void> restore() async {
    state = const SessionUnknown();
    final token = await _repository.readToken();
    if (token == null) {
      state = const SessionSignedOut();
      return;
    }
    final result = await _repository.currentUser();
    switch (result) {
      case Ok(:final value):
        _profileReadAt = DateTime.now();
        await _enter(value);
      case Err(:final failure) when failure is NetworkFailure || failure is ServerFailure:
        // Offline or the server is down: keep the token and let the splash offer Retry.
        state = SessionUnavailable(failure);
      case Err(failure: UnauthenticatedFailure()):
        await _signOut(reason: SignedOutReason.expired);
      case Err(:final failure):
        // 403 deactivated/suspended, 404 account gone, or anything else the session cannot survive.
        await _signOut(reason: SignedOutReason.refused, message: failure.message);
    }
  }

  Future<AppResult<UserProfile>> signIn({required String email, required String password}) async {
    final result = await _repository.signIn(email: email, password: password);
    if (result case Ok(:final value)) {
      _profileReadAt = DateTime.now();
      await _enter(value);
    }
    return result;
  }

  /// Registers a learner. Signed in at once only where the deployment skips email verification;
  /// otherwise [verifyAccount] finishes it.
  Future<AppResult<RegistrationStep>> register({
    required String name,
    required String email,
    required String password,
    required String workspace,
  }) async {
    final result = await _repository.register(
      name: name,
      email: email,
      password: password,
      workspace: workspace,
    );
    await _enterIfSignedIn(result);
    return result;
  }

  /// The code emailed to a learner or an instructor who registered themselves. A learner is signed
  /// in exactly as registering signs one in; an instructor's request waits for the LMS admin.
  Future<AppResult<RegistrationStep>> verifyAccount({
    required String verificationId,
    required String code,
  }) async {
    final result = await _repository.verifyAccount(verificationId: verificationId, code: code);
    await _enterIfSignedIn(result);
    return result;
  }

  Future<void> _enterIfSignedIn(AppResult<RegistrationStep> result) async {
    if (result case Ok(value: RegistrationSignedIn(:final profile))) await _enter(profile);
  }

  /// Starts registering an academy. Signed in at once only where the deployment skips email
  /// verification; otherwise [verifyAcademy] finishes it.
  Future<AppResult<AcademySignupStep>> startAcademy({
    required String academyName,
    required String name,
    required String email,
    required String password,
    String? slug,
  }) async {
    final result = await _repository.startAcademy(
      academyName: academyName,
      slug: slug,
      name: name,
      email: email,
      password: password,
    );
    if (result case Ok(value: SignupDone(:final profile))) await _enter(profile);
    return result;
  }

  /// The emailed code: the new academy's admin is signed in.
  Future<AppResult<UserProfile>> verifyAcademy({
    required String signupId,
    required String code,
  }) async {
    final result = await _repository.verifyAcademy(signupId: signupId, code: code);
    if (result case Ok(:final value)) await _enter(value);
    return result;
  }

  /// Accepts an invitation with a new learner account. The LMS and the role are the invitation's;
  /// the session then starts exactly as registering starts one.
  Future<AppResult<RegistrationStep>> registerWithInvitation({
    required String token,
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _repository.registerWithInvitation(
      token: token,
      name: name,
      email: email,
      password: password,
    );
    await _enterIfSignedIn(result);
    return result;
  }

  /// Accepts an invitation by signing in with the learner's existing account in that LMS.
  Future<AppResult<UserProfile>> signInWithInvitation({
    required String token,
    required String email,
    required String password,
  }) async {
    final result = await _repository.signInWithInvitation(
      token: token,
      email: email,
      password: password,
    );
    if (result case Ok(:final value)) {
      _profileReadAt = DateTime.now();
      await _enter(value);
    }
    return result;
  }

  /// Joins the course's LMS from a course link, as a new learner.
  Future<AppResult<RegistrationStep>> joinFromCourseLink({
    required String courseId,
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _repository.joinFromCourseLink(
      courseId: courseId,
      name: name,
      email: email,
      password: password,
    );
    await _enterIfSignedIn(result);
    return result;
  }

  /// Signed out by the person. The server ends the session first (`POST /auth/logout`, B1 settled
  /// by SAAS-020), so the token stops working everywhere rather than only being forgotten here.
  /// The local sign-out never depends on that call: offline, or with a token the server already
  /// refuses, the device is still cleared.
  Future<void> signOut() async {
    _signingOut = true;
    try {
      await _repository.endServerSession();
      await _signOut(reason: SignedOutReason.signedOut);
    } finally {
      _signingOut = false;
    }
  }

  /// Deletes the account (Google Play's account-deletion policy). The server has already ended every
  /// session when it answers, so the device is cleared at once rather than asking it to log out.
  Future<AppResult<void>> deleteAccount(String password) async {
    final result = await _repository.deleteAccount(password);
    if (result case Ok()) await _signOut(reason: SignedOutReason.deleted);
    return result;
  }

  /// A deliberate sign-out is in progress: a 401 from its own logout call is not an expiry.
  bool _signingOut = false;

  /// Called by the API client's single-flight 401 handling (§6).
  Future<void> handleSessionExpired() async {
    // Nothing to expire once signed out: a request that left with the old token and is refused after a
    // deliberate sign-out must not turn "signed out" into "session ended" (it would land on sign-in, not
    // Welcome). Restoring at launch handles its own refusal.
    if (_signingOut || state is SessionSignedOut || state is SessionUnknown) return;
    await _signOut(reason: SignedOutReason.expired);
  }

  /// Called by the API client when a request is refused because the platform suspended or closed the
  /// account's LMS. Signed out with the server's words, shown on the sign-in screen.
  Future<void> handleAccountClosed(AccountClosedFailure failure) async {
    if (_signingOut || state is! SessionSignedIn) return;
    await _signOut(reason: SignedOutReason.refused, message: failure.message);
  }

  /// Re-reads the profile when the last read is older than [refreshProfileEvery] — on app resume
  /// and on entering a shell (§7).
  Future<void> refreshProfileIfStale({DateTime? now}) async {
    final at = _profileReadAt;
    final moment = now ?? DateTime.now();
    if (at != null && moment.difference(at) < refreshProfileEvery) return;
    await refreshProfile();
  }

  /// Re-reads the profile (permission changes apply on the next call, §7). Failures leave the
  /// current session alone unless the server refused the account.
  Future<void> refreshProfile() async {
    if (state is! SessionSignedIn) return;
    final result = await _repository.currentUser();
    switch (result) {
      case Ok(:final value):
        _profileReadAt = DateTime.now();
        await _enter(value);
      case Err(failure: UnauthenticatedFailure()):
        await _signOut(reason: SignedOutReason.expired);
      case Err(:final failure) when failure is ForbiddenFailure || failure is PermissionFailure:
        await _signOut(reason: SignedOutReason.refused, message: failure.message);
      case Err():
        break;
    }
  }

  Future<void> _enter(UserProfile profile) async {
    if (profile.role == UserRole.superadmin) {
      // The API issued a token; the app keeps none and says where to go instead.
      await _clearSession();
      state = const SessionUnsupportedRole();
      return;
    }
    final previous = state.user;
    if (previous != null && previous.id != profile.id) {
      // A different person on the same device: nothing of the last one may remain (§8.4).
      await _purge();
    }
    state = SessionSignedIn(profile);
  }

  Future<void> _signOut({SignedOutReason reason = SignedOutReason.none, String? message}) async {
    await _clearSession();
    state = SessionSignedOut(reason: reason, message: message);
  }

  Future<void> _clearSession() async {
    await _repository.clearToken();
    await _purge();
  }

  Future<void> _purge() async {
    ref.read(apiClientProvider).endSession();
    await ref.read(preferencesProvider).clearUserScoped();
    final logger = ref.read(appLoggerProvider);
    await ref
        .read(sessionCleanupProvider)
        .runAll(
          onError: (e, s) => logger.error('session cleanup failed', error: e, stack: s),
        );
  }
}

final sessionControllerProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);
