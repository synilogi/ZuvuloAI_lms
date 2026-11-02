import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/auth_form.dart';
import '../auth_messages.dart';
import '../widgets/auth_scaffold.dart';

/// Ask for a reset link. The confirmation is the same whether or not the address has an account —
/// the server never says (`routes/auth.ts`).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(forgotPasswordControllerProvider.notifier).sendLink(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(forgotPasswordControllerProvider);
    if (state.done) {
      return AuthScaffold(
        title: l10n.forgotConfirmationTitle,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.forgotConfirmationBody,
              style: context.type.bodyM.copyWith(color: context.colors.muted),
            ),
          ),
          const SizedBox(height: Space.s5),
          AppButton(
            label: l10n.actionBack,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }
    final failure = state.failure;
    return AuthScaffold(
      brand: true,
      title: l10n.forgotTitle,
      subtitle: l10n.forgotSubtitle,
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
                label: l10n.fieldEmail,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                errorText: state.fieldErrors['email'],
                validator: (v) => AuthValidators.email(l10n, v),
                inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Space.s5),
              AppButton(
                label: l10n.actionSendLink,
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
