import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/auth_form.dart';
import '../auth_messages.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/email_code_step.dart';
import '../widgets/join_link_parts.dart';
import 'login_screen.dart';

/// The workspace a request to teach goes to when no link names one. The server's
/// `/public/academies/:slug` answers for the platform's one workspace only, whose slug is `default`
/// unless the server's `DEFAULT_TENANT_SLUG` says otherwise; `--dart-define=WORKSPACE_SLUG` matches
/// it.
const _workspaceSlug = String.fromEnvironment('WORKSPACE_SLUG', defaultValue: 'default');

/// Register as an instructor (D34). The person asks to teach in the workspace a link names
/// (`/join/<address>/teach`, or its join link) or, without a link, [_workspaceSlug], then enters the
/// 6-digit code emailed to them, and an admin approves or rejects them. Nobody is signed in: the
/// account waits for approval, which the server enforces at sign-in and on every request.
class InstructorSignupScreen extends ConsumerStatefulWidget {
  const InstructorSignupScreen({super.key, this.workspace});

  /// The LMS address from a join link, if the screen was opened from one.
  final String? workspace;

  @override
  ConsumerState<InstructorSignupScreen> createState() => _InstructorSignupScreenState();
}

class _InstructorSignupScreenState extends ConsumerState<InstructorSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _title = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  /// Set once the server is waiting for the emailed code; the details stay as they were typed.
  VerificationPending? _pending;

  /// The request reached the LMS admin: nothing is left to do here but sign in later.
  bool _awaitingApproval = false;

  @override
  void dispose() {
    for (final c in [_name, _title, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(String workspace) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final step = await ref
        .read(instructorSignupControllerProvider.notifier)
        .register(
          workspace: workspace,
          name: _name.text,
          email: _email.text,
          password: _password.text,
          title: _title.text,
        );
    if (mounted) _settle(step);
  }

  Future<void> _verify(String code) async {
    final pending = _pending;
    if (pending == null) return;
    final step = await ref
        .read(instructorSignupControllerProvider.notifier)
        .verify(verificationId: pending.verificationId, code: code);
    if (mounted) _settle(step);
  }

  Future<bool> _resend() async {
    final pending = _pending;
    if (pending == null) return false;
    final renewed = await ref
        .read(instructorSignupControllerProvider.notifier)
        .resend(pending.verificationId);
    if (renewed == null || !mounted) return false;
    setState(() => _pending = renewed);
    return true;
  }

  void _changeDetails() {
    ref.read(instructorSignupControllerProvider.notifier).clear();
    setState(() => _pending = null);
  }

  void _settle(RegistrationStep? step) {
    switch (step) {
      case RegistrationNeedsCode(:final pending):
        setState(() => _pending = pending);
      case RegistrationAwaitingApproval():
        setState(() {
          _pending = null;
          _awaitingApproval = true;
        });
      // An instructor is never signed in by registering; nothing else to do.
      case RegistrationSignedIn() || null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_awaitingApproval) return InstructorPendingScreen(email: _email.text.trim());
    final pending = _pending;
    if (pending != null) {
      return EmailCodeStep(
        pending: pending,
        state: ref.watch(instructorSignupControllerProvider),
        onVerify: _verify,
        onResend: _resend,
        onChangeDetails: _changeDetails,
      );
    }
    final workspace = widget.workspace ?? _workspaceSlug;
    final notFound = JoinLinkProblem(
      title: l10n.registerWorkspaceNotFound,
      body: l10n.joinLinkNotRecognised,
    );
    if (AuthValidators.workspace(l10n, workspace) != null) return notFound;
    return joinLinkLookup(
      lookup: ref.watch(lmsJoinPageProvider(workspace)),
      notFound: () => notFound,
      onRetry: () => ref.invalidate(lmsJoinPageProvider(workspace)),
      data: (page) => page.open
          ? _form(context, page)
          : JoinLinkProblem(title: l10n.joinLmsClosedTitle, body: l10n.joinLmsClosedBody),
    );
  }

  Widget _form(BuildContext context, LmsJoinPage page) {
    final l10n = context.l10n;
    final state = ref.watch(instructorSignupControllerProvider);
    final failure = state.failure;
    final text = failure == null ? null : authFailureText(l10n, failure);
    return AuthScaffold(
      title: l10n.instructorSignupJoinTitle(page.name),
      subtitle: l10n.instructorSignupSubtitle,
      banner: text == null
          ? null
          : AuthErrorBanner(
              title: text.title == l10n.stateErrorTitle
                  ? l10n.instructorSignupFailedTitle
                  : text.title,
              detail: text.detail,
            ),
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
                label: l10n.fieldInstructorTitle,
                controller: _title,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                helperText: l10n.fieldInstructorTitleHelp,
                errorText: state.fieldErrors['title'],
                maxLength: 120,
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
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                helperText: l10n.validationPasswordMin,
                errorText: state.fieldErrors['password'],
                validator: (v) => AuthValidators.newPassword(l10n, v),
              ),
              const SizedBox(height: Space.s4),
              AppTextField(
                label: l10n.fieldConfirmPassword,
                controller: _confirm,
                obscure: true,
                textInputAction: TextInputAction.done,
                validator: (v) => AuthValidators.confirmPassword(l10n, v, _password.text),
                onSubmitted: (_) => _submit(page.slug),
              ),
              const SizedBox(height: Space.s5),
              AppButton(
                label: l10n.instructorSignupAction,
                size: AppButtonSize.lg,
                expand: true,
                busy: state.busy,
                onPressed: () => _submit(page.slug),
              ),
              const SizedBox(height: Space.s3),
              Text(
                l10n.registerAgreement,
                style: context.type.bodyS.copyWith(color: context.colors.muted),
                textAlign: TextAlign.center,
              ),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => GoRouter.of(context).push(AppRoutes.terms),
                    child: Text(l10n.legalTermsTitle),
                  ),
                  TextButton(
                    onPressed: () => GoRouter.of(context).push(AppRoutes.privacy),
                    child: Text(l10n.legalPrivacyTitle),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// After registering as an instructor: what happens next, and the way to sign in once approved. The
/// person is not signed in — sign-in itself says whether the approval has come.
class InstructorPendingScreen extends StatelessWidget {
  const InstructorPendingScreen({required this.email, super.key});

  final String email;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return AuthScaffold(
      title: l10n.instructorPendingScreenTitle,
      children: [
        const Center(child: ToneMark(icon: AppIcons.success)),
        const SizedBox(height: Space.s4),
        Semantics(
          liveRegion: true,
          child: Text(
            l10n.instructorPendingHeading,
            style: context.type.titleM,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: Space.s3),
        Text(l10n.instructorPendingBody, style: context.type.bodyM, textAlign: TextAlign.center),
        const SizedBox(height: Space.s3),
        Text(
          l10n.instructorPendingNext,
          style: context.type.bodyS.copyWith(color: c.muted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.s2),
        Text(
          email,
          style: context.type.bodyS.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.s6),
        AppButton(
          label: l10n.actionSignIn,
          size: AppButtonSize.lg,
          expand: true,
          // Opened from a link, there is nothing beneath this screen to replace: the router's own
          // sign-in takes over.
          onPressed: () => Navigator.of(context).canPop()
              ? Navigator.of(
                  context,
                ).pushReplacement(MaterialPageRoute<void>(builder: (_) => const LoginScreen()))
              : GoRouter.of(context).go(AppRoutes.login),
        ),
      ],
    );
  }
}
