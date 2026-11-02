/// The app's route table (modules.md §5.3). Paths are `const`; every route with parameters has a
/// typed builder, so no feature ever concatenates a path.
abstract final class AppRoutes {
  // Public
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';

  /// Create account for the Admin's LMS a join link names.
  static String registerFor(String workspace) =>
      Uri(path: register, queryParameters: {'workspace': workspace}).toString();

  /// A learner invitation (`/invite/<token>`): join the Admin's LMS it names.
  static const invitePattern = '/invite/:token';

  /// A course link (`/courses/<id>/enroll` on the web): join the course's LMS and enrol.
  static const courseEnrolPattern = '/enrol/:courseId';
  static const forgotPassword = '/forgot-password';
  static const resetPasswordPattern = '/reset-password/:token';
  static const catalog = '/catalog';
  static const catalogCoursePattern = '/catalog/:slug';
  static const catalogPreviewPattern = '/catalog/:slug/preview/:lessonId';
  static const verify = '/verify';
  static const verifyCredentialPattern = '/verify/:credentialId';
  static const help = '/help';
  static const helpCategoryPattern = '/help/:categoryId';
  static const helpArticlePattern = '/help/article/:slug';
  static const privacy = '/legal/privacy';
  static const terms = '/legal/terms';
  static const unsupportedRole = '/unsupported-role';

  // Learner
  static const home = '/home';
  static const myLearningRoot = '/my-learning';
  static const myLearningPattern = '/my-learning/:tab';
  static const explore = '/explore';
  static const learnCoursePattern = '/learn/:courseId';
  static const learnLessonPattern = '/learn/:courseId/lessons/:lessonId';
  static const assignments = '/assignments';
  static const assignmentPattern = '/assignments/:assignmentId';
  static const assessments = '/assessments';
  static const live = '/live';
  static const liveClassPattern = '/live/:liveId';
  static const certificates = '/certificates';
  static const certificatePattern = '/certificates/:certificateId';
  static const ranks = '/ranks';
  static const notifications = '/notifications';
  static const notificationPreferences = '/notifications/preferences';
  static const notificationPattern = '/notifications/:notificationId';
  static const profile = '/profile';
  static const profileSettings = '/profile/settings';
  static const profileDeleteAccount = '/profile/delete-account';

  /// The courses the learner has bought (or tried to).
  static const profilePurchases = '/profile/purchases';

  // The pages Home's shortcuts open, held by the Home tab too: opened from Home they stay in it,
  // so Back returns to Home; opened from Profile or Tests they stay there (§5.5).
  static const homeMyLearningRoot = '/home/my-learning';
  static const homeMyLearningPattern = '/home/my-learning/:tab';
  static const homeAssignments = '/home/assignments';
  static const homeAssignmentPattern = '/home/assignments/:assignmentId';
  static const homeAssessments = '/home/assessments';
  static const homeCertificates = '/home/certificates';
  static const homeCertificatePattern = '/home/certificates/:certificateId';
  static const homeRanks = '/home/ranks';

  /// The roots of the pages the Home tab also holds.
  static const homeHeldRoots = [myLearningRoot, assignments, assessments, certificates, ranks];

  // Staff (instructor and academy admin share the shell; scope comes from the server)
  static const staffDashboard = '/staff';
  static const staffCourses = '/staff/courses';
  static const staffCoursePattern = '/staff/courses/:courseId';
  static const staffCurriculumPattern = '/staff/courses/:courseId/curriculum';
  static const staffLessonPattern = '/staff/courses/:courseId/lessons/:lessonId';
  static const staffReview = '/staff/review';
  static const staffSubmissionsPattern = '/staff/assignments/:assignmentId/submissions';
  static const staffSubmissionPattern = '/staff/submissions/:submissionId';
  static const staffQuizzes = '/staff/quizzes';
  static const staffQuizPattern = '/staff/quizzes/:quizId';
  static const staffStudents = '/staff/students';
  static const staffStudentPattern = '/staff/students/:studentId';
  static const staffLive = '/staff/live';
  static const staffLiveNew = '/staff/live/new';
  static const staffLiveClassPattern = '/staff/live/:liveId';
  static const staffLiveEditPattern = '/staff/live/:liveId/edit';
  static const staffCalendar = '/staff/calendar';
  static const staffCalendarNew = '/staff/calendar/new';
  static const staffEventPattern = '/staff/calendar/:eventId';
  static const staffEventEditPattern = '/staff/calendar/:eventId/edit';
  static const staffNotifications = '/staff/notifications';
  static const staffNotificationPreferences = '/staff/notifications/preferences';
  static const staffNotificationPattern = '/staff/notifications/:notificationId';
  static const staffProfile = '/staff/profile';
  static const staffProfileSettings = '/staff/profile/settings';
  static const staffHelp = '/staff/help';

  // Academy admin only (inside the staff shell)
  static const staffInstructors = '/staff/instructors';
  static const staffInstructorPattern = '/staff/instructors/:instructorId';
  static const staffInstructorInvite = '/staff/instructors/invite';
  static const staffInstructorEditPattern = '/staff/instructors/:instructorId/edit';
  static const staffCertificates = '/staff/certificates';
  static const staffCertificatePattern = '/staff/certificates/:certificateId';
  static const staffReports = '/staff/reports';
  static const staffReportsCourses = '/staff/reports/courses';
  static const staffReportsCoursePattern = '/staff/reports/courses/:courseId';
  static const staffReportsLearners = '/staff/reports/learners';
  static const staffReportsInstructors = '/staff/reports/instructors';
  static const staffReportsEnrolments = '/staff/reports/enrolments';
  static const staffBilling = '/staff/billing';
  static const staffInvoicePattern = '/staff/billing/invoices/:invoiceId';
  static const staffBillingPlans = '/staff/billing/plans';

  /// A brand-new academy's first stop: choose a plan or start the free trial (onboarding).
  static const staffGetStarted = '/staff/get-started';

  /* ── Typed builders ─────────────────────────────────────────────────── */

  /// [route] as the Home tab holds it (`/certificates` → `/home/certificates`). Only for a route
  /// under [homeHeldRoots].
  static String atHome(String route) => '$home$route';

  /// Where a link to [route] leads from the page at [location]: a page the Home tab holds keeps
  /// its links in Home when Home holds the target too (a certificate from Home's Certificates);
  /// anywhere else — and for every other target — [route] is used as it is.
  static String within(String location, String route) {
    if (!location.startsWith('$home/')) return route;
    final held = homeHeldRoots.any((root) => route == root || route.startsWith('$root/'));
    return held ? atHome(route) : route;
  }

  static String resetPassword(String token) => '/reset-password/${_seg(token)}';
  static String invite(String token) => '/invite/${_seg(token)}';
  static String courseEnrol(String courseId) => '/enrol/${_seg(courseId)}';
  static String catalogCourse(String slug) => '/catalog/${_seg(slug)}';
  static String catalogPreview(String slug, String lessonId) =>
      '/catalog/${_seg(slug)}/preview/${_seg(lessonId)}';
  static String verifyCredential(String credentialId) => '/verify/${_seg(credentialId)}';
  static String helpCategory(String categoryId) => '/help/${_seg(categoryId)}';
  static String helpArticle(String slug) => '/help/article/${_seg(slug)}';
  static String myLearning(MyLearningTab tab) => '/my-learning/${tab.slug}';
  static String learnCourse(String courseId) => '/learn/${_seg(courseId)}';
  static String learnLesson(String courseId, String lessonId) =>
      '/learn/${_seg(courseId)}/lessons/${_seg(lessonId)}';
  static String assignment(String assignmentId) => '/assignments/${_seg(assignmentId)}';
  static String liveClass(String liveId) => '/live/${_seg(liveId)}';
  static String certificate(String certificateId) => '/certificates/${_seg(certificateId)}';
  static String notification(String notificationId) => '/notifications/${_seg(notificationId)}';
  static String staffCourse(String courseId) => '/staff/courses/${_seg(courseId)}';
  static String staffCurriculum(String courseId) => '/staff/courses/${_seg(courseId)}/curriculum';
  static String staffLesson(String courseId, String lessonId) =>
      '/staff/courses/${_seg(courseId)}/lessons/${_seg(lessonId)}';
  static String staffSubmissions(String assignmentId) =>
      '/staff/assignments/${_seg(assignmentId)}/submissions';
  static String staffSubmission(String submissionId) => '/staff/submissions/${_seg(submissionId)}';
  static String staffQuiz(String quizId) => '/staff/quizzes/${_seg(quizId)}';
  static String staffStudent(String studentId) => '/staff/students/${_seg(studentId)}';
  static String staffLiveClass(String liveId) => '/staff/live/${_seg(liveId)}';
  static String staffLiveEdit(String liveId) => '/staff/live/${_seg(liveId)}/edit';
  static String staffEvent(String eventId) => '/staff/calendar/${_seg(eventId)}';
  static String staffEventEdit(String eventId) => '/staff/calendar/${_seg(eventId)}/edit';
  static String staffNotification(String id) => '/staff/notifications/${_seg(id)}';
  static String staffInstructor(String instructorId) => '/staff/instructors/${_seg(instructorId)}';
  static String staffInstructorEdit(String instructorId) =>
      '/staff/instructors/${_seg(instructorId)}/edit';
  static String staffCertificate(String certificateId) =>
      '/staff/certificates/${_seg(certificateId)}';
  static String staffReportsCourse(String courseId) => '/staff/reports/courses/${_seg(courseId)}';
  static String staffInvoice(String invoiceId) => '/staff/billing/invoices/${_seg(invoiceId)}';

  static String _seg(String value) => Uri.encodeComponent(value);
}

/// The tabs of My Learning (§5.3).
enum MyLearningTab {
  inProgress('in-progress'),
  completed('completed'),
  saved('saved');

  const MyLearningTab(this.slug);

  final String slug;

  static MyLearningTab parse(String? slug) => MyLearningTab.values.firstWhere(
    (t) => t.slug == slug,
    orElse: () => MyLearningTab.inProgress,
  );
}
