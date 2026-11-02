import '../../features/auth/auth.dart';
import 'route_access.dart';
import 'routes.dart';

/// Turns a **web** path the backend sent (`AppNotification.action.to`, dashboard `attention[].to`,
/// `events[].to`, learner `upcoming[].to`) into one of the app's own routes (§5.4).
///
/// Anything it does not recognise returns null and the app does not navigate: a notification can
/// carry a client-supplied path (`routes/notifications.ts` accepts `secondaryAction` unchecked), so
/// an unknown path is never followed and never opened in a web view (§18).
abstract final class WebPathMapper {
  /// [role] decides the shell: a learner's `/notifications` is the learner route, a staff member's
  /// the staff one.
  static String? map(String? webPath, UserRole role) {
    if (webPath == null || webPath.isEmpty || !webPath.startsWith('/')) return null;
    final uri = Uri.tryParse(webPath);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return null;

    final segments = uri.pathSegments;
    if (segments.isEmpty) return null;
    final query = uri.hasQuery ? uri.query : null;
    final staff = role == UserRole.instructor || role == UserRole.admin;

    final mapped = _mapSegments(segments, staff: staff, admin: role == UserRole.admin);
    if (mapped == null) return null;

    final target = query == null ? mapped : '$mapped?$query';
    // Never hand back something outside the app's own table, whatever the server sent.
    return isKnownAppRoute(target) ? target : null;
  }

  static String? _mapSegments(List<String> s, {required bool staff, required bool admin}) {
    final first = s.first;

    // `/teach/…` and `/admin/…` are the web's staff paths; both land in the staff shell.
    if (first == 'teach' || first == 'admin') {
      return _mapStaff(s.sublist(1), admin: admin);
    }

    return switch (s) {
      ['learn', final courseId] => AppRoutes.learnCourse(courseId),
      ['learn', final courseId, 'lessons', final lessonId] => AppRoutes.learnLesson(
        courseId,
        lessonId,
      ),
      ['my-learning'] => AppRoutes.myLearning(MyLearningTab.inProgress),
      ['my-learning', final tab] => AppRoutes.myLearning(MyLearningTab.parse(tab)),
      ['live'] => staff ? AppRoutes.staffLive : AppRoutes.live,
      ['live', final id] => staff ? AppRoutes.staffLiveClass(id) : AppRoutes.liveClass(id),
      ['assignments'] => staff ? AppRoutes.staffReview : AppRoutes.assignments,
      ['assignments', final id] =>
        staff ? AppRoutes.staffSubmissions(id) : AppRoutes.assignment(id),
      ['certificates'] => staff ? AppRoutes.staffCertificates : AppRoutes.certificates,
      ['certificates', final id] =>
        staff ? AppRoutes.staffCertificate(id) : AppRoutes.certificate(id),
      ['notifications'] => staff ? AppRoutes.staffNotifications : AppRoutes.notifications,
      ['notifications', 'preferences'] =>
        staff ? AppRoutes.staffNotificationPreferences : AppRoutes.notificationPreferences,
      ['notifications', final id] =>
        staff ? AppRoutes.staffNotification(id) : AppRoutes.notification(id),
      ['verify'] => AppRoutes.verify,
      ['verify', final credentialId] => AppRoutes.verifyCredential(credentialId),
      ['courses'] => staff ? AppRoutes.staffCourses : AppRoutes.catalog,
      // The web's public course page is by slug; the app's catalogue mirrors it.
      ['courses', final slug] =>
        staff ? AppRoutes.staffCourse(slug) : AppRoutes.catalogCourse(slug),
      ['reset-password', final token] => AppRoutes.resetPassword(token),
      ['help'] => staff ? AppRoutes.staffHelp : AppRoutes.help,
      ['help', 'article', final slug] => AppRoutes.helpArticle(slug),
      ['help', final categoryId] => AppRoutes.helpCategory(categoryId),
      ['explore'] => AppRoutes.explore,
      ['assessments'] => AppRoutes.assessments,
      ['ranks'] => AppRoutes.ranks,
      ['profile'] => staff ? AppRoutes.staffProfile : AppRoutes.profile,
      _ => null,
    };
  }

  /// The staff side of the web (`/teach/…`, `/admin/…`).
  static String? _mapStaff(List<String> s, {required bool admin}) {
    if (s.isEmpty) return AppRoutes.staffDashboard;
    return switch (s) {
      ['dashboard'] => AppRoutes.staffDashboard,
      ['assignments'] || ['assignments', 'review'] => AppRoutes.staffReview,
      // The web nests a submission under `/assignments/submissions/:id`.
      ['assignments', 'submissions', final submissionId] => AppRoutes.staffSubmission(submissionId),
      ['assignments', final assignmentId, 'submissions'] => AppRoutes.staffSubmissions(
        assignmentId,
      ),
      ['assignments', _, 'submissions', final submissionId] => AppRoutes.staffSubmission(
        submissionId,
      ),
      ['courses'] => AppRoutes.staffCourses,
      ['courses', final courseId] => AppRoutes.staffCourse(courseId),
      ['courses', final courseId, 'curriculum'] ||
      ['courses', final courseId, 'lessons'] => AppRoutes.staffCurriculum(courseId),
      ['courses', final courseId, 'lessons', final lessonId] => AppRoutes.staffLesson(
        courseId,
        lessonId,
      ),
      ['students'] => AppRoutes.staffStudents,
      ['students', final studentId] => AppRoutes.staffStudent(studentId),
      ['students', final studentId, ...] => AppRoutes.staffStudent(studentId),
      ['live'] => AppRoutes.staffLive,
      ['live', final liveId] => AppRoutes.staffLiveClass(liveId),
      ['calendar'] => AppRoutes.staffCalendar,
      ['calendar', final eventId] => AppRoutes.staffEvent(eventId),
      ['quizzes'] => AppRoutes.staffQuizzes,
      ['quizzes', final quizId] => AppRoutes.staffQuiz(quizId),
      ['notifications'] => AppRoutes.staffNotifications,
      ['notifications', 'preferences'] => AppRoutes.staffNotificationPreferences,
      ['notifications', final id] => AppRoutes.staffNotification(id),
      ['instructors'] => admin ? AppRoutes.staffInstructors : null,
      ['instructors', final instructorId] => admin ? AppRoutes.staffInstructor(instructorId) : null,
      ['certificates'] => admin ? AppRoutes.staffCertificates : null,
      ['certificates', final certificateId] =>
        admin ? AppRoutes.staffCertificate(certificateId) : null,
      ['reports'] => admin ? AppRoutes.staffReports : null,
      ['reports', 'courses'] => admin ? AppRoutes.staffReportsCourses : null,
      ['reports', 'courses', final courseId] =>
        admin ? AppRoutes.staffReportsCourse(courseId) : null,
      ['reports', 'learners'] => admin ? AppRoutes.staffReportsLearners : null,
      ['reports', 'instructors'] => admin ? AppRoutes.staffReportsInstructors : null,
      ['reports', 'enrolments'] => admin ? AppRoutes.staffReportsEnrolments : null,
      ['profile'] => AppRoutes.staffProfile,
      ['help'] => AppRoutes.staffHelp,
      _ => null,
    };
  }
}
