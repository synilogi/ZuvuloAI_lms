import '../../core/auth/capabilities.dart';
import '../../features/auth/auth.dart';
import '../../shared/entitlements/module_access.dart';
import 'routes.dart';

/// Which part of the app a route belongs to (§5.2). Membership decides the shell and the redirect;
/// the server still decides every piece of data.
enum AppSection {
  /// Reachable signed out (and signed in).
  public,

  /// The learner shell.
  learner,

  /// The staff shell — instructors and academy admins. Which staff routes a person may open is
  /// decided per route by [requiredCapability], mirroring the backend's guards (§7).
  staff,
}

class _RoutePattern {
  _RoutePattern(this.pattern, this.section)
    : _regExp = RegExp('^${pattern.replaceAll(RegExp(r':[A-Za-z]+'), r'[^/]+')}\$');

  final String pattern;
  final AppSection section;
  final RegExp _regExp;

  bool matches(String path) => _regExp.hasMatch(path);
}

final List<_RoutePattern> _routes = [
  // Public
  for (final path in [
    AppRoutes.splash,
    AppRoutes.welcome,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.invitePattern,
    AppRoutes.courseEnrolPattern,
    AppRoutes.forgotPassword,
    AppRoutes.resetPasswordPattern,
    AppRoutes.catalog,
    AppRoutes.catalogCoursePattern,
    AppRoutes.catalogPreviewPattern,
    AppRoutes.verify,
    AppRoutes.verifyCredentialPattern,
    AppRoutes.help,
    AppRoutes.helpArticlePattern,
    AppRoutes.helpCategoryPattern,
    AppRoutes.privacy,
    AppRoutes.terms,
    AppRoutes.unsupportedRole,
  ])
    _RoutePattern(path, AppSection.public),
  // Learner
  for (final path in [
    AppRoutes.home,
    AppRoutes.myLearningRoot,
    AppRoutes.myLearningPattern,
    AppRoutes.explore,
    AppRoutes.learnCoursePattern,
    AppRoutes.learnLessonPattern,
    AppRoutes.assignments,
    AppRoutes.assignmentPattern,
    AppRoutes.assessments,
    AppRoutes.live,
    AppRoutes.liveClassPattern,
    AppRoutes.certificates,
    AppRoutes.certificatePattern,
    AppRoutes.ranks,
    AppRoutes.notifications,
    AppRoutes.notificationPreferences,
    AppRoutes.notificationPattern,
    AppRoutes.profile,
    AppRoutes.profileSettings,
    AppRoutes.profileDeleteAccount,
    AppRoutes.profilePurchases,
    AppRoutes.homeMyLearningRoot,
    AppRoutes.homeMyLearningPattern,
    AppRoutes.homeAssignments,
    AppRoutes.homeAssignmentPattern,
    AppRoutes.homeAssessments,
    AppRoutes.homeCertificates,
    AppRoutes.homeCertificatePattern,
    AppRoutes.homeRanks,
  ])
    _RoutePattern(path, AppSection.learner),
  // Staff
  for (final path in [
    AppRoutes.staffDashboard,
    AppRoutes.staffCourses,
    AppRoutes.staffCoursePattern,
    AppRoutes.staffCurriculumPattern,
    AppRoutes.staffLessonPattern,
    AppRoutes.staffReview,
    AppRoutes.staffSubmissionsPattern,
    AppRoutes.staffSubmissionPattern,
    AppRoutes.staffQuizzes,
    AppRoutes.staffQuizPattern,
    AppRoutes.staffStudents,
    AppRoutes.staffStudentPattern,
    AppRoutes.staffLive,
    AppRoutes.staffLiveNew,
    AppRoutes.staffLiveClassPattern,
    AppRoutes.staffLiveEditPattern,
    AppRoutes.staffCalendar,
    AppRoutes.staffCalendarNew,
    AppRoutes.staffEventPattern,
    AppRoutes.staffEventEditPattern,
    AppRoutes.staffNotifications,
    AppRoutes.staffNotificationPreferences,
    AppRoutes.staffNotificationPattern,
    AppRoutes.staffProfile,
    AppRoutes.staffProfileSettings,
    AppRoutes.staffHelp,
  ])
    _RoutePattern(path, AppSection.staff),
  // Also the staff shell; the capability decides who may open them.
  for (final path in [
    AppRoutes.staffInstructors,
    AppRoutes.staffInstructorInvite,
    AppRoutes.staffInstructorPattern,
    AppRoutes.staffCertificates,
    AppRoutes.staffCertificatePattern,
    AppRoutes.staffReports,
    AppRoutes.staffReportsCourses,
    AppRoutes.staffReportsCoursePattern,
    AppRoutes.staffReportsLearners,
    AppRoutes.staffReportsInstructors,
    AppRoutes.staffReportsEnrolments,
    AppRoutes.staffBilling,
    AppRoutes.staffBillingPlans,
    AppRoutes.staffInvoicePattern,
    AppRoutes.staffGetStarted,
  ])
    _RoutePattern(path, AppSection.staff),
];

/// The capability a staff route needs, mirroring the guard on the backend route it reads
/// (verified against `apps/api/src/routes/*.ts`; see progress.md FLUTTER-006). A route with none
/// is open to any staff member — the server still scopes what it returns.
Capability? requiredCapability(String path) {
  final location = Uri.parse(path).path;
  bool at(String pattern) => _RoutePattern(pattern, AppSection.staff).matches(location);

  // `GET /dashboard` itself is guarded by `reports.view`.
  if (at(AppRoutes.staffDashboard)) return Capability.viewReports;
  if (at(AppRoutes.staffInstructorInvite)) return Capability.manageInstructors;
  if (at(AppRoutes.staffReportsInstructors)) return Capability.viewInstructorReport;
  if (location.startsWith('/staff/billing')) return Capability.viewBilling;
  // Onboarding reads the plans on sale from `/tenant/billing`.
  if (at(AppRoutes.staffGetStarted)) return Capability.viewBilling;
  if (location.startsWith('/staff/reports')) return Capability.viewReports;
  if (location.startsWith('/staff/instructors')) return Capability.viewInstructors;
  if (location.startsWith('/staff/certificates')) return Capability.issueCertificates;
  if (location.startsWith('/staff/students')) return Capability.viewLearners;
  if (location.startsWith('/staff/courses')) return Capability.viewCourses;
  if (location.startsWith('/staff/quizzes')) return Capability.viewAssessments;
  if (location.startsWith('/staff/review') ||
      location.startsWith('/staff/assignments') ||
      location.startsWith('/staff/submissions')) {
    return Capability.viewAssessments;
  }
  // Scheduling a class and editing one are `POST /live` and `PATCH /live/:id`, both behind
  // `live.manage`; an admin without it is not offered a form the academy would refuse to save.
  if (at(AppRoutes.staffLiveNew) || at(AppRoutes.staffLiveEditPattern)) {
    return Capability.manageLive;
  }
  // The schedule, a class and the calendar are role-gated only on the backend; the actions inside
  // them (start, remind) are what need `live.manage` / `live.notify`.
  return null;
}

/// The plan-gated module a staff route belongs to (`WorkspaceModule`), or null for a route no plan
/// feature governs. Every page below a module's root is the module's too — a course's curriculum,
/// a submission, a live class's edit form.
WorkspaceModule? moduleOf(String path) {
  final location = Uri.parse(path).path;
  bool under(String root) => location == root || location.startsWith('$root/');

  if (under(AppRoutes.staffCourses)) return WorkspaceModule.courses;
  if (under(AppRoutes.staffQuizzes)) return WorkspaceModule.quizzes;
  if (under(AppRoutes.staffReview) || under('/staff/assignments') || under('/staff/submissions')) {
    return WorkspaceModule.assignments;
  }
  if (under(AppRoutes.staffCertificates)) return WorkspaceModule.certificates;
  if (under(AppRoutes.staffLive)) return WorkspaceModule.live;
  if (under(AppRoutes.staffReports)) return WorkspaceModule.reports;
  return null;
}

/// The section [path] belongs to, or null when the app has no such route. Longer, more specific
/// patterns win, so `/staff/instructors/invite` is admin-only rather than a generic staff route.
AppSection? sectionOf(String path) {
  final location = Uri.parse(path).path;
  _RoutePattern? best;
  for (final route in _routes) {
    if (!route.matches(location)) continue;
    if (best == null || route.pattern.length > best.pattern.length) best = route;
  }
  return best?.section;
}

/// Whether the app has this route at all — used for deep links and for the `next` parameter, so a
/// link can never send the app somewhere it does not own (§5.1, §18).
bool isKnownAppRoute(String path) {
  if (!path.startsWith('/') || path.startsWith('//')) return false;
  return sectionOf(path) != null;
}

/// Where a signed-in person starts, by role.
String homeFor(UserRole role) => switch (role) {
  UserRole.student => AppRoutes.home,
  UserRole.instructor || UserRole.admin => AppRoutes.staffDashboard,
  UserRole.superadmin || UserRole.unknown => AppRoutes.unsupportedRole,
};

/// Whether [role] belongs in [section] — which shell, not which screen.
bool canSee(UserRole role, AppSection section) => switch (section) {
  AppSection.public => true,
  AppSection.learner => role == UserRole.student,
  AppSection.staff => role == UserRole.instructor || role == UserRole.admin,
};

/// Whether [profile] may open [path]: the right shell, and the capability its backend route asks
/// for. UX only — every screen still handles the server's refusal (§7).
bool canOpen(UserProfile profile, String path) {
  final section = sectionOf(path);
  if (section == null) return true; // Unknown paths fall through to the not-found screen.
  if (!canSee(profile.role, section)) return false;
  final capability = requiredCapability(path);
  return capability == null || can(profile, capability);
}
