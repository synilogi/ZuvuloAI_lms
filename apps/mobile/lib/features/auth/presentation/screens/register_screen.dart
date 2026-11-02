import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app.dart' show kAppName;
import '../../../../app/routing/redirect.dart';
import '../../../../app/routing/routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/auth_form.dart';
import '../../application/session_controller.dart';
import '../auth_messages.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/email_code_step.dart';
import '../widgets/join_link_parts.dart';
import 'login_screen.dart';

/// Create a learner account. Opened from a join link (`/join/<address>`, [workspace]), the screen
/// names what it read from the server. Opened without one, it shows the form straight away under
/// the product's name and sends no address: the server places every learner in the platform's one
/// workspace. Either way it asks only for the learner's own details, then for the 6-digit code
/// emailed to them. The role is never sent: public registration always creates a learner.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.next, this.workspace});

  /// The LMS address from a join link, if the screen was opened from one.
  final String? workspace;

  /// Where to continue once the account exists — validated, as on the sign-in screen.
  final String? next;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// Set once the server is waiting for the emailed code; the details stay as they were typed.
  VerificationPending? _pending;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(String workspace) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final step = await ref
        .read(registerControllerProvider.notifier)
        .register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          workspace: workspace,
        );
    if (mounted) _settle(step);
  }

  Future<void> _verify(String code) async {
    final pending = _pending;
    if (pending == null) return;
    final step = await ref
        .read(registerControllerProvider.notifier)
        .verify(verificationId: pending.verificationId, code: code);
    if (mounted) _settle(step);
  }

  Future<bool> _resend() async {
    final pending = _pending;
    if (pending == null) return false;
    final renewed = await ref
        .read(registerControllerProvider.notifier)
        .resend(pending.verificationId);
    if (renewed == null || !mounted) return false;
    setState(() => _pending = renewed);
    return true;
  }

  void _changeDetails() {
    ref.read(registerControllerProvider.notifier).clear();
    setState(() => _pending = null);
  }

  /// Waiting for the code shows the code; signed in, the learner goes on.
  void _settle(RegistrationStep? step) {
    switch (step) {
      case RegistrationNeedsCode(:final pending):
        setState(() => _pending = pending);
      case RegistrationSignedIn():
        final router = GoRouter.of(context);
        Navigator.of(context).popUntil((route) => route.isFirst);
        continueAfterSignIn(
          router: router,
          profile: ref.read(sessionControllerProvider).user,
          next: widget.next,
        );
      case RegistrationAwaitingApproval() || null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pending = _pending;
    if (pending != null) {
      return EmailCodeStep(
        pending: pending,
        state: ref.watch(registerControllerProvider),
        onVerify: _verify,
        onResend: _resend,
        onChangeDetails: _changeDetails,
      );
    }
    // Without a join link there is nothing to look up: the empty address is left out of the request.
    final workspace = widget.workspace;
    if (workspace == null) {
      return _form(context, const LmsJoinPage(name: kAppName, slug: '', open: true));
    }
    final notFound = JoinLinkProblem(
      title: l10n.registerWorkspaceNotFound,
      body: l10n.joinLinkNotRecognised,
    );
    // An address the server could never have issued is not worth asking about.
    if (AuthValidators.workspace(l10n, workspace) != null) return notFound;
    return joinLinkLookup(
      lookup: ref.watch(lmsJoinPageProvider(workspace)),
      notFound: () => notFound,
      onRetry: () => ref.invalidate(lmsJoinPageProvider(workspace)),
      data: (page) => !page.open
          ? JoinLinkProblem(title: l10n.joinLmsClosedTitle, body: l10n.joinLmsClosedBody)
          // Learners join this LMS by invitation only: its join link takes nobody.
          : page.invitationOnly
          ? JoinLinkProblem(title: l10n.invitationRequiredTitle, body: l10n.invitationRequiredBody)
          : _form(context, page),
    );
  }

  void _openSignIn() => Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute<void>(builder: (_) => LoginScreen(next: widget.next)));

  /// The learner's own details, under the name [page] gives; its slug is what the request sends.
  Widget _form(BuildContext context, LmsJoinPage page) {
    final l10n = context.l10n;
    final state = ref.watch(registerControllerProvider);
    final failure = state.failure;
    return AuthScaffold(
      title: l10n.joinLmsTitle(page.name),
      subtitle: l10n.joinLmsSubtitle(page.name),
      banner: failure == null
          ? null
          : AuthErrorBanner(
              // A specific reason (LMS full, address not found, LMS closed) keeps its own title.
              title: authFailureText(l10n, failure).title == l10n.stateErrorTitle
                  ? l10n.registerFailedTitle
                  : authFailureText(l10n, failure).title,
              detail: authFailureText(l10n, failure).detail,
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
                onSubmitted: (_) => _submit(page.slug),
              ),
              const SizedBox(height: Space.s5),
              AppButton(
                label: l10n.actionCreateAccount,
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
              const SizedBox(height: Space.s3),
              AuthSwitchPrompt(
                prompt: l10n.registerHaveAccount,
                actionLabel: l10n.actionSignIn,
                onPressed: _openSignIn,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
