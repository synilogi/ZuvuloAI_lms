import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/flavor.dart';
import '../core/theme/theme.dart';
import '../features/auth/auth.dart';
import '../features/course_purchase/course_purchase.dart' show coursePurchaseRecoveryProvider;
import '../features/profile/profile.dart';
import '../l10n/l10n.dart';
import '../shared/entitlements/entitlements.dart';
import '../shared/widgets/widgets.dart';
import 'push_scope.dart';
import 'routing/app_router.dart';
import 'session_scope.dart';

/// Product name. A brand name, not translatable copy.
const String kAppName = 'ZuviloAI';

/// Root widget: Celestial Ink themes (system light/dark), localizations and the router (§5).
class SyniastroApp extends ConsumerWidget {
  const SyniastroApp({required this.flavor, super.key});

  final Flavor flavor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nothing of one signed-in person outlives their session (§8.4).
    listenForSessionChange(ref);
    // The academy's notifications reach the phone's shade while someone is signed in (FLUTTER-028).
    listenForPush(ref);
    // A course paid for just before the app was closed opens as soon as the learner is back (§11).
    listenForPendingPurchases(ref);
    // How the app behaves is the device's own choice, kept on it (FLUTTER-017).
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp.router(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            // Both settings sit **on top of** the platform's own: motion is reduced if either
            // asks, and the preview scale multiplies the phone's text size (§19).
            disableAnimations: media.disableAnimations || settings.reducedMotion,
            textScaler: settings.textScale == 1
                ? media.textScaler
                : media.textScaler.clamp(
                    minScaleFactor: settings.textScale,
                    maxScaleFactor: settings.textScale,
                  ),
          ),
          // The page ground, beneath every route: scaffolds are translucent over it (tokens.dart).
          child: AppBackdrop(child: _SessionStarter(child: child ?? const SizedBox.shrink())),
        );
      },
    );
  }
}

/// Confirms the stored token with `GET /auth/me` once, as soon as the app is on screen (§6). The
/// router's redirect holds everything on the splash until it answers.
class _SessionStarter extends ConsumerStatefulWidget {
  const _SessionStarter({required this.child});

  final Widget child;

  @override
  ConsumerState<_SessionStarter> createState() => _SessionStarterState();
}

class _SessionStarterState extends ConsumerState<_SessionStarter> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionControllerProvider.notifier).restore();
    });
    // Coming back to the app re-reads the profile (a permission may have been taken away) and the
    // academy's plan, each throttled to five minutes (§7, §9.2).
    _lifecycle = AppLifecycleListener(
      onResume: () {
        unawaited(ref.read(sessionControllerProvider.notifier).refreshProfileIfStale());
        unawaited(ref.read(academyPlanProvider.notifier).refreshIfStale());
        // A course purchase left open on this device: the server may have the payment by now.
        unawaited(ref.read(coursePurchaseRecoveryProvider).run());
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Asks the server about course purchases left open on this device whenever someone signs in —
/// including the session restored at start-up. Called from the root's build, outside any build work.
void listenForPendingPurchases(WidgetRef ref) {
  ref.listen<String?>(currentUserProvider.select((profile) => profile?.id), (previous, next) {
    if (next == null || previous == next) return;
    unawaited(ref.read(coursePurchaseRecoveryProvider).run());
  });
}
