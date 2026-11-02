import 'package:flutter/widgets.dart';

import '../../../core/auth/capabilities.dart';
import '../../../features/auth/auth.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/entitlements/entitlements.dart';
import '../../../shared/widgets/widgets.dart';
import '../route_access.dart';
import '../routes.dart';

/// The headings of the staff More sheet, in the order it shows them: the day-to-day teaching
/// pages, the academy's own, then the person's account.
enum MoreGroup {
  teaching,
  academy,
  account;

  String label(AppLocalizations l10n) => switch (this) {
    MoreGroup.teaching => l10n.moreGroupTeaching,
    MoreGroup.academy => l10n.moreGroupAcademy,
    MoreGroup.account => l10n.moreGroupAccount,
  };
}

/// One entry in a shell's navigation (§5.2).
class ShellDestination {
  const ShellDestination({
    required this.route,
    required this.icon,
    required this.label,
    this.branch,
    this.capability,
    this.built = false,
    this.group = MoreGroup.account,
  });

  /// The heading it sits under in the More sheet. Only overflow entries are grouped.
  final MoreGroup group;

  /// Where it goes — always a route from [AppRoutes].
  final String route;

  /// The shell branch this destination lives in, when it has its own tab stack. Overflow entries
  /// without one are pushed onto the current branch instead.
  final int? branch;
  final IconData icon;
  final String Function(AppLocalizations l10n) label;

  /// What the person must be able to do for this destination to be offered — the same capability
  /// the route's backend guard checks (§7). Null means any member of the shell may see it.
  final Capability? capability;

  /// Whether the screen behind it exists yet. Unbuilt destinations show a placeholder in dev and
  /// are hidden in staging and prod (FLUTTER-005 spec); each module flips its own to true.
  final bool built;

  /// The plan-gated module behind it, if any — the same answer the router's gate uses.
  WorkspaceModule? get module => moduleOf(route);

  /// How the academy's [plan] opens this destination. One no plan feature governs is always open,
  /// and so is every destination while the plan is not known.
  ModuleAccess accessUnder(AcademyPlan? plan) {
    final gated = module;
    return gated == null ? ModuleAccess.open : moduleAccess(plan, gated);
  }
}

/// The tabs and overflow of each role's shell (§5.2). Tabs keep their own stack; when there is an
/// overflow, the last button opens it.
class ShellLayout {
  const ShellLayout({required this.tabs, this.overflow = const [], this.pages = const []});

  /// Branches of the indexed stack. With an [overflow], "More" is added by the shell as one more
  /// button, so a shell has at most five.
  final List<ShellDestination> tabs;

  /// Shown in the "More" sheet. Empty means the shell has no "More" button at all.
  final List<ShellDestination> overflow;

  /// Pages reached from inside a tab rather than from the bar (Explore from My Learning,
  /// Certificates from Profile). They are never offered as navigation; they name their own page
  /// in the app bar. One with a [ShellDestination.branch] is a root of that tab beside the tab's
  /// own page (Assignments beside Tests) and has no back arrow; one without goes up to its tab.
  final List<ShellDestination> pages;

  /// Whether the shell shows the "More" button.
  bool get hasMore => overflow.isNotEmpty;

  /// What [profile] is offered: destinations whose capability they hold, and — unless the build
  /// shows them — only those whose screen exists.
  List<ShellDestination> visible(
    List<ShellDestination> destinations, {
    required bool showUnbuilt,
    UserProfile? profile,
  }) => [
    for (final destination in destinations)
      if ((showUnbuilt || destination.built) &&
          (destination.capability == null || can(profile, destination.capability!)))
        destination,
  ];
}

const _home = ShellDestination(
  route: AppRoutes.home,
  icon: AppIcons.home,
  label: _homeLabel,
  branch: 0,
);
String _homeLabel(AppLocalizations l10n) => l10n.navHome;

/// The learner shell: Home · Courses · Live · Tests · Profile, and no "More". Courses is the
/// academy's whole catalogue; the learner's own courses (in progress, completed, saved),
/// certificates and the rank ladder sit under Profile.
ShellLayout learnerLayout() => const ShellLayout(
  tabs: [
    _home,
    ShellDestination(
      route: AppRoutes.explore,
      icon: AppIcons.learning,
      // One word, like every label in the bar: two-word labels wrap at large text sizes.
      label: _coursesLabel,
      branch: 1,
      built: true,
    ),
    ShellDestination(
      route: AppRoutes.live,
      icon: AppIcons.live,
      label: _liveLabel,
      branch: 2,
      built: true,
    ),
    ShellDestination(
      route: AppRoutes.assessments,
      icon: AppIcons.quiz,
      label: _testsLabel,
      branch: 3,
      built: true,
    ),
    ShellDestination(
      route: AppRoutes.profile,
      icon: AppIcons.profile,
      label: _profileLabel,
      branch: 4,
      built: true,
    ),
  ],
  pages: [
    // Tests and Assignments are the two halves of one tab.
    ShellDestination(
      route: AppRoutes.assignments,
      icon: AppIcons.assignment,
      label: _assignmentsLabel,
      branch: 3,
      built: true,
    ),
    // The learner's own courses, opened from Profile; every tab of it goes up to Profile.
    ShellDestination(
      route: AppRoutes.myLearningRoot,
      icon: AppIcons.learning,
      label: _myCoursesLabel,
      built: true,
    ),
    ShellDestination(
      route: AppRoutes.certificates,
      icon: AppIcons.certificate,
      label: _certificatesLabel,
      built: true,
    ),
    ShellDestination(route: AppRoutes.ranks, icon: AppIcons.rank, label: _ranksLabel, built: true),
    // The same pages opened from Home's shortcuts: they name themselves, and go up to Home.
    ShellDestination(
      route: AppRoutes.homeMyLearningRoot,
      icon: AppIcons.learning,
      label: _myCoursesLabel,
      built: true,
    ),
    ShellDestination(
      route: AppRoutes.homeAssignments,
      icon: AppIcons.assignment,
      label: _assignmentsLabel,
      built: true,
    ),
    ShellDestination(
      route: AppRoutes.homeAssessments,
      icon: AppIcons.quiz,
      label: _testsLabel,
      built: true,
    ),
    ShellDestination(
      route: AppRoutes.homeCertificates,
      icon: AppIcons.certificate,
      label: _certificatesLabel,
      built: true,
    ),
    ShellDestination(
      route: AppRoutes.homeRanks,
      icon: AppIcons.rank,
      label: _ranksLabel,
      built: true,
    ),
    ShellDestination(
      route: AppRoutes.notifications,
      icon: AppIcons.notifications,
      label: _notificationsLabel,
      built: true,
    ),
  ],
);

/// The staff shell, in the learner's order — Home, Courses, Live, then the role's own work — and a
/// More sheet grouped under Teaching, Academy and Account. An instructor's fourth tab is Review
/// (their marking); an academy admin's is People, and Review heads their More sheet. Every route,
/// branch and capability is the same whichever slot a destination sits in.
ShellLayout staffLayout(UserRole role) {
  final isAdmin = role == UserRole.admin;
  const review = ShellDestination(
    route: AppRoutes.staffReview,
    icon: AppIcons.review,
    label: _reviewLabel,
    branch: 1,
    capability: Capability.viewAssessments,
    built: true,
    group: MoreGroup.teaching,
  );
  const live = ShellDestination(
    route: AppRoutes.staffLive,
    icon: AppIcons.live,
    label: _liveLabel,
    branch: 3,
    built: true,
    group: MoreGroup.teaching,
  );
  return ShellLayout(
    tabs: [
      const ShellDestination(
        route: AppRoutes.staffDashboard,
        icon: AppIcons.dashboard,
        label: _homeLabel,
        branch: 0,
        capability: Capability.viewReports,
        built: true,
      ),
      const ShellDestination(
        route: AppRoutes.staffCourses,
        icon: AppIcons.courses,
        label: _coursesLabel,
        branch: 2,
        capability: Capability.viewCourses,
        built: true,
      ),
      if (isAdmin)
        const ShellDestination(
          route: AppRoutes.staffStudents,
          icon: AppIcons.people,
          label: _peopleLabel,
          branch: 4,
          capability: Capability.viewLearners,
          built: true,
        ),
      live,
      if (!isAdmin) review,
    ],
    overflow: [
      if (isAdmin) review,
      if (!isAdmin)
        const ShellDestination(
          route: AppRoutes.staffStudents,
          icon: AppIcons.people,
          label: _studentsLabel,
          branch: 4,
          capability: Capability.viewLearners,
          built: true,
          group: MoreGroup.teaching,
        ),
      const ShellDestination(
        route: AppRoutes.staffCalendar,
        icon: AppIcons.calendar,
        label: _calendarLabel,
        built: true,
        group: MoreGroup.teaching,
      ),
      const ShellDestination(
        route: AppRoutes.staffQuizzes,
        icon: AppIcons.quiz,
        label: _quizzesLabel,
        capability: Capability.viewAssessments,
        built: true,
        group: MoreGroup.teaching,
      ),
      // Offered by capability, not by role: `instructors.view`, `certificates.issue` and
      // `reports.view` are staff keys an instructor passes on role (apps/api/src/lib/permissions.ts).
      const ShellDestination(
        route: AppRoutes.staffCertificates,
        icon: AppIcons.certificate,
        label: _certificatesLabel,
        capability: Capability.issueCertificates,
        group: MoreGroup.teaching,
      ),
      const ShellDestination(
        route: AppRoutes.staffInstructors,
        icon: AppIcons.instructor,
        label: _instructorsLabel,
        capability: Capability.viewInstructors,
        group: MoreGroup.academy,
      ),
      const ShellDestination(
        route: AppRoutes.staffReports,
        icon: AppIcons.reports,
        label: _reportsLabel,
        capability: Capability.viewReports,
        group: MoreGroup.academy,
      ),
      const ShellDestination(
        route: AppRoutes.staffProfile,
        icon: AppIcons.profile,
        label: _profileLabel,
        built: true,
      ),
      const ShellDestination(
        route: AppRoutes.staffNotifications,
        icon: AppIcons.notifications,
        label: _notificationsLabel,
        built: true,
      ),
      const ShellDestination(
        route: AppRoutes.staffHelp,
        icon: AppIcons.help,
        label: _helpLabel,
        built: true,
      ),
    ],
  );
}

String _myCoursesLabel(AppLocalizations l10n) => l10n.navMyCourses;
String _liveLabel(AppLocalizations l10n) => l10n.navLive;
String _profileLabel(AppLocalizations l10n) => l10n.navProfile;
String _assignmentsLabel(AppLocalizations l10n) => l10n.navAssignments;
String _testsLabel(AppLocalizations l10n) => l10n.navTests;
String _certificatesLabel(AppLocalizations l10n) => l10n.navCertificates;
String _ranksLabel(AppLocalizations l10n) => l10n.navRanks;
String _notificationsLabel(AppLocalizations l10n) => l10n.navNotifications;
String _helpLabel(AppLocalizations l10n) => l10n.navHelp;
String _peopleLabel(AppLocalizations l10n) => l10n.navPeople;
String _studentsLabel(AppLocalizations l10n) => l10n.navStudents;
String _reviewLabel(AppLocalizations l10n) => l10n.navReview;
String _coursesLabel(AppLocalizations l10n) => l10n.navCourses;
String _calendarLabel(AppLocalizations l10n) => l10n.navCalendar;
String _quizzesLabel(AppLocalizations l10n) => l10n.navQuizzes;
String _instructorsLabel(AppLocalizations l10n) => l10n.navInstructors;
String _reportsLabel(AppLocalizations l10n) => l10n.navReports;
