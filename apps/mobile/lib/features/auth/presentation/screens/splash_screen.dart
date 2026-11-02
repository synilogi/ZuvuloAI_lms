import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/session_controller.dart';
import '../../application/session_state.dart';

/// What the app shows while the stored session is confirmed with `GET /auth/me`, and when the
/// server cannot be reached — the token is kept and Retry tries again (§6).
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // The router holds every route here until the session resolves, so the splash itself says when
    // the server could not be reached.
    if (ref.watch(sessionControllerProvider) is SessionUnavailable) {
      return Scaffold(
        body: StateLayout(
          icon: AppIcons.offline,
          title: l10n.splashOfflineTitle,
          message: l10n.splashOfflineBody,
          actionLabel: l10n.actionRetry,
          onAction: () => ref.read(sessionControllerProvider.notifier).restore(),
        ),
      );
    }
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandLogo(),
            const SizedBox(height: Space.s5),
            Semantics(
              label: l10n.loadingLabel,
              liveRegion: true,
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
