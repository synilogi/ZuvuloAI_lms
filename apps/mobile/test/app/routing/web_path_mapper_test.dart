import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/routing/route_access.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/app/routing/web_path_mapper.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';

/// Every web path the backend emits today, read out of `apps/api/src` (notification `action.to`,
/// dashboard `attention[].to` / `events[].to`, learner `upcoming[].to`, instructor events and the
/// e-mail links). If the backend adds one, this list gets a row and the mapper a case.
void main() {
  String? forLearner(String path) => WebPathMapper.map(path, UserRole.student);
  String? forInstructor(String path) => WebPathMapper.map(path, UserRole.instructor);
  String? forAdmin(String path) => WebPathMapper.map(path, UserRole.admin);

  group('learner paths', () {
    const cases = {
      // lib/calendarEvents.ts, lib/notificationJobs.ts, routes/learning.ts
      '/learn/c1': '/learn/c1',
      '/learn/c1/lessons/l2': '/learn/c1/lessons/l2',
      // routes/students.ts (bulk message)
      '/my-learning': '/my-learning/in-progress',
      '/my-learning/completed': '/my-learning/completed',
      // lib/liveEvents.ts, routes/learning.ts
      '/live': '/live',
      '/live/lc1': '/live/lc1',
      // routes/assignments.ts, lib/notificationJobs.ts
      '/assignments/a1': '/assignments/a1',
      // lib/certificates.ts, routes/certificates.ts
      '/certificates/ic1': '/certificates/ic1',
      // routes/certificates.ts (verifyUrl) and the revoked-certificate notice
      '/verify/SYN-7F3K': '/verify/SYN-7F3K',
      '/help': '/help',
      // lib/notificationJobs.ts digest footer
      '/notifications/preferences': '/notifications/preferences',
      // routes/auth.ts, routes/instructors.ts e-mail links
      '/reset-password/0123456789abcdef': '/reset-password/0123456789abcdef',
    };

    cases.forEach((webPath, appRoute) {
      test('$webPath → $appRoute', () => expect(forLearner(webPath), appRoute));
    });
  });

  group('staff paths — /teach for an instructor, /admin for an academy admin', () {
    const shared = {
      // lib/notificationJobs.ts, routes/learning.ts
      'assignments/submissions/s1': '/staff/submissions/s1',
      // dashboard.ts attention[], instructors.ts events[]
      'assignments/review': '/staff/review',
      'assignments': '/staff/review',
      // dashboard.ts attention[] (at-risk learners), notificationJobs.ts (daily enrolments)
      'students': '/staff/students',
      // dashboard.ts attention[]/events[], instructors.ts events[], routes/courses.ts
      'courses/c1': '/staff/courses/c1',
      'courses/c1/lessons': '/staff/courses/c1/curriculum',
      'courses/c1/curriculum': '/staff/courses/c1/curriculum',
      'live/lc1': '/staff/live/lc1',
      'courses': '/staff/courses',
    };

    shared.forEach((suffix, appRoute) {
      test('/teach/$suffix and /admin/$suffix → $appRoute', () {
        expect(forInstructor('/teach/$suffix'), appRoute);
        expect(forAdmin('/admin/$suffix'), appRoute);
      });
    });

    test('query strings the backend adds are kept', () {
      expect(forInstructor('/teach/students?courseId=c1'), '/staff/students?courseId=c1');
      expect(forAdmin('/admin/students?status=at-risk'), '/staff/students?status=at-risk');
      expect(forAdmin('/admin/courses?status=archived'), '/staff/courses?status=archived');
    });

    test('admin-only targets are refused for an instructor', () {
      // routes/dashboard.ts emits these only in academy scope.
      expect(forAdmin('/admin/certificates/ic1'), '/staff/certificates/ic1');
      expect(forAdmin('/admin/instructors/i1'), '/staff/instructors/i1');
      expect(forAdmin('/admin/reports/enrolments'), '/staff/reports/enrolments');
      expect(forInstructor('/teach/certificates/ic1'), isNull);
      expect(forInstructor('/teach/instructors/i1'), isNull);
      expect(forInstructor('/teach/reports/enrolments'), isNull);
    });

    test('billing paths lead nowhere: billing is retired', () {
      expect(forAdmin('/admin/billing'), isNull);
      expect(forAdmin('/admin/billing/plans'), isNull);
      expect(forAdmin('/admin/billing/invoices/inv1'), isNull);
      expect(forInstructor('/teach/billing'), isNull);
    });
  });

  group('the shell follows the role', () {
    test('notifications, live and help land in the right shell', () {
      expect(forLearner('/notifications'), AppRoutes.notifications);
      expect(forInstructor('/notifications'), AppRoutes.staffNotifications);
      expect(forAdmin('/notifications/preferences'), AppRoutes.staffNotificationPreferences);
      expect(forInstructor('/live/lc1'), AppRoutes.staffLiveClass('lc1'));
      expect(forInstructor('/help'), AppRoutes.staffHelp);
    });
  });

  group('anything else is never navigated', () {
    const refused = [
      // Media URLs are content, not routes (routes/media.ts).
      '/media/m1',
      // A notification may carry a client-supplied path (routes/notifications.ts import endpoint).
      '/superadmin/tenants',
      '/admin/settings',
      '/teach/unknown-area',
      'https://evil.example/home',
      '//evil.example',
      'relative/path',
      '',
    ];

    for (final path in refused) {
      test('"$path" → null', () {
        expect(forLearner(path), isNull);
        expect(forAdmin(path), isNull);
      });
    }

    test('null is handled', () => expect(WebPathMapper.map(null, UserRole.student), isNull));
  });

  test('every mapped route is a route the app actually has', () {
    const everyWebPath = [
      '/learn/c1',
      '/learn/c1/lessons/l2',
      '/my-learning',
      '/live',
      '/live/lc1',
      '/assignments/a1',
      '/certificates/ic1',
      '/verify/SYN-1',
      '/help',
      '/notifications/preferences',
      '/reset-password/tok',
      '/teach/assignments/submissions/s1',
      '/teach/assignments/review',
      '/teach/students?courseId=c1',
      '/teach/courses/c1',
      '/teach/courses/c1/lessons',
      '/teach/live/lc1',
      '/admin/reports/enrolments',
      '/admin/courses?status=archived',
      '/admin/certificates/ic1',
      '/admin/instructors/i1',
    ];
    for (final role in [UserRole.student, UserRole.instructor, UserRole.admin]) {
      for (final path in everyWebPath) {
        final mapped = WebPathMapper.map(path, role);
        if (mapped == null) continue;
        expect(isKnownAppRoute(mapped), isTrue, reason: '$path → $mapped for ${role.name}');
      }
    }
  });
}
