import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/redirect.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/auth_form.dart';
import '../../application/session_controller.dart';
import '../auth_messages.dart';
import '../widgets/auth_scaffold.dart';
import 'account_type_screen.dart';
import 'forgot_password_screen.dart';

/// Sign in. A success moves the session on; the router (FLUTTER-005) decides where to land —
/// unless a validated [next] says where the person was going (§5.1).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.message, this.next});

  /// Why the person is here ("Your session ended. Sign in again.").
  final String? message;

  /// Where to continue after signing in, as the redirect recorded it. It is checked against the
  /// app's own route table and the person's access before it is followed — never an open
  /// redirect.
  final String? next;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final router = GoRouter.of(context);
    final signedIn = await ref
        .read(loginControllerProvider.notifier)
        .signIn(email: _email.text, password: _password.text);
    if (!signedIn || !mounted) return;
    // This screen may have been pushed over the welcome screen; leave that stack first.
    Navigator.of(context).popUntil((route) => route.isFirst);
    continueAfterSignIn(
      router: router,
      profile: ref.read(sessionControllerProvider).user,
      next: widget.next,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(loginControllerProvider);
    final failure = state.failure;
    return AuthScaffold(
      brand: true,
      title: l10n.loginTitle,
      subtitle: widget.message ?? l10n.loginSubtitle,
      banner: failure == null
          ? null
          : Builder(
              builder: (context) {
                final text = authFailureText(l10n, failure);
                // A suspended or closed LMS, and an instructor awaiting or refused approval (D34),
                // keep their own title; anything else is a failed sign-in.
                return AuthErrorBanner(
                  title: failure is AccountClosedFailure || failure is InstructorApprovalFailure
                      ? text.title
                      : l10n.loginFailedTitle,
                  detail: text.detail,
                );
              },
            ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: l10n.fieldEmail,
                hintText: l10n.fieldEmailHint,
                prefixIcon: AppIcons.email,
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
                hintText: l10n.fieldPasswordHint,
                prefixIcon: AppIcons.lock,
                controller: _password,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                errorText: state.fieldErrors['password'],
                validator: (v) => AuthValidators.loginPassword(l10n, v),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Space.s1),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen())),
                  child: Text(l10n.actionForgotPassword),
                ),
              ),
              const SizedBox(height: Space.s3),
              AppButton(
                label: l10n.actionSignIn,
                size: AppButtonSize.lg,
                expand: true,
                busy: state.busy,
                onPressed: _submit,
              ),
              const SizedBox(height: Space.s5),
              AuthSwitchPrompt(
                prompt: l10n.loginNoAccount,
                actionLabel: l10n.actionCreateAccount,
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => AccountTypeScreen(next: widget.next)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
