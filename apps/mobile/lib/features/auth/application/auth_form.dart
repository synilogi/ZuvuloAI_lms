import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/result.dart';
import '../data/auth_repository.dart';
import '../data/dto/academy_signup.dart';
import '../data/dto/account_verification.dart';
import '../data/dto/join_links.dart';
import 'session_controller.dart';

/// The refusal the registration screens name: an LMS that adds learners by invitation only.
export '../../../core/network/error_decoder.dart' show InvitationRequiredFailure;

/// What registering an academy, a learner or an instructor answers, for their screens.
export '../data/auth_repository.dart'
    show
        AcademySignupStep,
        RegistrationAwaitingApproval,
        RegistrationNeedsCode,
        RegistrationSignedIn,
        RegistrationStep,
        SignupDone,
        SignupNeedsCode;
export '../data/dto/academy_signup.dart';
export '../data/dto/account_verification.dart' show VerificationPending;

/// What the link screens read (`InvitationView`, `CourseLinkView`, `LmsJoinPage`).
export '../data/dto/join_links.dart';

/// What an auth form shows while it is being submitted (§16): a busy button, the server's refusal,
/// and its issues mapped onto fields.
class AuthFormState {
  const AuthFormState({
    this.busy = false,
    this.failure,
    this.fieldErrors = const {},
    this.done = false,
  });

  final bool busy;

  /// The last refusal; the screen turns it into a title plus the server's message.
  final AppFailure? failure;

  /// Server `issues` by field name (`path`, or a 409's `field`), e.g.
  /// `{'password': 'Password must be at least…'}` or `{'email': 'An account with this email…'}`.
  final Map<String, String> fieldErrors;

  /// The action succeeded (used by forms that stay on screen, like forgot password).
  final bool done;

  static Map<String, String> issuesOf(AppFailure failure) => switch (failure) {
    ValidationFailure(:final issues) || ConflictFailure(:final issues) => {
      for (final issue in issues)
        if (issue.key != null) issue.key!: issue.message,
    },
    _ => const {},
  };
}

/// Shared submit handling for the auth forms.
abstract class AuthFormController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  AuthRepository get repository => ref.read(authRepositoryProvider);

  SessionController get session => ref.read(sessionControllerProvider.notifier);

  /// Runs [action], keeping the form busy meanwhile and mapping a refusal onto the fields.
  Future<bool> submit(Future<AppResult<Object?>> Function() action) async {
    if (state.busy) return false;
    state = const AuthFormState(busy: true);
    final result = await action();
    switch (result) {
      case Ok():
        state = const AuthFormState(done: true);
        return true;
      case Err(:final failure):
        state = AuthFormState(failure: failure, fieldErrors: AuthFormState.issuesOf(failure));
        return false;
    }
  }
}

class LoginController extends AuthFormController {
  Future<bool> signIn({required String email, required String password}) =>
      submit(() => session.signIn(email: email, password: password));
}

/// The forms where a learner or an instructor registers themselves: the details, then — where the
/// deployment verifies email — the 6-digit code emailed to them. Nothing that can sign in exists
/// until the code is entered.
abstract class RegistrationFormController extends AuthFormController {
  /// Runs a registration call; returns where it stands, or null when the server refused (the state
  /// then says why).
  Future<RegistrationStep?> step(Future<AppResult<RegistrationStep>> Function() action) async {
    RegistrationStep? step;
    final ok = await submit(() async {
      final result = await action();
      if (result case Ok(:final value)) step = value;
      return result;
    });
    // Waiting for the code is not finishing: the form is not done until someone is signed in.
    if (step is RegistrationNeedsCode) state = const AuthFormState();
    return ok ? step : null;
  }

  /// The emailed code.
  Future<RegistrationStep?> verify({required String verificationId, required String code}) =>
      step(() => session.verifyAccount(verificationId: verificationId, code: code));

  /// A new code; returns the registration's new timings, or null when refused.
  Future<VerificationPending?> resend(String verificationId) async {
    VerificationPending? pending;
    final ok = await submit(() async {
      final result = await repository.resendAccountCode(verificationId);
      if (result case Ok(:final value)) pending = value;
      return result;
    });
    // Resending is not finishing: the code form stays as it was.
    if (ok) state = const AuthFormState();
    return pending;
  }

  /// Going back from the code to the details (or between forms) leaves the last refusal behind.
  void clear() => state = const AuthFormState();
}

class RegisterController extends RegistrationFormController {
  Future<RegistrationStep?> register({
    required String name,
    required String email,
    required String password,
    required String workspace,
  }) => step(
    () => session.register(name: name, email: email, password: password, workspace: workspace),
  );
}

/// Registering as an instructor (D34): the request goes to the LMS admin; nobody is signed in.
class InstructorSignupController extends RegistrationFormController {
  Future<RegistrationStep?> register({
    required String workspace,
    required String name,
    required String email,
    required String password,
    String? title,
  }) => step(
    () => repository.requestInstructorAccess(
      workspace: workspace,
      name: name,
      email: email,
      password: password,
      title: title,
    ),
  );
}

/// Registering an academy and its admin: the details, then the code emailed to them.
class AcademySignupController extends AuthFormController {
  /// Returns where the registration stands, or null when the server refused (the state says why).
  Future<AcademySignupStep?> start({
    required String academyName,
    required String name,
    required String email,
    required String password,
    String? slug,
  }) async {
    AcademySignupStep? step;
    final ok = await submit(() async {
      final result = await session.startAcademy(
        academyName: academyName,
        slug: slug,
        name: name,
        email: email,
        password: password,
      );
      if (result case Ok(:final value)) step = value;
      return result;
    });
    return ok ? step : null;
  }

  Future<bool> verify({required String signupId, required String code}) =>
      submit(() => session.verifyAcademy(signupId: signupId, code: code));

  /// A new code; returns the registration's new timings, or null when refused.
  Future<SignupPending?> resend(String signupId) async {
    SignupPending? pending;
    final ok = await submit(() async {
      final result = await repository.resendSignupCode(signupId);
      if (result case Ok(:final value)) pending = value;
      return result;
    });
    // Resending is not finishing: the code form stays as it was.
    if (ok) state = const AuthFormState();
    return pending;
  }

  /// Going back from the code to the details leaves the code's refusal behind.
  void clear() => state = const AuthFormState();
}

/// The invitation screen: a new account, or the learner's existing one in the invitation's LMS.
class InvitationController extends RegistrationFormController {
  Future<RegistrationStep?> register({
    required String token,
    required String name,
    required String email,
    required String password,
  }) => step(
    () =>
        session.registerWithInvitation(token: token, name: name, email: email, password: password),
  );

  Future<bool> signIn({required String token, required String email, required String password}) =>
      submit(() => session.signInWithInvitation(token: token, email: email, password: password));
}

/// The course-link screen's Create account: the account, and whether the LMS enrolled it
/// ([RegistrationSignedIn.enrolled]).
class CourseJoinController extends RegistrationFormController {
  Future<RegistrationStep?> join({
    required String courseId,
    required String name,
    required String email,
    required String password,
  }) => step(
    () => session.joinFromCourseLink(
      courseId: courseId,
      name: name,
      email: email,
      password: password,
    ),
  );
}

class ForgotPasswordController extends AuthFormController {
  /// Always reports success: the server never says whether the address exists.
  Future<bool> sendLink(String email) => submit(() => repository.forgotPassword(email));
}

class ResetPasswordController extends AuthFormController {
  Future<bool> setPassword({required String token, required String password}) =>
      submit(() => repository.resetPassword(token: token, password: password));
}

final loginControllerProvider = NotifierProvider<LoginController, AuthFormState>(
  LoginController.new,
);
final registerControllerProvider = NotifierProvider<RegisterController, AuthFormState>(
  RegisterController.new,
);

final instructorSignupControllerProvider =
    NotifierProvider<InstructorSignupController, AuthFormState>(
      InstructorSignupController.new,
      isAutoDispose: true,
    );

final academySignupControllerProvider = NotifierProvider<AcademySignupController, AuthFormState>(
  AcademySignupController.new,
  isAutoDispose: true,
);

/// Screen-scoped: a link's form starts clean every time, and nothing of it outlives the screen.
final invitationControllerProvider = NotifierProvider<InvitationController, AuthFormState>(
  InvitationController.new,
  isAutoDispose: true,
);
final courseJoinControllerProvider = NotifierProvider<CourseJoinController, AuthFormState>(
  CourseJoinController.new,
  isAutoDispose: true,
);
final forgotPasswordControllerProvider = NotifierProvider<ForgotPasswordController, AuthFormState>(
  ForgotPasswordController.new,
);
final resetPasswordControllerProvider = NotifierProvider<ResetPasswordController, AuthFormState>(
  ResetPasswordController.new,
);

/// Whether a reset link is still usable (`GET /auth/reset-password/:token`). The failure is carried
/// as a value so the screen can tell "link expired" from "we couldn't reach the server".
final resetTokenValidProvider = FutureProvider.autoDispose.family<AppResult<bool>, String>((
  ref,
  token,
) async {
  return ref.watch(authRepositoryProvider).isResetTokenValid(token);
});

/// The LMS a join link names (`GET /public/academies/:slug`). Like the two below, auto-disposed and
/// read without a session, so nothing of it belongs to whoever is signed in; the failure is a value
/// so the screen can tell "no such LMS" from "we couldn't reach the server".
final lmsJoinPageProvider = FutureProvider.autoDispose.family<AppResult<LmsJoinPage>, String>((
  ref,
  slug,
) async {
  return ref.watch(authRepositoryProvider).lmsJoinPage(slug);
});

/// What an invitation link offers (`GET /public/invitations/:token`).
final invitationProvider = FutureProvider.autoDispose.family<AppResult<InvitationView>, String>((
  ref,
  token,
) async {
  return ref.watch(authRepositoryProvider).invitation(token);
});

/// The course a course link names (`GET /public/courses/:courseId/enroll`).
final courseLinkProvider = FutureProvider.autoDispose.family<AppResult<CourseLinkView>, String>((
  ref,
  courseId,
) async {
  return ref.watch(authRepositoryProvider).courseLink(courseId);
});
