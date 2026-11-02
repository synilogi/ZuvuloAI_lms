import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/auth_scaffold.dart';
import 'instructor_signup_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Create account: who is registering. A learner joins the platform; an instructor asks to teach
/// and waits for an admin's approval (D34).
/// The role is never sent: each path's endpoint decides it.
class AccountTypeScreen extends StatelessWidget {
  const AccountTypeScreen({super.key, this.next});

  /// Where to continue once signed in — handed on, and validated, as on the sign-in screen.
  final String? next;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      brand: true,
      title: l10n.accountTypeTitle,
      subtitle: l10n.accountTypeSubtitle,
      children: [
        _Choice(
          icon: AppIcons.learning,
          title: l10n.accountTypeLearnerTitle,
          body: l10n.accountTypeLearnerBody,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => RegisterScreen(next: next))),
        ),
        const SizedBox(height: Space.s3),
        _Choice(
          icon: AppIcons.instructor,
          title: l10n.accountTypeInstructorTitle,
          body: l10n.accountTypeInstructorAction,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const InstructorSignupScreen())),
        ),
        const SizedBox(height: Space.s5),
        AuthSwitchPrompt(
          prompt: l10n.registerHaveAccount,
          actionLabel: l10n.actionSignIn,
          onPressed: () => Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute<void>(builder: (_) => LoginScreen(next: next))),
        ),
      ],
    );
  }
}

/// One way in: a card that opens its form, or — without [onTap] — only explains.
class _Choice extends StatelessWidget {
  const _Choice({required this.icon, required this.title, required this.body, this.onTap});

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      semanticLabel: '$title. $body',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, size: Sizes.iconTile + Space.s1),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.type.titleS),
                const SizedBox(height: Space.s1),
                Text(body, style: context.type.bodyS.copyWith(color: c.muted)),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: Space.s2),
            AppIcon(AppIcons.chevronRight, size: IconSizes.sm, color: c.faint),
          ],
        ],
      ),
    );
  }
}
