import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/format/dates_ist.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/theme.dart';
import '../../../features/auth/auth.dart';
import '../../../features/notifications/notifications.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/entitlements/entitlements.dart';
import '../../../shared/widgets/navigation/app_nav_bar.dart';
import '../../../shared/widgets/widgets.dart';
import '../nav_history.dart';
import '../routes.dart';
import '../up_navigation.dart';
import 'destinations.dart';

/// The frame every signed-in screen sits in (§5.2, §20): bottom navigation on phones, a rail from
/// 600 dp and an extended rail from 1024 dp, an app bar with the notification bell, the offline
/// banner, and Android back behaviour per §5.5.
class AppShell extends ConsumerWidget {
  const AppShell({
    required this.navigationShell,
    required this.layout,
    required this.notificationsRoute,
    super.key,
    this.profileRoute,
    this.showUnbuilt = false,
  });

  final StatefulNavigationShell navigationShell;
  final ShellLayout layout;

  /// Where the bell goes — the learner's or the staff route.
  final String notificationsRoute;

  /// Where the home header's avatar goes — the learner's or the staff profile.
  final String? profileRoute;

  /// Dev builds show destinations whose screens are not built yet.
  final bool showUnbuilt;

  void _onSelect(BuildContext context, List<ShellDestination> tabs, int index) {
    if (index == tabs.length) {
      _openMore(context, tabs);
      return;
    }
    _open(context, tabs[index]);
  }

  /// Every tab has a branch; an overflow entry without one is pushed onto the current branch. A
  /// destination chosen from the bar (or More) is a fresh start: Back from it follows the tabs'
  /// own rule, not the path that led there.
  void _open(BuildContext context, ShellDestination destination) {
    NavHistory.of(GoRouter.of(context)).resetNext();
    final branch = destination.branch;
    if (branch == null) {
      GoRouter.of(context).go(destination.route);
      return;
    }
    // A tab opens on its own page, every time: a page that a link from another tab left in this
    // tab's stack (a lesson resumed from Home) is not where the tab opens.
    navigationShell.goBranch(branch, initialLocation: true);
  }

  Future<void> _openMore(BuildContext context, List<ShellDestination> tabs) async {
    final l10n = context.l10n;
    final container = ProviderScope.containerOf(context);
    final overflow = layout.visible(
      layout.overflow,
      showUnbuilt: showUnbuilt,
      profile: container.read(currentUserProvider),
    );
    final plan = container.read(academyPlanProvider).value;
    // Grouped under headings (Teaching, Academy, Account) once there is more than one group to
    // tell apart; the learner's shell has no More at all.
    final groups = [
      for (final group in MoreGroup.values)
        (
          group,
          [
            for (final d in overflow)
              if (d.group == group) d,
          ],
        ),
    ].where((entry) => entry.$2.isNotEmpty).toList();
    await showAppBottomSheet<void>(
      context,
      builder: (sheetContext) => AppBottomSheet(
        title: l10n.moreSheetTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < groups.length; i++) ...[
              if (i > 0) const SizedBox(height: Space.s4),
              GroupedList(
                title: groups.length > 1 ? groups[i].$1.label(l10n) : null,
                children: [
                  for (final destination in groups[i].$2)
                    AppListTile(
                      title: destination.label(l10n),
                      leading: HueTile(
                        icon: destination.icon,
                        hue: AppNavIcons.of(destination.icon).hue,
                      ),
                      // A module the plan does not open is still offered, marked, and explains
                      // itself.
                      trailing: destination.accessUnder(plan) == ModuleAccess.open
                          ? null
                          : PlanAccessBadge(access: destination.accessUnder(plan)),
                      showChevron: true,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _open(context, destination);
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: Space.s2),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final size = WindowSize.of(context);
    final profile = ref.watch(currentUserProvider);
    final offline = ref.watch(isOnlineProvider).value == false;
    final plan = ref.watch(academyPlanProvider).value;

    // A tab the person cannot open is not offered — but the shell always keeps at least one, so
    // the navigation bar has something to show while signing out (when the profile is briefly
    // null) or for an admin whose grants cover nothing; that screen shows its own refusal.
    // The first tab is where the person lands, so it is always the first button: when their grants
    // do not cover it, its page says so rather than the bar marking another tab they are not on.
    final permitted = layout.visible(layout.tabs, showUnbuilt: true, profile: profile);
    final tabs = permitted.contains(layout.tabs.first)
        ? permitted
        : [layout.tabs.first, ...permitted];

    // Where the person is: a page opened from More replaces the first tab's own page in its
    // stack, so "on the first tab" is not the same as "where Back should leave the app".
    final location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;

    final home = tabs.first.route;
    final atHome = navigationShell.currentIndex == 0 && location == home;
    // Where this page was opened from, when a link opened it: Back returns there first (§5.5).
    final history = NavHistory.of(GoRouter.of(context));
    final previous = history.previous;
    // Back leaves the app only from the first tab's own page, with nothing to go back to.
    final canExit = atHome && previous == null;
    // A prefix match that belongs to another tab does not name this page: `/staff/submissions/7`
    // sits under `/staff` (the dashboard) by path, but it is the Review tab's page.
    final match = _pageFor(location, [...tabs, ...layout.overflow, ...layout.pages]);
    final page =
        match != null &&
            match.route != location &&
            match.branch != null &&
            match.branch != navigationShell.currentIndex
        ? null
        : match;
    // The tab whose stack holds this page.
    final branchTab = tabs.firstWhere(
      (t) => t.branch == navigationShell.currentIndex,
      orElse: () => tabs.first,
    );
    // The bar marks where the person is: a page opened from More marks More, not the tab whose
    // stack happens to hold it.
    final selected = page != null && !tabs.contains(page) && layout.overflow.contains(page)
        ? tabs.length
        : tabs.indexOf(branchTab);
    // A page below a destination (a course, a submission, an edit form) goes up to its parent
    // inside the same tab, both from the app bar's back arrow and from Android Back (§5.5).
    final up = _upFor(context, location, [
      ...tabs,
      ...layout.overflow,
      // A page that is a root of its tab (Assignments beside Tests) has nothing above it.
      ...layout.pages.where((p) => p.branch != null),
    ], branchTab);

    final body = Column(
      children: [
        if (offline) const OfflineBanner(),
        // One plan notice at a time: past due, then restricted, then the trial.
        const AcademyPlanBanner(),
        // Its own semantics container: every page in a tab sits on a ModalBarrier, whose
        // BlockSemantics otherwise hides everything painted before it — the banners above — from
        // assistive technology (found by the live E2E layer: CORE-001).
        Expanded(
          child: Semantics(
            container: true,
            child: UpNavigation(up: previous ?? up, child: navigationShell),
          ),
        ),
      ],
    );

    // Android 13+ predictive back asks the framework up front whether it will handle Back, and a
    // tab's own navigator — with nothing of its own to pop — keeps answering "no". Unless the shell
    // answers too, Android closes the app from any tab (LIVE E2E NAV-002) instead of going home.
    if (!canExit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) const NavigationNotification(canHandlePop: true).dispatch(context);
      });
    }

    return PopScope(
      canPop: canExit,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Where the page was opened from comes first; then up, then the first tab.
        if (history.back()) return;
        history.backNext();
        if (up != null) {
          GoRouter.of(context).go(up);
          return;
        }
        // Back leaves a tab, or a page opened from More, by returning to the first tab's own page,
        // and only then exits (§5.5).
        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        } else {
          GoRouter.of(context).go(home);
        }
      },
      child: NotificationListener<NavigationNotification>(
        onNotification: (notification) {
          if (notification.canHandlePop || canExit) return false;
          const NavigationNotification(canHandlePop: true).dispatch(context);
          return true;
        },
        child: Scaffold(
          appBar: atHome && profile != null
              // The first tab's own page greets the person instead of naming itself; the avatar
              // is the way to their profile, as on any phone app.
              ? CommonAppBar(
                  automaticallyImplyLeading: false,
                  leadingWidth: profileRoute == null ? null : ProfileAvatarButton.width,
                  leading: profileRoute == null
                      ? null
                      : ProfileAvatarButton(
                          name: profile.name,
                          onPressed: () => GoRouter.of(context).go(profileRoute!),
                        ),
                  title: l10n.homeGreetingName(
                    DatesIst.greeting(l10n, DateTime.now()),
                    AvatarInitials.firstNameOf(profile.name),
                  ),
                  subtitle: profile.descriptor.isEmpty ? null : profile.descriptor,
                  actions: [NotificationBell(route: notificationsRoute)],
                )
              : CommonAppBar(
                  automaticallyImplyLeading: false,
                  onBack: previous == null && up == null ? null : () => _goBack(context, up),
                  // The page's own name (§5.2): a page opened from More says what it is, not
                  // which tab happens to hold it.
                  title:
                      _subpageTitle(location, l10n) ?? page?.label(l10n) ?? branchTab.label(l10n),
                  actions: [NotificationBell(route: notificationsRoute)],
                ),
          body: size.isCompact
              ? body
              : Row(
                  children: [
                    _Rail(
                      tabs: tabs,
                      showMore: layout.hasMore,
                      plan: plan,
                      selected: selected,
                      extended: size == WindowSize.expanded,
                      onSelect: (index) => _onSelect(context, tabs, index),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: body),
                  ],
                ),
          bottomNavigationBar: size.isCompact
              ? MediaQuery.withClampedTextScaling(
                  // Labels stop growing at 115 %, as the platforms' own bars do: past that, five
                  // labels crowd the bar. Each keeps its full name as its tooltip and semantics.
                  maxScaleFactor: 1.15,
                  child: AppNavBar(
                    selectedIndex: selected,
                    onDestinationSelected: (index) => _onSelect(context, tabs, index),
                    destinations: [
                      for (final tab in tabs)
                        AppNavDestination(
                          icon: tab.icon,
                          label: tab.label(l10n),
                          access: tab.accessUnder(plan),
                        ),
                      if (layout.hasMore)
                        AppNavDestination(icon: AppIcons.more, label: l10n.navMore),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }

  /// The app bar's back arrow. The page's own navigator is asked first, so a form's
  /// unsaved-changes guard (a `PopScope` on the page) still gets to ask before leaving; only when
  /// nothing there handles it does the arrow go back to where the page was opened from — or, with
  /// nothing remembered, up.
  Future<void> _goBack(BuildContext context, String? up) async {
    final router = GoRouter.of(context);
    final branch = navigationShell.route.branches[navigationShell.currentIndex];
    final handled = await branch.navigatorKey.currentState?.maybePop() ?? false;
    final history = NavHistory.of(router);
    if (handled || history.back()) return;
    if (up != null) {
      history.backNext();
      router.go(up);
    }
  }

  /// Where "up" leads from [location], or null on a destination's own page. The nearest shorter
  /// path that is a page of the current branch wins (`/staff/courses/1/lessons/2` → the course);
  /// a page with no such ancestor (`/learn/42`) goes up to its tab.
  String? _upFor(
    BuildContext context,
    String location,
    List<ShellDestination> destinations,
    ShellDestination tab,
  ) {
    final config = GoRouter.of(context).configuration;
    RouteBase? routeOf(String path) {
      final match = config.findMatch(Uri.parse(path));
      if (match.isError || match.isEmpty) return null;
      return match.last.route;
    }

    final here = routeOf(location);
    if (here == null) return null;
    // A destination's own page — including the other tabs of a parameterised one (My Learning's
    // Completed is the same page as its In progress).
    for (final destination in destinations) {
      if (destination.route == location || routeOf(destination.route) == here) return null;
    }
    final branch = navigationShell.route.branches[navigationShell.currentIndex];
    bool inBranch(RouteBase route) => branch.routes.contains(route);
    final segments = Uri.parse(location).pathSegments.toList();
    while (segments.length > 1) {
      segments.removeLast();
      final candidate = '/${segments.join('/')}';
      final route = routeOf(candidate);
      if (route is GoRoute && route.redirect == null && inBranch(route)) return candidate;
    }
    return tab.route == location ? null : tab.route;
  }

  /// The destination whose route is the longest match for [location] — `/assignments/42` is the
  /// Assignments page — or null when none matches.
  /// Fixed pages beneath a destination that name themselves rather than their parent (a detail
  /// page with an id keeps the parent's name: its own heading names the item).
  static String? _subpageTitle(String location, AppLocalizations l10n) => switch (location) {
    AppRoutes.profileSettings || AppRoutes.staffProfileSettings => l10n.settingsTitle,
    AppRoutes.profileDeleteAccount => l10n.deleteAccountTitle,
    AppRoutes.profilePurchases => l10n.purchasesTitle,
    AppRoutes.notificationPreferences ||
    AppRoutes.staffNotificationPreferences => l10n.notificationPrefsTitle,
    // A staff form says what it is doing, not which tab holds it ("Schedule a class", not "Live").
    AppRoutes.staffLiveNew => l10n.staffLiveNewTitle,
    AppRoutes.staffCalendarNew => l10n.calendarNewTitle,
    AppRoutes.staffInstructorInvite => l10n.instructorFormInviteTitle,
    _ when _editOf(location, '/staff/live/') => l10n.staffLiveEditTitle,
    _ when _editOf(location, '/staff/calendar/') => l10n.calendarEditTitle,
    _ when _editOf(location, '/staff/instructors/') => l10n.instructorFormEditTitle,
    _ => null,
  };

  /// Whether [location] is `<prefix><id>/edit`.
  static bool _editOf(String location, String prefix) =>
      location.startsWith(prefix) &&
      location.endsWith('/edit') &&
      !location.substring(prefix.length, location.length - '/edit'.length).contains('/');

  static ShellDestination? _pageFor(String location, List<ShellDestination> destinations) {
    ShellDestination? best;
    for (final destination in destinations) {
      final route = destination.route;
      final matches =
          location == route || location.startsWith(route.endsWith('/') ? route : '$route/');
      if (matches && (best == null || route.length > best.route.length)) best = destination;
    }
    return best;
  }
}

/// A destination's icon in the bar or the rail (AppNavIcons): the light line glyph in the quiet ink
/// while idle; selected, the filled glyph in the destination's own hue on a pill of its soft tint —
/// shape and colour both say where you are. A module the plan does not open keeps its badge.
class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, this.access = ModuleAccess.open, this.selected = false});

  final IconData icon;
  final ModuleAccess access;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final glyph = AppNavIcons.of(icon);
    final h = c.hue(glyph.hue);
    final drawn = IconTheme.merge(
      data: IconThemeData(color: selected ? h.solid : c.muted),
      child: PlanAwareNavIcon(
        icon: selected ? glyph.active : glyph.idle,
        access: access,
        size: IconSizes.lg,
      ),
    );
    if (!selected) return drawn;
    return Container(
      width: 56,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: h.soft, borderRadius: BorderRadius.circular(Radii.pill)),
      child: drawn,
    );
  }
}

/// The signed-in person's initials as the home header's leading button: opens their profile.
class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({required this.name, required this.onPressed, super.key});

  final String name;
  final VoidCallback onPressed;

  /// The app bar's leading width: the gutter, the avatar and the gap before the title.
  static const double width = Space.s4 + AvatarSizes.md + Space.s3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Space.s4, right: Space.s3),
      child: Center(
        child: Semantics(
          button: true,
          label: context.l10n.navProfile,
          excludeSemantics: true,
          child: Tooltip(
            message: context.l10n.navProfile,
            child: InkResponse(
              onTap: onPressed,
              radius: Space.minTap / 2,
              child: AvatarInitials(name: name, size: AvatarSizes.md),
            ),
          ),
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.tabs,
    required this.showMore,
    required this.plan,
    required this.selected,
    required this.extended,
    required this.onSelect,
  });

  final List<ShellDestination> tabs;
  final bool showMore;
  final AcademyPlan? plan;
  final int selected;
  final bool extended;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // A phone on its side is wide enough for the rail but only ~360 dp tall: there the rail names
    // only the selected destination, and scrolls rather than overflowing if it still does not fit.
    final short = MediaQuery.sizeOf(context).height < 480;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(child: _rail(l10n, short)),
        ),
      ),
    );
  }

  Widget _rail(AppLocalizations l10n, bool short) {
    return NavigationRail(
      selectedIndex: selected,
      // Each selected destination draws its own pill, in its own hue (_NavIcon).
      indicatorColor: Colors.transparent,
      extended: extended,
      labelType: extended
          ? NavigationRailLabelType.none
          : (short ? NavigationRailLabelType.selected : NavigationRailLabelType.all),
      onDestinationSelected: onSelect,
      destinations: [
        for (final tab in tabs)
          NavigationRailDestination(
            icon: _NavIcon(icon: tab.icon, access: tab.accessUnder(plan)),
            selectedIcon: _NavIcon(icon: tab.icon, access: tab.accessUnder(plan), selected: true),
            label: Text(tab.label(l10n)),
          ),
        if (showMore)
          NavigationRailDestination(
            icon: const _NavIcon(icon: AppIcons.more),
            selectedIcon: const _NavIcon(icon: AppIcons.more, selected: true),
            label: Text(l10n.navMore),
          ),
      ],
    );
  }
}

/// A destination whose screen a later module builds (§5 route table). Inside a shell it is just a
/// body — the shell already provides the app bar; [standalone] adds one for public routes.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({required this.title, super.key, this.standalone = false});

  final String title;
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final body = StateLayout(
      icon: AppIcons.empty,
      title: l10n.comingSoonTitle,
      message: l10n.comingSoonBody,
    );
    if (!standalone) return body;
    return Scaffold(
      appBar: CommonAppBar(title: title),
      body: body,
    );
  }
}

/// An app route that does not exist (a bad deep link, a stale notification target).
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.home = AppRoutes.welcome});

  final String home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      body: NotFoundView(onBack: () => GoRouter.of(context).go(home)),
    );
  }
}

/// The bell, with the academy's own unread count on it. The number is polled — there is no push
/// and no socket (§12) — and a failed poll leaves the last one showing rather than shouting.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({required this.route, super.key});

  final String route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final unread = ref.watch(unreadCountProvider) ?? 0;
    final bell = Icon(
      AppNavIcons.of(AppIcons.notifications).idle,
      size: IconSizes.md,
      color: c.text,
    );
    // A light line bell in a small round chip, sized with the avatar opposite it. The count sits
    // on the bell's own shoulder — badging the whole tap target left it floating off in a corner.
    // The end inset matches the avatar's at the start, so the header sits evenly in its margins.
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: Space.s1),
      child: IconButton(
        tooltip: unread > 0 ? l10n.notificationsUnreadBadge(unread) : l10n.notificationsBellLabel,
        onPressed: () => GoRouter.of(context).go(route),
        constraints: const BoxConstraints(minWidth: Space.minTap, minHeight: Space.minTap),
        padding: EdgeInsets.zero,
        icon: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.surface,
            shape: BoxShape.circle,
            border: Border.all(color: c.border),
          ),
          child: unread == 0
              ? bell
              : Badge(
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  backgroundColor: c.danger,
                  textColor: c.onAccent,
                  textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, height: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  largeSize: 16,
                  offset: const Offset(6, -5),
                  child: bell,
                ),
        ),
      ),
    );
  }
}
