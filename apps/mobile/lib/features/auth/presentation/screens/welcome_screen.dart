import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import 'account_type_screen.dart';
import 'login_screen.dart';

/// The signed-out entry point: what the app is, then sign in, create an account, or use the
/// public side — the catalogue, certificate verification and the help centre (§2.2).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    this.next,
    this.onBrowseCourses,
    this.onVerifyCertificate,
    this.onOpenHelp,
  });

  /// Where the person was going when the redirect brought them here (a protected link opened while
  /// signed out). Handed to sign-in and registration, which validate it before following it —
  /// without it, signing in from here dropped the link and landed on home (LIVE E2E LINK-003).
  final String? next;

  final VoidCallback? onBrowseCourses;
  final VoidCallback? onVerifyCertificate;
  final VoidCallback? onOpenHelp;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final links = <(String, IconData, VoidCallback)>[
      if (onBrowseCourses case final open?) (l10n.actionBrowseCourses, AppIcons.explore, open),
      if (onVerifyCertificate case final open?)
        (l10n.actionVerifyCertificate, AppIcons.certificate, open),
      if (onOpenHelp case final open?) (l10n.actionHelpCentre, AppIcons.help, open),
    ];
    return AuroraBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Space.s5),
              child: ConstrainedBox(
                // At least a screen tall, so the identity sits high and the actions sit low; taller
                // when the text is large, and then it scrolls.
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: Space.authMaxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: Space.s4),
                          const _WelcomeArt(),
                          const SizedBox(height: Space.s6),
                          Semantics(
                            header: true,
                            child: Text(
                              l10n.appTagline,
                              textAlign: TextAlign.center,
                              style: context.type.displayL,
                            ),
                          ),
                          const SizedBox(height: Space.s3),
                          Text(
                            l10n.welcomeIntro,
                            textAlign: TextAlign.center,
                            style: context.type.bodyM.copyWith(color: context.colors.muted),
                          ),
                          const Spacer(),
                          const SizedBox(height: Space.s5),
                          AppButton(
                            label: l10n.actionSignIn,
                            size: AppButtonSize.lg,
                            expand: true,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => LoginScreen(next: next)),
                            ),
                          ),
                          const SizedBox(height: Space.s3),
                          AppButton(
                            label: l10n.actionCreateAccount,
                            variant: AppButtonVariant.secondary,
                            size: AppButtonSize.lg,
                            expand: true,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => AccountTypeScreen(next: next),
                              ),
                            ),
                          ),
                          if (links.isNotEmpty) ...[
                            const SizedBox(height: Space.s5),
                            const AppDivider(),
                            const SizedBox(height: Space.s3),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final (label, icon, open) in links)
                                  Expanded(
                                    child: _PublicLink(label: label, icon: icon, onTap: open),
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: Space.s4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One of the signed-out shortcuts: an icon over its label, one tap target.
class _PublicLink extends StatelessWidget {
  const _PublicLink({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.s1, vertical: Space.s2),
          child: Column(
            children: [
              IconTile(icon: icon, size: Sizes.iconTile + Space.s2),
              const SizedBox(height: Space.s2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: context.type.bodyS.copyWith(color: c.accentInk, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The onboarding illustration: the brand's constellation on a soft accent panel, with what the
/// app holds — courses, live classes, certificates — orbiting it.
class _WelcomeArt extends StatelessWidget {
  const _WelcomeArt();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1.1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.xxl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.accentSoft, c.surface2],
            ),
          ),
          child: Builder(
            builder: (context) {
              // The panel spans the column (screen less its gutters, at most the auth width); it
              // sits inside an IntrinsicHeight, so it is sized from the screen, not laid out.
              final width = (MediaQuery.sizeOf(context).width - Space.s5 * 2).clamp(
                0.0,
                Space.authMaxWidth,
              );
              final side = width / 1.1;
              Widget orbit(IconData icon, Tone tone, Alignment at) => Align(
                alignment: at,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(Radii.lg),
                    boxShadow: context.shadows.e2,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Space.s2),
                    child: IconTile(icon: icon, tone: tone),
                  ),
                ),
              );
              return Stack(
                children: [
                  Center(child: ConstellationArt(size: side * 0.62)),
                  Center(
                    child: Container(
                      width: side * 0.42,
                      height: side * 0.42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: c.surface),
                      child: BrandMark(size: side * 0.3),
                    ),
                  ),
                  orbit(AppIcons.courses, Tone.accent, const Alignment(-0.78, -0.7)),
                  orbit(AppIcons.live, Tone.info, const Alignment(0.8, -0.35)),
                  orbit(AppIcons.certificate, Tone.warn, const Alignment(-0.6, 0.78)),
                  orbit(AppIcons.rank, Tone.accent, const Alignment(0.7, 0.72)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
