import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/route_access.dart';
import '../../../../app/routing/routes.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/user_profile.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../course_learning/course_learning.dart';
import '../../application/auth_form.dart';
import '../../application/session_controller.dart';
import '../auth_messages.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/email_code_step.dart';
import '../widgets/join_link_parts.dart';
import 'login_screen.dart';

/// A course link (`/courses/<id>/enroll` on the web): the course names the Admin's LMS. Signed out,
/// the visitor creates a learner account there (enrolled when the LMS's policy allows) or signs in
/// and comes back; a signed-in learner enrols through the ordinary enrol call, which finds only
/// their own LMS's courses. Staff are told the link is for learners.
class CourseEnrolScreen extends ConsumerStatefulWidget {
  const CourseEnrolScreen({required this.courseId, super.key});

  final String courseId;

  @override
  ConsumerState<CourseEnrolScreen> createState() => _CourseEnrolScreenState();
}

class _CourseEnrolScreenState extends ConsumerState<CourseEnrolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// The account was made but the LMS did not enrol it: the server's reason, shown in place of an
  /// Enrol button that would only be refused again.
  String? _notEnrolled;

  /// Set once the server is waiting for the emailed code; the details stay as they were typed.
  VerificationPending? _pending;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final step = await ref
        .read(courseJoinControllerProvider.notifier)
        .join(
          courseId: widget.courseId,
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
    if (mounted) _settle(step);
  }

  Future<void> _verify(String code) async {
    final pending = _pending;
    if (pending == null) return;
    final step = await ref
        .read(courseJoinControllerProvider.notifier)
        .verify(verificationId: pending.verificationId, code: code);
    if (mounted) _settle(step);
  }

  Future<bool> _resend() async {
    final pending = _pending;
    if (pending == null) return false;
    final renewed = await ref
        .read(courseJoinControllerProvider.notifier)
        .resend(pending.verificationId);
    if (renewed == null || !mounted) return false;
    setState(() => _pending = renewed);
    return true;
  }

  void _changeDetails() {
    ref.read(courseJoinControllerProvider.notifier).clear();
    setState(() => _pending = null);
  }

  /// Waiting for the code shows the code. Signed in and enrolled, the learner goes to the course;
  /// signed in but not enrolled, the server's reason is shown in place of an Enrol button.
  void _settle(RegistrationStep? step) {
    switch (step) {
      case RegistrationNeedsCode(:final pending):
        setState(() => _pending = pending);
      case RegistrationSignedIn(:final enrolled, :final enrolment, :final purchaseRequired):
        // Enrolled, or a paid course: either way the course's own page is next — there it opens,
        // or shows its price and the way to buy it.
        if ((enrolled ?? false) || purchaseRequired) {
          GoRouter.of(context).go(AppRoutes.learnCourse(widget.courseId));
          return;
        }
        setState(() {
          _pending = null;
          _notEnrolled = enrolment ?? context.l10n.courseLinkNotEnrolledBody;
        });
      case RegistrationAwaitingApproval() || null:
        break;
    }
  }

  Future<void> _enrol() async {
    final router = GoRouter.of(context);
    final actions = ref.read(courseActionsProvider.notifier);
    final enrolled = await actions.enroll(widget.courseId);
    if (!mounted) return;
    final failure = ref.read(courseActionsProvider).failure;
    // A paid course is bought on its page, not joined here.
    final paid = failure is ConflictFailure && failure.code == 'COURSE_PURCHASE_REQUIRED';
    if (paid) actions.clearFailure();
    if (enrolled || paid) router.go(AppRoutes.learnCourse(widget.courseId));
  }

  void _signIn() {
    // Signing in comes back here, where the learner's own enrol call takes over.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(next: AppRoutes.courseEnrol(widget.courseId)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lookup = ref.watch(courseLinkProvider(widget.courseId));
    return joinLinkLookup(
      lookup: lookup,
      notFound: () =>
          JoinLinkProblem(title: l10n.courseLinkInvalidTitle, body: l10n.courseLinkInvalidBody),
      onRetry: () => ref.invalidate(courseLinkProvider(widget.courseId)),
      data: (link) {
        final user = ref.watch(sessionControllerProvider.select((session) => session.user));
        final notEnrolled = _notEnrolled;
        if (user != null && notEnrolled != null) return _accountReady(context, user, notEnrolled);
        if (user != null && ref.watch(courseJoinControllerProvider).done) {
          // Just joined and enrolled: on the way to the course.
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (user == null) {
          if (!link.open) {
            return JoinLinkProblem(title: l10n.joinLmsClosedTitle, body: l10n.joinLmsClosedBody);
          }
          final pending = _pending;
          if (pending != null) {
            return EmailCodeStep(
              pending: pending,
              state: ref.watch(courseJoinControllerProvider),
              onVerify: _verify,
              onResend: _resend,
              onChangeDetails: _changeDetails,
            );
          }
          return _createForm(context, link);
        }
        if (user.role != UserRole.student) {
          return JoinLinkSignedIn(
            title: l10n.courseLinkStaffTitle,
            profile: user,
            body: l10n.courseLinkStaffBody,
          );
        }
        return _enrolView(context, link);
      },
    );
  }

  /// A signed-in learner: enrol with the ordinary call. A course of another LMS is not found for
  /// them (404), which is said plainly rather than as "not found".
  Widget _enrolView(BuildContext context, CourseLinkView link) {
    final l10n = context.l10n;
    final state = ref.watch(courseActionsProvider);
    final failure = state.failure;
    return AuthScaffold(
      title: link.course.title,
      subtitle: l10n.courseLinkSubtitle(link.lms.name),
      banner: failure == null
          ? null
          : AuthErrorBanner(
              title: failure is NotFoundFailure
                  ? l10n.courseLinkOtherLmsTitle
                  : l10n.enrolFailedTitle,
              detail: failure is NotFoundFailure
                  ? failure.message
                  : authFailureText(l10n, failure).detail,
            ),
      children: [
        Text(
          l10n.courseLinkEnrolBody,
          style: context.type.bodyM.copyWith(color: context.colors.muted),
        ),
        const SizedBox(height: Space.s5),
        AppButton(
          label: l10n.actionEnrol,
          size: AppButtonSize.lg,
          expand: true,
          busy: state.enrolling,
          onPressed: _enrol,
        ),
        const SizedBox(height: Space.s3),
        AppButton(
          label: l10n.actionGoHome,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: () => GoRouter.of(context).go(AppRoutes.home),
        ),
      ],
    );
  }

  /// The account exists, but the LMS's policy did not let it enrol itself.
  Widget _accountReady(BuildContext context, UserProfile user, String reason) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.courseLinkAccountReadyTitle,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(reason, style: context.type.bodyM.copyWith(color: context.colors.muted)),
        ),
        const SizedBox(height: Space.s5),
        AppButton(
          label: l10n.actionGoHome,
          expand: true,
          onPressed: () => GoRouter.of(context).go(homeFor(user.role)),
        ),
      ],
    );
  }

  Widget _createForm(BuildContext context, CourseLinkView link) {
    final l10n = context.l10n;
    final state = ref.watch(courseJoinControllerProvider);
    final failure = state.failure;
    final text = failure == null
        ? null
        : joinFailureText(l10n, failure, notFoundTitle: l10n.courseLinkInvalidTitle);
    return AuthScaffold(
      title: link.course.title,
      subtitle: l10n.courseLinkCreateBody(link.lms.name),
      banner: text == null ? null : AuthErrorBanner(title: text.title, detail: text.detail),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: l10n.fieldName,
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                errorText: state.fieldErrors['name'],
                validator: (v) => AuthValidators.name(l10n, v),
              ),
              const SizedBox(height: Space.s4),
              AppTextField(
                label: l10n.fieldEmail,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                errorText: state.fieldErrors['email'],
                validator: (v) => AuthValidators.email(l10n, v),
                inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              ),
              const SizedBox(height: Space.s4),
              AppTextField(
                label: l10n.fieldPassword,
                controller: _password,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                helperText: l10n.validationPasswordMin,
                errorText: state.fieldErrors['password'],
                validator: (v) => AuthValidators.newPassword(l10n, v),
                onSubmitted: (_) => _create(),
              ),
              const SizedBox(height: Space.s5),
              AppButton(
                label: l10n.actionCreateAndEnrol,
                size: AppButtonSize.lg,
                expand: true,
                busy: state.busy,
                onPressed: _create,
              ),
              const SizedBox(height: Space.s3),
              Text(
                l10n.registerAgreement,
                style: context.type.bodyS.copyWith(color: context.colors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.s3),
              AuthSwitchPrompt(
                prompt: l10n.registerHaveAccount,
                actionLabel: l10n.actionSignIn,
                onPressed: _signIn,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
