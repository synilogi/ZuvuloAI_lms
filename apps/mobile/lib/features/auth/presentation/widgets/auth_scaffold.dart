import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

/// The shared frame for the auth forms, on the aurora backdrop: a back arrow, a title, a subtitle,
/// and a comfortable column that scrolls at any text size.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.children,
    super.key,
    this.subtitle,
    this.banner,
    this.brand = false,
  });

  final String title;
  final String? subtitle;

  /// Whether the ZuviloAI mark sits above the title: on for the app's own doors (sign in, create
  /// an account, reset a password), off where the screen is about an academy the person is joining.
  final bool brand;

  /// A refusal shown above the form (the server's message).
  final Widget? banner;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // The doors to the app sit on the light, colourful aurora rather than the plain page.
    return AuroraBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CommonAppBar(),
        body: SafeArea(
          // Top-aligned: the form does not jump when the keyboard opens, and the title sits where
          // the eye lands after the back arrow.
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(Space.s5, Space.s4, Space.s5, Space.s6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Space.authMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (brand) ...[
                      const Align(alignment: AlignmentDirectional.centerStart, child: BrandMark()),
                      const SizedBox(height: Space.s4),
                    ],
                    Semantics(header: true, child: Text(title, style: context.type.displayL)),
                    if (subtitle != null) ...[
                      const SizedBox(height: Space.s2),
                      Text(
                        subtitle!,
                        style: context.type.bodyL.copyWith(color: context.colors.muted),
                      ),
                    ],
                    if (banner != null) ...[const SizedBox(height: Space.s5), banner!],
                    const SizedBox(height: Space.s6),
                    ...children,
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

/// A refusal banner: the app's title with the server's own message beneath it.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({required this.title, super.key, this.detail});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Space.s4),
        decoration: BoxDecoration(
          color: c.dangerSoft,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(AppIcons.warning, color: c.dangerInk),
            const SizedBox(width: Space.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.type.titleS.copyWith(color: c.dangerInk)),
                  if (detail != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(detail!, style: context.type.bodyS.copyWith(color: c.dangerInk)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The footer line that switches between signing in and registering: "New here? Create account".
class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    required this.prompt,
    required this.actionLabel,
    required this.onPressed,
    super.key,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: context.type.bodyM.copyWith(color: context.colors.muted)),
        TextButton(onPressed: onPressed, child: Text(actionLabel)),
      ],
    );
  }
}
