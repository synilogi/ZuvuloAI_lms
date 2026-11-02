import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'nav_history.dart';
import 'routes.dart';

/// Where "up" leads from the page below it, published by the shell (the same target as the app
/// bar's back arrow). Pages in a tab are flat routes opened with `go`, so a page's own navigator
/// usually has nothing beneath it to pop back to.
class UpNavigation extends InheritedWidget {
  const UpNavigation({required this.up, required super.child, super.key});

  final String? up;

  @override
  bool updateShouldNotify(UpNavigation oldWidget) => oldWidget.up != up;
}

/// Opens [route] from the page on screen, keeping it in the tab that holds this page when that tab
/// holds [route] too ([AppRoutes.within]): a certificate opened from Home's Certificates stays in
/// Home, so Back walks back to Home rather than to Profile.
///
/// With [replace] the target is this same page shown another way (another tab of My Courses, the
/// other half of Tests): Back skips it and returns to where the page was opened from.
void goWithin(BuildContext context, String route, {bool replace = false}) {
  final router = GoRouter.of(context);
  if (replace) NavHistory.of(router).replaceNext();
  router.go(AppRoutes.within(router.routerDelegate.currentConfiguration.uri.path, route));
}

/// Leaves the current page once its unsaved-changes guard has been answered "Leave": pops when
/// there is a page beneath, otherwise goes up to the parent the shell named. Popping the only page
/// of a tab is not a way out — go_router refuses it, and the screen was left blank.
void leavePage(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }
  final router = GoRouter.of(context);
  final history = NavHistory.of(router);
  if (history.back()) return;
  final up = context.getInheritedWidgetOfExactType<UpNavigation>()?.up;
  if (up != null) {
    history.backNext();
    router.go(up);
  } else if (router.canPop()) {
    router.pop();
  }
}

/// The nearest shorter path of [location] that is a page of its own (`/catalog/x/preview/y` →
/// `/catalog/x`), or null when none is.
String? parentRouteOf(GoRouter router, String location) {
  final segments = Uri.parse(location).pathSegments.toList();
  while (segments.length > 1) {
    segments.removeLast();
    final candidate = '/${segments.join('/')}';
    final match = router.configuration.findMatch(Uri.parse(candidate));
    if (match.isError || match.isEmpty) continue;
    final route = match.last.route;
    if (route.redirect == null) return candidate;
  }
  return null;
}

/// The back arrow for a full-screen page outside the shells (the catalogue, verification, help).
/// Those pages are opened with `go`, so there is often nothing beneath them to pop: the arrow then
/// goes up to the parent page, or to [fallback] (where the page was opened from). Null — letting
/// the app bar decide — when a page beneath can simply be popped, or when there is nowhere to go.
Widget? upButton(BuildContext context, {String? fallback}) {
  if (Navigator.of(context).canPop()) return null;
  final router = GoRouter.maybeOf(context);
  if (router == null) return null;
  final history = NavHistory.of(router);
  // Back to where the page was opened from comes first (§5.5).
  if (history.previous != null) return BackButton(onPressed: history.back);
  final location = router.routerDelegate.currentConfiguration.uri.path;
  final up = parentRouteOf(router, location) ?? fallback;
  if (up == null || up == location) return null;
  return BackButton(
    onPressed: () {
      history.backNext();
      router.go(up);
    },
  );
}

/// Makes Android Back on a full-screen page outside the shells do what its [upButton] does — go
/// up — instead of closing the app because nothing lies beneath the page.
class UpPopScope extends StatelessWidget {
  const UpPopScope({required this.child, super.key, this.fallback});

  final Widget child;
  final String? fallback;

  @override
  Widget build(BuildContext context) {
    if (Navigator.of(context).canPop()) return child;
    final router = GoRouter.maybeOf(context);
    if (router == null) return child;
    final history = NavHistory.of(router);
    final location = router.routerDelegate.currentConfiguration.uri.path;
    final up = parentRouteOf(router, location) ?? fallback;
    if (history.previous == null && (up == null || up == location)) return child;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || history.back()) return;
        if (up != null && up != location) {
          history.backNext();
          router.go(up);
        }
      },
      child: child,
    );
  }
}
