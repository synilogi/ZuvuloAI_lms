import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/links/deep_link.dart';
import '../../features/assessments/assessments.dart';
import '../../features/assignments/assignments.dart';
import '../../features/auth/auth.dart';
import '../../features/certificates/certificates.dart';
import '../../features/course_learning/course_learning.dart';
import '../../features/course_purchase/course_purchase.dart' show PurchasesScreen;
import '../../features/explore/explore.dart';
import '../../features/help/help.dart';
import '../../features/learner_home/learner_home.dart';
import '../../features/live/live.dart';
import '../../features/notifications/notifications.dart';
import '../../features/profile/profile.dart';
import '../../features/public_catalog/public_catalog.dart';
import '../../features/staff_billing/staff_billing.dart';
import '../../features/staff_calendar/staff_calendar.dart';
import '../../features/staff_certificates/staff_certificates.dart';
import '../../features/staff_courses/staff_courses.dart';
import '../../features/staff_dashboard/staff_dashboard.dart';
import '../../features/staff_instructors/staff_instructors.dart';
import '../../features/staff_live/staff_live.dart';
import '../../features/staff_quizzes/staff_quizzes.dart';
import '../../features/staff_reports/staff_reports.dart';
import '../../features/staff_review/staff_review.dart';
import '../../features/staff_students/staff_students.dart';
import '../../features/verify/verify.dart';
import '../../l10n/l10n.dart';
import '../../shared/entitlements/entitlements.dart';
import 'nav_history.dart';
import 'redirect.dart';
import 'route_access.dart';
import 'routes.dart';
import 'shells/app_shell.dart';
import 'shells/destinations.dart';

/// Rebuilds the router's redirect whenever the session changes (§5.1).
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(this._ref) {
    _ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      if (previous.runtimeType != next.runtimeType || previous?.user?.id != next.user?.id) {
        // Bring the derived current user up to date now, outside any build. Left dirty, it is
        // first recomputed when the new shell watches it mid-build, and the providers that depend
        // on it (the academy plan, help audience) then schedule a refresh during that build —
        // "setState() or markNeedsBuild() called during build" right after sign-in.
        // Deferred to a microtask (still before the next frame): this listener subscribed before
        // the current user did, so read now it would return the stale value and only then be
        // marked dirty.
        scheduleMicrotask(() => _ref.read(currentUserProvider));
        notifyListeners();
      }
    });
  }

  final Ref _ref;
}

/// Developer-only routes, provided by `main_dev.dart` alone, so they are not compiled into
/// staging or prod builds.
final devRoutesProvider = Provider<Map<String, WidgetBuilder>>((ref) => const {});

/// The app's router (§5): the route table, one session-driven redirect, and the two role shells.
/// Screens a later module builds show a neutral placeholder in dev; the rest of the table is real.
final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _SessionListenable(ref);
  ref.onDispose(listenable.dispose);
  // A link the app was opened with survives the session restore (§5.4, FLUTTER-028).
  final resume = LinkResume();
  final showUnbuilt = ref.watch(appConfigProvider).isDev;

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: listenable,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final location = state.uri.toString();
      return resume.follow(session: session, location: location);
    },
    errorBuilder: (context, state) => NotFoundScreen(
      home: homeFor(ref.read(sessionControllerProvider).user?.role ?? UserRole.unknown),
    ),
    routes: [
      /* ── Public ─────────────────────────────────────────────────────── */
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => WelcomeScreen(
          next: state.uri.queryParameters['next'],
          onBrowseCourses: () => GoRouter.of(context).go(AppRoutes.catalog),
          onVerifyCertificate: () => GoRouter.of(context).go(AppRoutes.verify),
          onOpenHelp: () => GoRouter.of(context).go(AppRoutes.help),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginScreen(
          message: _signedOutMessage(context, ref),
          next: state.uri.queryParameters['next'],
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        // A teaching link (`/join/<address>/teach`) opens the instructor's form for that LMS.
        builder: (context, state) => state.uri.queryParameters['as'] == registerAsInstructor
            ? InstructorSignupScreen(workspace: state.uri.queryParameters['workspace'])
            : RegisterScreen(
                next: state.uri.queryParameters['next'],
                workspace: state.uri.queryParameters['workspace'],
              ),
      ),
      // The links an Admin sends learners: an invitation and a course link. Both are public, and each
      // screen handles someone already being signed in itself.
      GoRoute(
        path: AppRoutes.invitePattern,
        builder: (_, state) => InvitationScreen(token: state.pathParameters['token'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.courseEnrolPattern,
        builder: (_, state) => CourseEnrolScreen(courseId: state.pathParameters['courseId'] ?? ''),
      ),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(
        path: AppRoutes.resetPasswordPattern,
        builder: (context, state) =>
            ResetPasswordScreen(token: state.pathParameters['token'] ?? ''),
      ),
      GoRoute(path: AppRoutes.catalog, builder: (_, _) => const CatalogScreen()),
      GoRoute(
        path: AppRoutes.catalogCoursePattern,
        builder: (_, state) => CourseDetailScreen(slug: state.pathParameters['slug'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.catalogPreviewPattern,
        builder: (_, state) => PreviewLessonScreen(
          slug: state.pathParameters['slug'] ?? '',
          lessonId: state.pathParameters['lessonId'] ?? '',
        ),
      ),
      GoRoute(path: AppRoutes.verify, builder: (_, _) => const VerifyScreen()),
      GoRoute(
        path: AppRoutes.verifyCredentialPattern,
        builder: (_, state) =>
            VerifyResultScreen(credentialId: state.pathParameters['credentialId'] ?? ''),
      ),
      GoRoute(path: AppRoutes.help, builder: (_, _) => const HelpHubScreen()),
      // Declared before the category route: `/help/article/<slug>` is not a category id.
      GoRoute(
        path: AppRoutes.helpArticlePattern,
        builder: (_, state) => HelpArticleScreen(slug: state.pathParameters['slug'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.helpCategoryPattern,
        builder: (_, state) =>
            HelpCategoryScreen(categoryId: state.pathParameters['categoryId'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (_, _) => const LegalScreen(document: LegalDocument.privacy),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (_, _) => const LegalScreen(document: LegalDocument.terms),
      ),
      GoRoute(path: AppRoutes.unsupportedRole, builder: (_, _) => const UnsupportedRoleScreen()),
      // Retired with plans: `redirectFor` sends this path home, as it does `/staff/billing*`.
      GoRoute(path: AppRoutes.staffGetStarted, builder: (_, _) => const ChoosePlanScreen()),
      for (final entry in ref.watch(devRoutesProvider).entries)
        GoRoute(path: entry.key, builder: (context, _) => entry.value(context)),

      /* ── Learner shell ──────────────────────────────────────────────── */
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          navigationShell: navigationShell,
          layout: learnerLayout(),
          notificationsRoute: AppRoutes.notifications,
          profileRoute: AppRoutes.profile,
          showUnbuilt: showUnbuilt,
        ),
        branches: [
          // Home, the notifications its bell opens, and the pages its shortcuts open — held here
          // as well as in their own tabs, so Back from them returns to Home.
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.home, builder: (_, _) => const LearnerHomeScreen()),
              GoRoute(
                path: AppRoutes.homeMyLearningRoot,
                redirect: (_, _) =>
                    AppRoutes.atHome(AppRoutes.myLearning(MyLearningTab.inProgress)),
              ),
              GoRoute(
                path: AppRoutes.homeMyLearningPattern,
                builder: (_, state) =>
                    MyLearningScreen(tab: MyLearningTab.parse(state.pathParameters['tab'])),
              ),
              GoRoute(
                path: AppRoutes.homeAssessments,
                builder: (_, _) => const TestsScreen(segment: TestsSegment.tests),
              ),
              GoRoute(
                path: AppRoutes.homeAssignments,
                builder: (_, _) => const TestsScreen(segment: TestsSegment.assignments),
              ),
              GoRoute(
                path: AppRoutes.homeAssignmentPattern,
                builder: (_, state) => AssignmentDetailScreen(
                  assignmentId: state.pathParameters['assignmentId'] ?? '',
                ),
              ),
              GoRoute(
                path: AppRoutes.homeCertificates,
                builder: (_, _) => const CertificatesScreen(),
              ),
              GoRoute(
                path: AppRoutes.homeCertificatePattern,
                builder: (_, state) => CertificateDetailScreen(
                  certificateId: state.pathParameters['certificateId'] ?? '',
                ),
              ),
              GoRoute(path: AppRoutes.homeRanks, builder: (_, _) => const RanksScreen()),
              GoRoute(
                path: AppRoutes.notifications,
                builder: (_, _) => const NotificationsScreen(),
              ),
              // Declared before the pattern: `preferences` is not a notification id.
              GoRoute(
                path: AppRoutes.notificationPreferences,
                builder: (_, _) => const NotificationPreferencesScreen(),
              ),
              GoRoute(
                path: AppRoutes.notificationPattern,
                builder: (_, state) => NotificationDetailScreen(
                  notificationId: state.pathParameters['notificationId'] ?? '',
                ),
              ),
            ],
          ),
          // Courses: the academy's catalogue, and each course and lesson.
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.explore, builder: (_, _) => const ExploreScreen()),
              GoRoute(
                path: AppRoutes.learnCoursePattern,
                builder: (_, state) =>
                    CourseOverviewScreen(courseId: state.pathParameters['courseId'] ?? ''),
              ),
              GoRoute(
                path: AppRoutes.learnLessonPattern,
                builder: (_, state) => LessonPlayerScreen(
                  courseId: state.pathParameters['courseId'] ?? '',
                  lessonId: state.pathParameters['lessonId'] ?? '',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.live, builder: (_, _) => const LiveScreen()),
              GoRoute(
                path: AppRoutes.liveClassPattern,
                builder: (_, state) =>
                    LiveDetailScreen(liveClassId: state.pathParameters['liveId'] ?? ''),
              ),
            ],
          ),
          // Tests: quizzes and assignments, side by side.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.assessments,
                builder: (_, _) => const TestsScreen(segment: TestsSegment.tests),
              ),
              GoRoute(
                path: AppRoutes.assignments,
                builder: (_, _) => const TestsScreen(segment: TestsSegment.assignments),
              ),
              GoRoute(
                path: AppRoutes.assignmentPattern,
                builder: (_, state) => AssignmentDetailScreen(
                  assignmentId: state.pathParameters['assignmentId'] ?? '',
                ),
              ),
            ],
          ),
          // Profile: the account, the learner's own courses, and what they have earned.
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileScreen()),
              // My Courses, opened from Profile. The bare path opens its first tab.
              GoRoute(
                path: AppRoutes.myLearningRoot,
                redirect: (_, _) => AppRoutes.myLearning(MyLearningTab.inProgress),
              ),
              GoRoute(
                path: AppRoutes.myLearningPattern,
                builder: (_, state) =>
                    MyLearningScreen(tab: MyLearningTab.parse(state.pathParameters['tab'])),
              ),
              GoRoute(
                path: AppRoutes.profileSettings,
                builder: (_, _) => const AppSettingsScreen(),
              ),
              GoRoute(
                path: AppRoutes.profileDeleteAccount,
                builder: (_, _) => const DeleteAccountScreen(),
              ),
              GoRoute(path: AppRoutes.profilePurchases, builder: (_, _) => const PurchasesScreen()),
              GoRoute(path: AppRoutes.certificates, builder: (_, _) => const CertificatesScreen()),
              GoRoute(
                path: AppRoutes.certificatePattern,
                builder: (_, state) => CertificateDetailScreen(
                  certificateId: state.pathParameters['certificateId'] ?? '',
                ),
              ),
              GoRoute(path: AppRoutes.ranks, builder: (_, _) => const RanksScreen()),
            ],
          ),
        ],
      ),

      /* ── Staff shell (instructor and academy admin) ─────────────────── */
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          navigationShell: navigationShell,
          layout: staffLayout(
            ref.read(sessionControllerProvider).user?.role ?? UserRole.instructor,
          ),
          notificationsRoute: AppRoutes.staffNotifications,
          profileRoute: AppRoutes.staffProfile,
          showUnbuilt: showUnbuilt,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.staffDashboard,
                builder: (_, _) => const StaffDashboardScreen(),
              ),
              GoRoute(
                path: AppRoutes.staffCalendar,
                builder: (_, _) => const StaffCalendarScreen(),
              ),
              GoRoute(
                path: AppRoutes.staffCalendarNew,
                builder: (_, _) => const CalendarFormScreen(),
              ),
              GoRoute(
                path: AppRoutes.staffEventPattern,
                builder: (_, state) =>
                    CalendarEventScreen(eventId: state.pathParameters['eventId'] ?? ''),
              ),
              GoRoute(
                path: AppRoutes.staffEventEditPattern,
                builder: (_, state) =>
                    CalendarFormScreen(eventId: state.pathParameters['eventId'] ?? ''),
              ),
              GoRoute(
                path: AppRoutes.staffNotifications,
                builder: (_, _) => const NotificationsScreen(),
              ),
              GoRoute(
                path: AppRoutes.staffNotificationPreferences,
                builder: (_, _) => const NotificationPreferencesScreen(),
              ),
              GoRoute(
                path: AppRoutes.staffNotificationPattern,
                builder: (_, state) => NotificationDetailScreen(
                  notificationId: state.pathParameters['notificationId'] ?? '',
                ),
              ),
              GoRoute(path: AppRoutes.staffProfile, builder: (_, _) => const ProfileScreen()),
              GoRoute(
                path: AppRoutes.staffProfileSettings,
                builder: (_, _) => const AppSettingsScreen(),
              ),
              // The help centre is the same for everyone; a staff member reaches it inside their
              // own shell rather than being sent out to the public route (FLUTTER-017).
              GoRoute(path: AppRoutes.staffHelp, builder: (_, _) => const HelpHubScreen()),
              GoRoute(
                path: AppRoutes.staffInstructors,
                builder: (_, _) => const InstructorsScreen(),
              ),
              // Before the `:instructorId` pattern, so "invite" is never read as an id.
              GoRoute(
                path: AppRoutes.staffInstructorInvite,
                builder: (_, _) => const InstructorFormScreen(),
              ),
              GoRoute(
                path: AppRoutes.staffInstructorPattern,
                builder: (_, state) =>
                    InstructorScreen(instructorId: state.pathParameters['instructorId'] ?? ''),
              ),
              GoRoute(
                path: AppRoutes.staffInstructorEditPattern,
                builder: (_, state) =>
                    InstructorFormScreen(instructorId: state.pathParameters['instructorId'] ?? ''),
              ),
              GoRoute(
                path: AppRoutes.staffCertificates,
                builder: (_, _) => const PlanGate(
                  module: WorkspaceModule.certificates,
                  child: CertificatesRegisterScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.staffCertificatePattern,
                builder: (_, state) => PlanGate(
                  module: WorkspaceModule.certificates,
                  child: StaffCertificateScreen(
                    certificateId: state.pathParameters['certificateId'] ?? '',
                  ),
                ),
              ),
              GoRoute(
                path: AppRoutes.staffReports,
                builder: (_, _) =>
                    const PlanGate(module: WorkspaceModule.reports, child: ReportsOverviewScreen()),
              ),
              GoRoute(
                path: AppRoutes.staffReportsCourses,
                builder: (_, _) =>
                    const PlanGate(module: WorkspaceModule.reports, child: CoursesReportScreen()),
              ),
              GoRoute(
                path: AppRoutes.staffReportsCoursePattern,
                builder: (_, state) => PlanGate(
                  module: WorkspaceModule.reports,
                  child: CourseReportScreen(courseId: state.pathParameters['courseId'] ?? ''),
                ),
              ),
              GoRoute(
                path: AppRoutes.staffReportsLearners,
                builder: (_, _) =>
                    const PlanGate(module: WorkspaceModule.reports, child: LearnersReportScreen()),
              ),
              GoRoute(
                path: AppRoutes.staffReportsInstructors,
                builder: (_, _) => const PlanGate(
                  module: WorkspaceModule.reports,
                  child: InstructorsReportScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.staffReportsEnrolments,
                builder: (_, _) => const PlanGate(
                  module: WorkspaceModule.reports,
                  child: EnrolmentsReportScreen(),
                ),
              ),
              GoRoute(path: AppRoutes.staffBilling, builder: (_, _) => const BillingScreen()),
              // Before the invoice pattern, so "plans" is never read as an invoice id.
              GoRoute(path: AppRoutes.staffBillingPlans, builder: (_, _) => const PlansScreen()),
              GoRoute(
                path: AppRoutes.staffInvoicePattern,
                builder: (_, state) =>
                    InvoiceScreen(invoiceId: state.pathParameters['invoiceId'] ?? ''),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.staffReview,
                builder: (_, _) =>
                    const PlanGate(module: WorkspaceModule.assignments, child: ReviewQueueScreen()),
              ),
              GoRoute(
                path: AppRoutes.staffSubmissionsPattern,
                builder: (_, state) => PlanGate(
                  module: WorkspaceModule.assignments,
                  child: AssignmentSubmissionsScreen(
                    assignmentId: state.pathParameters['assignmentId'] ?? '',
                  ),
                ),
              ),
              GoRoute(
                path: AppRoutes.staffSubmissionPattern,
                builder: (_, state) => PlanGate(
                  module: WorkspaceModule.assignments,
                  child: SubmissionReviewScreen(
                    submissionId: state.pathParameters['submissionId'] ?? '',
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.staffCourses,
                builder: (_, _) =>
                    const PlanGate(module: WorkspaceModule.courses, child: StaffCoursesScreen()),
              ),
              GoRoute(
                path: AppRoutes.staffCoursePattern,
                builder: (_, state) => PlanGate(
                  module: WorkspaceModule.courses,
                  child: StaffCourseScreen(courseId: state.pathParameters['courseId'] ?? ''),
                ),
              ),
              GoRoute(
                path: AppRoutes.staffCurriculumPattern,
                builder: (_, state) => PlanGate(
                  module: WorkspaceModule.courses,
                  child: CourseCurriculumScreen(courseId: state.pathParameters['courseId'] ?? ''),
                ),
              ),
              GoRoute(
                path: AppRoutes.staffLessonPattern,
                builder: (_, state) => PlanGate(
                  module: WorkspaceModule.courses,
                  child: StaffLessonScreen(
                    courseId: state.pathParameters['courseId'] ?? '',
                    lessonId: state.pathParameters['lessonId'] ?? '',
                  ),
                ),
              ),
              GoRoute(
                path: AppRoutes.staffQuizzes,
                builder: (_, _) =>
                    const PlanGate(module: WorkspaceModule.quizzes, child: StaffQuizzesScreen()),
              ),
              GoRoute(
                path: AppRoutes.staffQuizPattern,
                builder: (_, state) => PlanGate(
                  module: WorkspaceModule.quizzes,
                  child: StaffQuizScreen(quizId: state.pathParameters['quizId'] ?? ''),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.staffLive,
                builder: (_, _) =>
                    const PlanGate(module: WorkspaceModule.live, child: StaffLiveScreen()),
              ),
              GoRoute(
                path: AppRoutes.staffLiveNew,
                builder: (_, _) =>
                    const PlanGate(module: WorkspaceModule.live, child: LiveFormScreen()),
              ),
              GoRoute(
                path: AppRoutes.staffLiveClassPattern,
                builder: (_, state) => PlanGate(
                  module: WorkspaceModule.live,
                  child: StaffLiveClassScreen(liveId: state.pathParameters['liveId'] ?? ''),
                ),
              ),
              GoRoute(
                path: AppRoutes.staffLiveEditPattern,
                builder: (_, state) => PlanGate(
                  module: WorkspaceModule.live,
                  child: LiveFormScreen(liveId: state.pathParameters['liveId'] ?? ''),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.staffStudents, builder: (_, _) => const StudentsScreen()),
              GoRoute(
                path: AppRoutes.staffStudentPattern,
                builder: (_, state) =>
                    StudentScreen(studentId: state.pathParameters['studentId'] ?? ''),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  // Back returns to where a page was opened from (§5.5): the history listens from the start.
  NavHistory.of(router);
  return router;
});

/// The sign-in screen explains why someone is there when the session ended or was refused (§6).
String? _signedOutMessage(BuildContext context, Ref ref) {
  final session = ref.read(sessionControllerProvider);
  if (session is! SessionSignedOut) return null;
  return switch (session.reason) {
    SignedOutReason.none || SignedOutReason.signedOut => null,
    SignedOutReason.expired => context.l10n.sessionEndedMessage,
    SignedOutReason.refused => session.message,
    SignedOutReason.deleted => context.l10n.deleteAccountDoneMessage,
  };
}
