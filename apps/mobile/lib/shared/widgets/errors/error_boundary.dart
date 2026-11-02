import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../actions/app_button.dart';
import '../icons/app_icons.dart';

/// What a crashed route shows instead of Flutter's red error screen (§16): a calm message and
/// "Go home" — never the exception or a stack trace. Installed app-wide by [ErrorBoundary.install];
/// the error itself has already gone to the crash reporter through `FlutterError.onError`.
class ErrorBoundary extends StatelessWidget {
  const ErrorBoundary({super.key, this.onGoHome});

  final VoidCallback? onGoHome;

  /// Replaces `ErrorWidget.builder` so a build failure anywhere renders this view.
  /// [onGoHome] receives the failing widget's context.
  static void install({void Function(BuildContext context)? onGoHome}) {
    ErrorWidget.builder = (details) => Builder(
      builder: (context) =>
          ErrorBoundary(onGoHome: onGoHome == null ? null : () => onGoHome(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A crash can happen above the localizations or theme; fall back to English and the light
    // tokens so this view itself can never fail.
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        lookupAppLocalizations(const Locale('en'));
    final theme = Theme.of(context).extension<AppColors>() == null
        ? AppTheme.light()
        : Theme.of(context);
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) => Directionality(
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
          child: ColoredBox(
            color: context.colors.bg,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Space.s5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(AppIcons.error, size: 40, color: context.colors.dangerInk),
                    const SizedBox(height: Space.s4),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.errorBoundaryTitle,
                        textAlign: TextAlign.center,
                        style: context.type.titleL,
                      ),
                    ),
                    const SizedBox(height: Space.s2),
                    Text(
                      l10n.errorBoundaryBody,
                      textAlign: TextAlign.center,
                      style: context.type.bodyM.copyWith(color: context.colors.muted),
                    ),
                    if (onGoHome != null) ...[
                      const SizedBox(height: Space.s5),
                      AppButton(label: l10n.actionGoHome, onPressed: onGoHome),
                    ],
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
