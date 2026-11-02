import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/capabilities.dart';
import '../../core/links/deep_link.dart';
import '../../features/auth/auth.dart';
import '../../shared/entitlements/dto/entitlements.dart';
import 'route_access.dart';
import 'routes.dart';

/// The router's single redirect (§5.1), as a pure function so the whole matrix is testable.
///
/// In order: restoring goes to the splash; signed out may see public routes and is sent to the
/// welcome screen otherwise (keeping a validated `next`); a super admin is sent to the unsupported
/// role screen; and a signed-in person is kept out of another role's shell. Returns null to stay.
String? redirectFor({required SessionState session, required String location}) {
  final path = Uri.parse(location).path;

  // A link from outside the app arrives here as an ordinary location. Map the web's own paths onto
  // the app's, and refuse an id the API would never have issued, before any of the session rules run
  // — a link is untrusted input (§18, FLUTTER-028).
  if (deepLinkReplacement(path) case final replacement? when replacement != path) {
    return replacement;
  }

  switch (session) {
    case SessionUnknown() || SessionUnavailable():
      return path == AppRoutes.splash ? null : AppRoutes.splash;

    case SessionUnsupportedRole():
      return path == AppRoutes.unsupportedRole ? null : AppRoutes.unsupportedRole;

    case SessionSignedOut(:final reason):
      // A session that ended or was refused lands on sign-in, which explains why (§6); otherwise
      // the welcome screen is the way in.
      final entry = switch (reason) {
        SignedOutReason.none || SignedOutReason.signedOut => AppRoutes.welcome,
        SignedOutReason.expired ||
        SignedOutReason.refused ||
        SignedOutReason.deleted => AppRoutes.login,
      };
      if (path == AppRoutes.splash) return entry;
      if (sectionOf(path) == AppSection.public) return null;
      // A deliberate sign-out leaves from wherever the person was; that page is not a destination.
      if (reason == SignedOutReason.signedOut || reason == SignedOutReason.deleted) return entry;
      // Remember where they were going, but only if it is one of the app's own routes.
      return isKnownAppRoute(path)
          ? Uri(path: entry, queryParameters: {'next': path}).toString()
          : entry;

    case SessionSignedIn(:final profile):
      final home = homeFor(profile.role);
      // The signed-out entry points are not somewhere a signed-in person stays.
      if ([
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.unsupportedRole,
      ].contains(path)) {
        return home;
      }
      // Billing and onboarding are retired: their API routes are gone, so nobody stays on them.
      if (_isRetiredBillingPath(path)) return home;
      // The right shell, and the capability the route's backend guard asks for (§7).
      if (canOpen(profile, path)) return null;
      // An admin whose grants do not even cover their home stays there and sees the screen's own
      // permission-denied state; redirecting would loop.
      return path == home ? null : home;
  }
}

bool _isRetiredBillingPath(String path) =>
    path == AppRoutes.staffGetStarted ||
    path == AppRoutes.staffBilling ||
    path.startsWith('${AppRoutes.staffBilling}/');

/// Not called by the router any more: [redirectFor] sends its target home, so following this would
/// loop. Kept with its tests until the billing feature is retired.
///
/// A brand-new academy's admin lands on choose-a-plan instead of the dashboard (onboarding): plans
/// are enforced and the academy has never subscribed (`GET /academy/plan` `status: null`), so every
/// plan-gated module would refuse. Only the dashboard is replaced — the admin may still open
/// anything else — and only for someone who can read the plans on sale. "Not now" ([deferred])
/// keeps the dashboard for the rest of the session. A plan that was not read never redirects.
String? onboardingRedirect({
  required SessionState session,
  required String location,
  required AcademyPlan? plan,
  bool deferred = false,
}) {
  if (session is! SessionSignedIn) return null;
  if (Uri.parse(location).path != AppRoutes.staffDashboard) return null;
  if (deferred || plan == null || !plan.needsOnboarding) return null;
  if (!can(session.profile, Capability.viewBilling)) return null;
  return AppRoutes.staffGetStarted;
}

/// Where to go after signing in: the validated `next`, or the person's home (§5.1, no open
/// redirect). A target they may not open falls back to home.
String destinationAfterSignIn({required UserProfile profile, String? next}) {
  final home = homeFor(profile.role);
  if (next == null || !isKnownAppRoute(next) || !canOpen(profile, next)) return home;
  return next;
}

/// Where the auth screens send someone once they are signed in. With no `next`, nothing is done:
/// the router's own redirect has already moved them off the sign-in screen to their home. With
/// one, [destinationAfterSignIn] decides, so a target outside the app — or one this person may
/// not open — falls back to home.
void continueAfterSignIn({required GoRouter router, required UserProfile? profile, String? next}) {
  if (next == null || profile == null) return;
  router.go(destinationAfterSignIn(profile: profile, next: next));
}

/// Holds a link the app was opened with while the session is still being restored.
///
/// A cold start from a link races the session: `SessionUnknown` sends everyone to the splash, so the
/// location the link asked for would simply be lost and the reader would land on their home wondering
/// what happened. This remembers it for exactly as long as that takes, then hands it back once the
/// session is known — where the ordinary rules apply, including keeping it as `next` for someone who
/// has to sign in first (§5.4).
///
/// It is deliberately a small piece of mutable state owned by the router, not a provider: a provider
/// that changed during a redirect would ask the router to rebuild mid-redirect.
class LinkResume {
  String? _pending;

  /// What the router should do about [location], given [session].
  String? follow({required SessionState session, required String location}) {
    final path = Uri.parse(location).path;
    final restoring = session is SessionUnknown || session is SessionUnavailable;

    if (restoring) {
      // Remember where they were going, but only one of the app's own routes.
      if (path != AppRoutes.splash && isKnownAppRoute(path)) _pending = location;
      return redirectFor(session: session, location: location);
    }

    final pending = _pending;
    if (pending != null) {
      _pending = null;
      // The splash is where the restore left them; anywhere else means they have moved on, and the
      // link is stale.
      if (path == AppRoutes.splash) {
        return redirectFor(session: session, location: pending) ?? pending;
      }
    }
    return redirectFor(session: session, location: location);
  }

  /// Whether a link is still waiting for the session — for tests, and for nothing else.
  @visibleForTesting
  String? get pending => _pending;
}
