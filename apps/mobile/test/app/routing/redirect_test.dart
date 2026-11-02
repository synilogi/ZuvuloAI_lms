import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/routing/redirect.dart';
import 'package:syniastrolms_mobile/app/routing/route_access.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/core/auth/capabilities.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/links/deep_link.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/shared/entitlements/dto/entitlements.dart';

/// A reset token the academy would issue: 64 hex characters, as `randomBytes(32).toString('hex')`
/// produces and `findUsableToken` insists on.
const _realToken = '3f9a1c7e20b84d65af0e2d19c8b73540e6a92f14bc385d70a1fe6b29d4c80713';

UserProfile _profile(UserRole role, {List<PermissionKey> permissions = const []}) => UserProfile(
  id: 'u1',
  name: 'A',
  email: 'a@b.test',
  role: role,
  descriptor: 'x',
  permissions: permissions,
);

/// A fully granted academy admin, as `permissions:backfill` leaves one.
UserProfile _fullAdmin() => _profile(
  UserRole.admin,
  permissions: PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

const _unknownSession = SessionUnknown();
const _unavailable = SessionUnavailable(NetworkFailure(NetworkProblem.offline));
const _signedOut = SessionSignedOut();
const _expired = SessionSignedOut(reason: SignedOutReason.expired);
const _refused = SessionSignedOut(reason: SignedOutReason.refused, message: 'Suspended.');
const _deleted = SessionSignedOut(reason: SignedOutReason.deleted);
final _learner = SessionSignedIn(_profile(UserRole.student));
final _instructor = SessionSignedIn(_profile(UserRole.instructor));
final _admin = SessionSignedIn(_fullAdmin());
const _superAdmin = SessionUnsupportedRole();

void main() {
  deepLinkRedirects();
  linkResume();
  liveFormAccess();
  String? go(SessionState session, String location) =>
      redirectFor(session: session, location: location);

  group('restoring', () {
    test('everything waits on the splash, and the splash itself stays', () {
      for (final location in [AppRoutes.home, AppRoutes.catalog, AppRoutes.staffDashboard]) {
        expect(go(_unknownSession, location), AppRoutes.splash);
        expect(go(_unavailable, location), AppRoutes.splash);
      }
      expect(go(_unknownSession, AppRoutes.splash), isNull);
      expect(go(_unavailable, AppRoutes.splash), isNull);
    });
  });

  group('signed out', () {
    test('public routes are allowed', () {
      for (final location in [
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.resetPassword(_realToken),
        AppRoutes.catalog,
        AppRoutes.catalogCourse('jyotish'),
        AppRoutes.verifyCredential('SYN-1'),
        AppRoutes.help,
        AppRoutes.privacy,
      ]) {
        expect(go(_signedOut, location), isNull, reason: location);
      }
    });

    test('a protected route sends them to welcome, keeping where they were going', () {
      expect(go(_signedOut, AppRoutes.home), '/welcome?next=%2Fhome');
      expect(
        go(_signedOut, AppRoutes.learnLesson('c1', 'l1')),
        '/welcome?next=%2Flearn%2Fc1%2Flessons%2Fl1',
      );
      expect(go(_signedOut, AppRoutes.splash), AppRoutes.welcome);
    });

    test('an unknown path is never kept as a destination', () {
      expect(go(_signedOut, '/not-a-route'), AppRoutes.welcome);
      expect(go(_signedOut, '//evil.example/phish'), AppRoutes.welcome);
    });

    test('a deliberate sign-out goes to welcome and keeps nothing of where it happened', () {
      // The page someone signs out from is not where the next person to sign in is going; with it
      // kept as `next`, signing in again landed on the last page (LIVE E2E AUTH-014).
      const signedOut = SessionSignedOut(reason: SignedOutReason.signedOut);
      expect(go(signedOut, AppRoutes.profile), AppRoutes.welcome);
      expect(go(signedOut, AppRoutes.staffBilling), AppRoutes.welcome);
      expect(go(signedOut, AppRoutes.welcome), isNull);
    });

    test('a session that ended or was refused lands on sign-in', () {
      expect(go(_expired, AppRoutes.splash), AppRoutes.login);
      expect(go(_expired, AppRoutes.home), '/login?next=%2Fhome');
      expect(go(_refused, AppRoutes.staffDashboard), '/login?next=%2Fstaff');
      expect(go(_expired, AppRoutes.login), isNull);
    });

    test('a deleted account lands on sign-in, and where it was is not kept', () {
      expect(go(_deleted, AppRoutes.profileDeleteAccount), AppRoutes.login);
      expect(go(_deleted, AppRoutes.login), isNull);
    });
  });

  test('a super admin is held on the unsupported-role screen', () {
    expect(go(_superAdmin, AppRoutes.home), AppRoutes.unsupportedRole);
    expect(go(_superAdmin, AppRoutes.catalog), AppRoutes.unsupportedRole);
    expect(go(_superAdmin, AppRoutes.unsupportedRole), isNull);
  });

  group('signed in', () {
    test('the signed-out entry points send each role to its home', () {
      for (final entry in [
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ]) {
        expect(go(_learner, entry), AppRoutes.home, reason: entry);
        expect(go(_instructor, entry), AppRoutes.staffDashboard, reason: entry);
        expect(go(_admin, entry), AppRoutes.staffDashboard, reason: entry);
      }
    });

    test('a granted admin and an instructor differ only where the backend differs', () {
      // reports.view, instructors.view and certificates.issue are staff keys: an instructor passes
      // on role alone (apps/api/src/lib/permissions.ts).
      expect(go(_instructor, AppRoutes.staffReports), isNull);
      expect(go(_instructor, AppRoutes.staffInstructors), isNull);
      expect(go(_instructor, AppRoutes.staffCertificates), isNull);
      // These use requirePermission: an instructor can never pass.
      expect(go(_instructor, AppRoutes.staffReportsInstructors), AppRoutes.staffDashboard);
      expect(go(_instructor, AppRoutes.staffBilling), AppRoutes.staffDashboard);
      expect(go(_instructor, AppRoutes.staffInstructorInvite), AppRoutes.staffDashboard);
      expect(go(_admin, AppRoutes.staffReportsInstructors), isNull);
    });

    test('the retired billing and onboarding paths go home, whoever is signed in', () {
      for (final location in [
        AppRoutes.staffBilling,
        AppRoutes.staffBillingPlans,
        AppRoutes.staffInvoice('inv1'),
        AppRoutes.staffGetStarted,
      ]) {
        expect(go(_admin, location), AppRoutes.staffDashboard, reason: location);
        expect(go(_instructor, location), AppRoutes.staffDashboard, reason: location);
        expect(go(_learner, location), AppRoutes.home, reason: location);
      }
    });

    test('an admin without the key is kept out, and never into a redirect loop', () {
      final bare = SessionSignedIn(_profile(UserRole.admin));
      expect(go(bare, AppRoutes.staffBilling), AppRoutes.staffDashboard);
      expect(go(bare, AppRoutes.staffCourses), AppRoutes.staffDashboard);
      // The dashboard itself needs reports.view; staying there shows the screen's refusal.
      expect(go(bare, AppRoutes.staffDashboard), isNull);
    });

    test('each role keeps its own shell and is sent home from another', () {
      // Learner routes
      expect(go(_learner, AppRoutes.home), isNull);
      expect(go(_instructor, AppRoutes.home), AppRoutes.staffDashboard);
      expect(go(_admin, AppRoutes.learnCourse('c1')), AppRoutes.staffDashboard);
      // Staff routes
      expect(go(_instructor, AppRoutes.staffReview), isNull);
      expect(go(_admin, AppRoutes.staffReview), isNull);
      expect(go(_learner, AppRoutes.staffReview), AppRoutes.home);
      expect(go(_learner, AppRoutes.staffInstructors), AppRoutes.home);
    });

    test('public routes stay reachable while signed in', () {
      expect(go(_learner, AppRoutes.catalog), isNull);
      expect(go(_admin, AppRoutes.helpArticle('getting-started')), isNull);
    });

    test('an unknown path falls through to the not-found screen', () {
      expect(go(_learner, '/nope'), isNull);
    });
  });

  group('destinationAfterSignIn', () {
    test('honours a known route the role may see', () {
      expect(
        destinationAfterSignIn(profile: _profile(UserRole.student), next: AppRoutes.certificates),
        AppRoutes.certificates,
      );
    });

    test('never follows an unknown or foreign target', () {
      final learner = _profile(UserRole.student);
      expect(destinationAfterSignIn(profile: learner, next: null), AppRoutes.home);
      expect(
        destinationAfterSignIn(profile: learner, next: 'https://evil.example'),
        AppRoutes.home,
      );
      expect(destinationAfterSignIn(profile: learner, next: '/nope'), AppRoutes.home);
      expect(
        destinationAfterSignIn(profile: learner, next: AppRoutes.staffBilling),
        AppRoutes.home,
      );
      expect(
        destinationAfterSignIn(
          profile: _profile(UserRole.instructor),
          next: AppRoutes.staffBilling,
        ),
        AppRoutes.staffDashboard,
      );
    });
  });

  group('route table', () {
    test('sections are assigned by the most specific pattern', () {
      expect(sectionOf(AppRoutes.staffCourses), AppSection.staff);
      expect(sectionOf(AppRoutes.staffInstructorInvite), AppSection.staff);
      expect(sectionOf(AppRoutes.staffInstructor('i1')), AppSection.staff);
      expect(sectionOf(AppRoutes.learnLesson('c1', 'l1')), AppSection.learner);
      expect(sectionOf(AppRoutes.catalogPreview('slug', 'l1')), AppSection.public);
      expect(sectionOf('/nope'), isNull);
    });

    test('isKnownAppRoute refuses anything the app does not own', () {
      expect(isKnownAppRoute(AppRoutes.home), isTrue);
      expect(isKnownAppRoute('/home?tab=1'), isTrue);
      expect(isKnownAppRoute('https://evil.example/home'), isFalse);
      expect(isKnownAppRoute('//evil.example'), isFalse);
      expect(isKnownAppRoute('/media/abc'), isFalse);
      expect(isKnownAppRoute('relative'), isFalse);
    });
  });
}

/// A link from outside the app reaches the router as an ordinary location, so the redirect is where
/// the web's own paths are mapped and an id nobody issued is refused (FLUTTER-028, §18).
void deepLinkRedirects() {
  group('a location the app was opened with', () {
    const id = 'cmumqihbi001rmmos6cypzr5m';

    test('the web\'s catalogue path becomes the app\'s', () {
      expect(
        redirectFor(session: _signedOut, location: '/courses/foundations-of-vedic-astrology'),
        '/catalog/foundations-of-vedic-astrology',
      );
    });

    test('a slug the catalogue never built goes nowhere the app answers', () {
      expect(
        redirectFor(session: _signedOut, location: '/courses/Not%20A%20Slug'),
        unroutableLocation,
      );
    });

    test('a reset token that did not come from the academy\'s e-mail is refused', () {
      expect(
        redirectFor(session: _signedOut, location: '/reset-password/short'),
        unroutableLocation,
      );
      expect(
        redirectFor(session: _signedOut, location: '/reset-password/$_realToken'),
        isNull,
        reason: 'a real token is left to the reset screen, which says if it has expired',
      );
    });

    test('an Admin\'s course link becomes the course-link screen, signed in or out', () {
      for (final session in [_signedOut, _learner, _instructor]) {
        expect(
          redirectFor(session: session, location: '/courses/$id/enroll'),
          '/enrol/$id',
          reason: '$session',
        );
        // Then it stays: the screen is public, and decides for itself what a session may do there.
        expect(
          redirectFor(session: session, location: '/enrol/$id'),
          isNull,
          reason: '$session',
        );
      }
    });

    test('an invitation stays open whoever is signed in; a bad token goes nowhere', () {
      for (final session in [_signedOut, _learner, _admin]) {
        expect(
          redirectFor(session: session, location: '/invite/$_realToken'),
          isNull,
          reason: '$session',
        );
      }
      expect(redirectFor(session: _signedOut, location: '/invite/short'), unroutableLocation);
      expect(sectionOf('/invite/$_realToken'), AppSection.public);
      expect(isKnownAppRoute('/enrol/$id'), isTrue);
    });

    test('the app\'s own paths keep their ids, whatever shape the API issues', () {
      // Re-checking these would put this mapping between the app and its own navigation; a bad id is
      // answered by the screen, from the API's own 404.
      for (final path in ['/verify/x', '/learn/c1', '/learn/c1/lessons/l1', '/notifications/n1']) {
        expect(
          redirectFor(session: _learner, location: path),
          isNot(unroutableLocation),
          reason: path,
        );
      }
    });

    test('a good id is left to the session rules, as any other route is', () {
      // The learner may open their own course, so nothing redirects.
      expect(redirectFor(session: _learner, location: '/learn/$id'), isNull);
      // Signed out, the same link keeps its destination as `next` — §5.4, unchanged by this mapping.
      expect(
        redirectFor(session: _signedOut, location: '/learn/$id'),
        contains('next=%2Flearn%2F$id'),
      );
    });

    test('the mapping does not disturb the app\'s own routes', () {
      expect(redirectFor(session: _learner, location: '/catalog/a-course'), isNull);
      expect(redirectFor(session: _learner, location: '/my-learning/in-progress'), isNull);
      expect(redirectFor(session: _learner, location: '/notifications'), isNull);
    });
  });
}

/// A link the app is opened with races the session restore. [LinkResume] is what stops it being lost.
void linkResume() {
  group('a link the app was opened with', () {
    const id = 'cmumqihbi001rmmos6cypzr5m';

    test('is held while the session is being restored, then followed', () {
      final resume = LinkResume();

      // Cold start on the link: the restore sends them to the splash, and the link is remembered.
      expect(
        resume.follow(session: _unknownSession, location: '/notifications/$id'),
        AppRoutes.splash,
      );
      expect(resume.pending, '/notifications/$id');

      // Once the session is known, the splash hands them the link rather than their home.
      expect(resume.follow(session: _learner, location: AppRoutes.splash), '/notifications/$id');
      expect(resume.pending, isNull, reason: 'a link is followed once');
    });

    test('is kept as `next` when the reader has to sign in first', () {
      final resume = LinkResume();
      resume.follow(session: _unknownSession, location: '/notifications/$id');

      final target = resume.follow(session: _signedOut, location: AppRoutes.splash);

      expect(target, contains('next=%2Fnotifications%2F$id'));
    });

    test('is dropped when they have already moved on', () {
      final resume = LinkResume();
      resume.follow(session: _unknownSession, location: '/notifications/$id');

      // The session resolved while they were somewhere else: the link is stale, not a jump.
      expect(resume.follow(session: _learner, location: AppRoutes.home), isNull);
      expect(resume.pending, isNull);
    });

    test('a location the app does not answer is never remembered', () {
      final resume = LinkResume();

      resume.follow(session: _unknownSession, location: '/not-a-route-at-all');

      expect(resume.pending, isNull);
    });

    test('an ordinary cold start remembers nothing', () {
      final resume = LinkResume();

      expect(resume.follow(session: _unknownSession, location: AppRoutes.splash), isNull);
      expect(resume.pending, isNull);
      // And the session resolving then behaves exactly as the plain redirect does.
      expect(
        resume.follow(session: _learner, location: AppRoutes.splash),
        homeFor(UserRole.student),
      );
    });

    test('an offline restore holds the link too, rather than losing it', () {
      final resume = LinkResume();

      resume.follow(session: _unavailable, location: '/learn/$id');

      expect(resume.pending, '/learn/$id');
    });
  });

  group('onboarding redirect', () {
    const brandNew = AcademyPlan(enforced: true, restricted: true);

    test('an admin of a brand-new academy is sent from the dashboard to choose a plan', () {
      expect(
        onboardingRedirect(session: _admin, location: AppRoutes.staffDashboard, plan: brandNew),
        AppRoutes.staffGetStarted,
      );
    });

    test('only the dashboard is replaced: everything else stays reachable', () {
      for (final location in [
        AppRoutes.staffStudents,
        AppRoutes.staffBilling,
        AppRoutes.staffProfile,
        AppRoutes.staffGetStarted,
      ]) {
        expect(
          onboardingRedirect(session: _admin, location: location, plan: brandNew),
          isNull,
          reason: location,
        );
      }
    });

    test(
      'never when plans are not enforced, the academy has subscribed, or the plan is unknown',
      () {
        for (final plan in [
          const AcademyPlan(restricted: true),
          const AcademyPlan(enforced: true, status: SubscriptionState.expired, restricted: true),
          const AcademyPlan(enforced: true, status: SubscriptionState.trialing),
          null,
        ]) {
          expect(
            onboardingRedirect(session: _admin, location: AppRoutes.staffDashboard, plan: plan),
            isNull,
            reason: '$plan',
          );
        }
      },
    );

    test('"Not now" keeps the dashboard for the session', () {
      expect(
        onboardingRedirect(
          session: _admin,
          location: AppRoutes.staffDashboard,
          plan: brandNew,
          deferred: true,
        ),
        isNull,
      );
    });

    test('never for an instructor, nor an admin who cannot read the plans on sale', () {
      for (final session in [_instructor, SessionSignedIn(_profile(UserRole.admin))]) {
        expect(
          onboardingRedirect(session: session, location: AppRoutes.staffDashboard, plan: brandNew),
          isNull,
        );
      }
    });

    test('the onboarding route needs billing read access, like the plans it shows', () {
      expect(requiredCapability(AppRoutes.staffGetStarted), isNotNull);
      expect(canOpen(_fullAdmin(), AppRoutes.staffGetStarted), isTrue);
      expect(canOpen(_profile(UserRole.instructor), AppRoutes.staffGetStarted), isFalse);
      expect(isKnownAppRoute(AppRoutes.staffGetStarted), isTrue);
    });
  });
}

/// `POST /live` and `PATCH /live/:id` are behind `live.manage`, as the staff actions inside are.
void liveFormAccess() {
  group('the live class form', () {
    final reader = SessionSignedIn(
      _profile(UserRole.admin, permissions: const [PermissionKey.liveNotify]),
    );
    final manager = SessionSignedIn(
      _profile(UserRole.admin, permissions: const [PermissionKey.liveManage]),
    );

    test('needs the right to run live classes', () {
      expect(requiredCapability(AppRoutes.staffLiveNew), Capability.manageLive);
      expect(requiredCapability(AppRoutes.staffLiveEdit('l1')), Capability.manageLive);
      // The schedule and a class stay open to staff; the actions inside them are gated.
      expect(requiredCapability(AppRoutes.staffLive), isNull);
      expect(requiredCapability(AppRoutes.staffLiveClass('l1')), isNull);
    });

    test('is closed to an admin without it, and open to one with it and to instructors', () {
      expect(
        redirectFor(session: reader, location: AppRoutes.staffLiveNew),
        AppRoutes.staffDashboard,
      );
      expect(
        redirectFor(session: reader, location: AppRoutes.staffLiveEdit('l1')),
        AppRoutes.staffDashboard,
      );
      expect(redirectFor(session: reader, location: AppRoutes.staffLiveClass('l1')), isNull);
      expect(redirectFor(session: manager, location: AppRoutes.staffLiveNew), isNull);
      expect(redirectFor(session: manager, location: AppRoutes.staffLiveEdit('l1')), isNull);
      expect(redirectFor(session: _instructor, location: AppRoutes.staffLiveNew), isNull);
      expect(redirectFor(session: _instructor, location: AppRoutes.staffLiveEdit('l1')), isNull);
    });
  });
}
