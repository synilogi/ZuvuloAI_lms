import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/auth_form.dart';
import '../auth_messages.dart';
import '../widgets/auth_scaffold.dart';

/// Set a new password from a reset link. The token comes from the link and is never logged or
/// stored; the server decides whether it is still usable.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({required this.token, super.key});

  final String token;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(resetPasswordControllerProvider.notifier)
        .setPassword(token: widget.token, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(resetPasswordControllerProvider);
    final validity = ref.watch(resetTokenValidProvider(widget.token));

    if (state.done) {
      return AuthScaffold(
        title: l10n.resetDoneTitle,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.resetDoneBody,
              style: context.type.bodyM.copyWith(color: context.colors.muted),
            ),
          ),
          const SizedBox(height: Space.s5),
          AppButton(
            label: l10n.actionSignIn,
            expand: true,
            // Straight to the sign-in form. A reset link usually opens the app on this screen, with
            // nothing beneath it to pop back to (LIVE E2E AUTH-023).
            onPressed: () => GoRouter.of(context).go(AppRoutes.login),
          ),
        ],
      );
    }

    return validity.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => _invalid(context),
      data: (result) => switch (result) {
        Ok(value: false) => _invalid(context),
        Err(:final failure) => AuthScaffold(
          title: l10n.stateErrorTitle,
          children: [
            AuthErrorBanner(
              title: authFailureText(l10n, failure).title,
              detail: authFailureText(l10n, failure).detail,
            ),
            const SizedBox(height: Space.s4),
            AppButton(
              label: l10n.actionRetry,
              expand: true,
              onPressed: () => ref.invalidate(resetTokenValidProvider(widget.token)),
            ),
          ],
        ),
        Ok() => _form(context, state),
      },
    );
  }

  Widget _invalid(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.resetInvalidTitle,
      children: [
        Text(
          l10n.resetInvalidBody,
          style: context.type.bodyM.copyWith(color: context.colors.muted),
        ),
        const SizedBox(height: Space.s5),
        AppButton(
          label: l10n.actionBack,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: () => Navigator.of(context).canPop()
              ? Navigator.of(context).popUntil((route) => route.isFirst)
              : GoRouter.of(context).go(AppRoutes.welcome),
        ),
      ],
    );
  }

  Widget _form(BuildContext context, AuthFormState state) {
    final l10n = context.l10n;
    final failure = state.failure;
    return AuthScaffold(
      brand: true,
      title: l10n.resetTitle,
      subtitle: l10n.resetSubtitle,
      banner: failure == null
          ? null
          : AuthErrorBanner(
              title: authFailureText(l10n, failure).title,
              detail: authFailureText(l10n, failure).detail,
            ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: l10n.fieldNewPassword,
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
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Space.s5),
              AppButton(
                label: l10n.actionSetPassword,
                size: AppButtonSize.lg,
                expand: true,
                busy: state.busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
