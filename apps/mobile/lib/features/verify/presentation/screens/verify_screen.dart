import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/verify_providers.dart';
import '../widgets/verification_card.dart';

/// `/verify` — where a credential ID is entered. The ID is sent exactly as typed; the server
/// decides whether it names a certificate (§18).
class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    GoRouter.of(context).go(AppRoutes.verifyCredential(CredentialId.normalise(_controller.text)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return UpPopScope(
      fallback: AppRoutes.welcome,
      child: Scaffold(
        appBar: CommonAppBar(
          leading: upButton(context, fallback: AppRoutes.welcome),
          title: l10n.verifyTitle,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.s4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Space.formMaxWidth),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.verifyIntro, style: context.type.bodyM),
                    const SizedBox(height: Space.s4),
                    AppTextField(
                      label: l10n.verifyFieldLabel,
                      hintText: l10n.verifyFieldHint,
                      controller: _controller,
                      required: true,
                      maxLength: CredentialId.maxLength,
                      textInputAction: TextInputAction.search,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                      onSubmitted: (_) => _submit(),
                      validator: (value) {
                        final raw = value ?? '';
                        if (CredentialId.normalise(raw).isEmpty) return l10n.verifyRequired;
                        if (!CredentialId.isWellFormed(raw)) return l10n.verifyTooLong;
                        return null;
                      },
                    ),
                    const SizedBox(height: Space.s4),
                    AppButton(
                      label: l10n.actionVerify,
                      size: AppButtonSize.lg,
                      expand: true,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `/verify/:credentialId` — the answer. A link from outside the app lands straight here.
class VerifyResultScreen extends ConsumerWidget {
  const VerifyResultScreen({required this.credentialId, super.key});

  final String credentialId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final result = ref.watch(verificationProvider(credentialId));
    return UpPopScope(
      fallback: AppRoutes.welcome,
      child: Scaffold(
        appBar: CommonAppBar(
          leading: upButton(context, fallback: AppRoutes.welcome),
          title: l10n.verifyTitle,
        ),
        body: SafeArea(
          child: AsyncView(
            value: result,
            onRetry: () => ref.invalidate(verificationProvider(credentialId)),
            skeleton: DelayedLoading(
              skeleton: StateLayout(icon: AppIcons.certificate, title: l10n.verifyCheckingTitle),
            ),
            notFound: StateLayout(
              icon: AppIcons.notFound,
              title: l10n.verifyNotFoundTitle,
              message: l10n.verifyNotFoundBody,
              actionLabel: l10n.actionVerifyAnother,
              onAction: () => GoRouter.of(context).go(AppRoutes.verify),
            ),
            data: (value) => VerificationCard(result: value),
          ),
        ),
      ),
    );
  }
}
