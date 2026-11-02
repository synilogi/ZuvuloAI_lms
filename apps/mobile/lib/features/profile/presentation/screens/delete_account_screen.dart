import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/auth.dart';

/// `/profile/delete-account` — a learner deletes their own account (Google Play's account-deletion
/// policy; `POST /auth/delete-account`). What goes and what stays is said before anything is asked,
/// and the password is asked in the confirmation, so the server decides who may. Staff accounts are
/// closed by their academy and never reach this page (see `ProfileScreen`). A shell body.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final l10n = context.l10n;
    _password.clear();
    await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title: l10n.deleteAccountConfirmTitle,
        message: l10n.deleteAccountConfirmBody,
        confirmLabel: l10n.deleteAccountAction,
        acknowledgementLabel: l10n.deleteAccountAcknowledge,
        destructive: true,
        body: AppTextField(
          label: l10n.fieldPassword,
          controller: _password,
          obscure: true,
          autofillHints: const [AutofillHints.password],
        ),
        onConfirm: () async {
          if (_password.text.isEmpty) return l10n.validationPasswordRequired;
          // On success the session is cleared and the router leaves for sign-in, which says why.
          final result = await ref
              .read(sessionControllerProvider.notifier)
              .deleteAccount(_password.text);
          return switch (result) {
            Ok() => null,
            Err(:final failure) => failure.message,
          };
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    Widget point(String text, {required bool removed}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: AppIcon(
              removed ? AppIcons.delete : AppIcons.info,
              size: IconSizes.sm,
              color: removed ? c.dangerInk : c.muted,
            ),
          ),
          const SizedBox(width: Space.s2),
          Expanded(child: Text(text, style: context.type.bodyM)),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.s4, Space.s4, Space.s4, Space.s6),
      children: [
        Text(l10n.deleteAccountTitle, style: context.type.titleM),
        const SizedBox(height: Space.s2),
        Text(l10n.deleteAccountIntro, style: context.type.bodyM.copyWith(color: c.muted)),
        const SizedBox(height: Space.sectionGap),
        SectionHeader(title: l10n.deleteAccountRemovedTitle),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              point(l10n.deleteAccountRemovedIdentity, removed: true),
              point(l10n.deleteAccountRemovedPersonal, removed: true),
              point(l10n.deleteAccountRemovedDevice, removed: true),
            ],
          ),
        ),
        const SizedBox(height: Space.sectionGap),
        SectionHeader(title: l10n.deleteAccountKeptTitle),
        AppCard(child: point(l10n.deleteAccountKeptRecords, removed: false)),
        const SizedBox(height: Space.s3),
        Text(l10n.deleteAccountWeb, style: context.type.bodyS.copyWith(color: c.muted)),
        const SizedBox(height: Space.sectionGap),
        AppButton(
          label: l10n.deleteAccountAction,
          variant: AppButtonVariant.destructive,
          expand: true,
          onPressed: _confirm,
        ),
      ],
    );
  }
}
