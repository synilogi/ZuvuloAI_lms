import 'package:go_router/go_router.dart';

import 'routes.dart';

/// Where Back goes: the pages the person came through, newest last (§5.5).
///
/// Every in-app link is a `go`, so the router keeps no history of its own and Back used to go
/// "up" the path inside the tab that holds a page — a course opened from Home went back to the
/// catalogue. This listens to the router and remembers each page a link left, so Back returns to
/// the screen a page was opened from, whichever tab or shell that was. With nothing remembered (a
/// deep link, a notification, a cold start) the callers fall back to going up.
class NavHistory {
  NavHistory._(this._router) {
    _current = _location;
    _router.routerDelegate.addListener(_onChange);
  }

  static final _all = Expando<NavHistory>();

  /// The history of [router], started the first time it is asked for. The app's router asks at
  /// creation, so nothing is missed.
  static NavHistory of(GoRouter router) => _all[router] ??= NavHistory._(router);

  /// Enough for any real path through the app; the oldest steps are dropped beyond it.
  static const _limit = 50;

  /// Where a new start begins: arriving from one of these is not a step to come back to, and
  /// arriving at one (signing out) forgets the signed-in path.
  static const _entryRoutes = {
    AppRoutes.splash,
    AppRoutes.welcome,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
    AppRoutes.unsupportedRole,
  };

  final GoRouter _router;
  final List<String> _stack = [];
  String _current = '';
  _Intent _next = _Intent.forward;

  String get _location => _router.routerDelegate.currentConfiguration.uri.toString();

  /// The page Back returns to, or null when nothing is remembered.
  String? get previous => _stack.isEmpty ? null : _stack.last;

  /// Goes back to [previous]. False — and nothing happens — when nothing is remembered.
  bool back() {
    while (_stack.isNotEmpty && _stack.last == _current) {
      _stack.removeLast();
    }
    if (_stack.isEmpty) return false;
    final target = _stack.removeLast();
    _next = _Intent.back;
    _router.go(target);
    return true;
  }

  /// The next navigation is itself a way back, made when nothing was remembered (up to the parent
  /// page, or to the first tab): it is not a step to come back to.
  void backNext() => _next = _Intent.back;

  /// The next navigation shows this page another way (another tab of My Courses, the other half
  /// of Tests): it is not a step of its own, so Back skips it.
  void replaceNext() => _next = _Intent.replace;

  /// The next navigation starts afresh (a tab chosen from the bottom bar): what came before is
  /// forgotten, and Back from there follows the tabs' own rule (§5.5).
  void resetNext() => _next = _Intent.reset;

  void _onChange() {
    final now = _location;
    if (now.isEmpty || now == _current) return;
    final from = _current;
    _current = now;
    final intent = _next;
    _next = _Intent.forward;

    switch (intent) {
      case _Intent.back || _Intent.replace:
        return;
      case _Intent.reset:
        _stack.clear();
        return;
      case _Intent.forward:
        break;
    }
    if (_isEntry(now) || from.isEmpty || _isEntry(from)) {
      _stack.clear();
      return;
    }
    // Going on to exactly the page just left is going back to it (a page that pops itself, a
    // "Back to the course" link), not a loop to walk through again.
    if (_stack.isNotEmpty && _stack.last == now) {
      _stack.removeLast();
      return;
    }
    _stack.add(from);
    if (_stack.length > _limit) _stack.removeAt(0);
  }

  static bool _isEntry(String location) => _entryRoutes.contains(Uri.parse(location).path);
}

enum _Intent { forward, back, replace, reset }
