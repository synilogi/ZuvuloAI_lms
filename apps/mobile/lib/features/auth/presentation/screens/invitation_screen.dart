import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/redirect.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/auth_form.dart';
import '../../application/session_controller.dart';
import '../auth_messages.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/email_code_step.dart';
import '../widgets/join_link_parts.dart';

/// A learner invitation (`/invite/<token>`): join the Admin's LMS it names, with a new account or
/// the one the learner already has there. The token is the credential — it names the LMS and the
/// role on the server, so nothing here chooses either. Never logged (§18).
class InvitationScreen extends ConsumerStatefulWidget {
  const InvitationScreen({required this.token, super.key});

  final String token;

  @override
  ConsumerState<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends ConsumerState<InvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// "I already have an account": sign in with the invitation instead of creating one.
  bool _signingIn = false;

  /// Set once the server is waiting for the code emailed for a new account; the details stay as
  /// they were typed.
  VerificationPending? _pending;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _switchMode() {
    ref.read(invitationControllerProvider.notifier).clear();
    _password.clear();
    setState(() => _signingIn = !_signingIn);
  }

  Future<void> _submit(InvitationView invitation) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final controller = ref.read(invitationControllerProvider.notifier);
    // A bound invitation is accepted only by its own address, so that is the one sent.
    final email = invitation.email ?? _email.text;
    if (_signingIn) {
      final joined = await controller.signIn(
        token: widget.token,
        email: email,
        password: _password.text,
      );
      if (joined && mounted) _goHome();
      return;
    }
    final step = await controller.register(
      token: widget.token,
      name: _name.text,
      email: email,
      password: _password.text,
    );
    if (mounted) _settle(step);
  }

  Future<void> _verify(String code) async {
    final pending = _pending;
    if (pending == null) return;
    final step = await ref
        .read(invitationControllerProvider.notifier)
        .verify(verificationId: pending.verificationId, code: code);
    if (mounted) _settle(step);
  }

  Future<bool> _resend() async {
    final pending = _pending;
    if (pending == null) return false;
    final renewed = await ref
        .read(invitationControllerProvider.notifier)
        .resend(pending.verificationId);
    if (renewed == null || !mounted) return false;
    setState(() => _pending = renewed);
    return true;
  }

  void _changeDetails() {
    ref.read(invitationControllerProvider.notifier).clear();
    setState(() => _pending = null);
  }

  void _settle(RegistrationStep? step) {
    switch (step) {
      case RegistrationNeedsCode(:final pending):
        setState(() => _pending = pending);
      case RegistrationSignedIn():
        _goHome();
      case RegistrationAwaitingApproval() || null:
        break;
    }
  }

  void _goHome() {
    final profile = ref.read(sessionControllerProvider).user;
    if (profile == null) return;
    final router = GoRouter.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    // This screen is public, so the router leaves a new learner on it; their home is where they go.
    router.go(destinationAfterSignIn(profile: profile));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lookup = ref.watch(invitationProvider(widget.token));
    return joinLinkLookup(
      lookup: lookup,
      notFound: () => JoinLinkProblem(title: l10n.inviteInvalidTitle, body: l10n.inviteInvalidBody),
      onRetry: () => ref.invalidate(invitationProvider(widget.token)),
      data: (invitation) {
        final form = ref.watch(invitationControllerProvider);
        final user = ref.watch(sessionControllerProvider.select((session) => session.user));
        // Just joined: the session is theirs now and the screen is on its way home.
        if (user != null && form.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final title = l10n.joinLmsTitle(invitation.lms.name);
        if (user != null) return JoinLinkSignedIn(title: title, profile: user);
        if (!invitation.open) {
          return JoinLinkProblem(title: l10n.joinLmsClosedTitle, body: l10n.joinLmsClosedBody);
        }
        final pending = _pending;
        if (pending != null) {
          return EmailCodeStep(
            pending: pending,
            state: form,
            onVerify: _verify,
            onResend: _resend,
            onChangeDetails: _changeDetails,
          );
        }
        return _form(context, invitation, form);
      },
    );
  }

  Widget _form(BuildContext context, InvitationView invitation, AuthFormState state) {
    final l10n = context.l10n;
    final failure = state.failure;
    final boundEmail = invitation.email;
    final text = failure == null
        ? null
        : joinFailureText(
            l10n,
            failure,
            notFoundTitle: l10n.inviteInvalidTitle,
            signingIn: _signingIn,
          );
    return AuthScaffold(
      title: l10n.joinLmsTitle(invitation.lms.name),
      subtitle: _signingIn
          ? l10n.inviteSignInSubtitle(invitation.lms.name)
          : l10n.inviteSubtitle(invitation.lms.name),
      banner: text == null ? null : AuthErrorBanner(title: text.title, detail: text.detail),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_signingIn) ...[
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
              ],
              AppTextField(
                label: l10n.fieldEmail,
                // The Admin bound this invitation to one address: it is shown, not chosen.
                controller: boundEmail == null ? _email : null,
                initialValue: boundEmail,
                enabled: boundEmail == null,
                helperText: boundEmail == null ? null : l10n.inviteEmailLocked,
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
                autofillHints: [_signingIn ? AutofillHints.password : AutofillHints.newPassword],
                helperText: _signingIn ? null : l10n.validationPasswordMin,
                errorText: state.fieldErrors['password'],
                validator: (v) => _signingIn
                    ? AuthValidators.loginPassword(l10n, v)
                    : AuthValidators.newPassword(l10n, v),
                onSubmitted: (_) => _submit(invitation),
              ),
              const SizedBox(height: Space.s5),
              AppButton(
                label: _signingIn ? l10n.actionSignInAndJoin : l10n.actionCreateAccount,
                size: AppButtonSize.lg,
                expand: true,
                busy: state.busy,
                onPressed: () => _submit(invitation),
              ),
              if (!_signingIn) ...[
                const SizedBox(height: Space.s3),
                Text(
                  l10n.registerAgreement,
                  style: context.type.bodyS.copyWith(color: context.colors.muted),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: Space.s3),
              AuthSwitchPrompt(
                prompt: _signingIn ? l10n.inviteNoAccount : l10n.registerHaveAccount,
                actionLabel: _signingIn ? l10n.actionCreateAccount : l10n.actionSignIn,
                onPressed: _switchMode,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
