import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/routing/route_access.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/shared/entitlements/entitlements.dart';

/// `moduleAccess` and `MODULE_FEATURE` mirror `packages/domain/src/entitlement.ts` exactly; the web
/// uses the same table, so a module never reads open on one client and locked on the other.
void main() {
  group('the module → feature table', () {
    test('is the domain\'s, entry for entry', () {
      expect(
        {for (final m in WorkspaceModule.values) m.name: m.feature.wire},
        {
          'courses': 'courses.manage',
          'quizzes': 'assessments.manage',
          'assignments': 'assessments.manage',
          'certificates': 'certificates.manage',
          'live': 'live_classes',
          'reports': 'reports.basic',
          'branding': 'custom_branding',
        },
      );
    });
  });

  group('moduleAccess', () {
    test('everything is open while plans are not enforced, whatever the plan says', () {
      const plan = AcademyPlan(restricted: true, status: SubscriptionState.expired);
      for (final module in WorkspaceModule.values) {
        expect(moduleAccess(plan, module), ModuleAccess.open, reason: module.name);
      }
    });

    test('a plan that was not read opens everything: the server decides', () {
      for (final module in WorkspaceModule.values) {
        expect(moduleAccess(null, module), ModuleAccess.open, reason: module.name);
      }
    });

    test('enforced: what the plan serves is open, the rest locked', () {
      const plan = AcademyPlan(
        enforced: true,
        status: SubscriptionState.active,
        features: [FeatureKey.coursesManage, FeatureKey.assessmentsManage],
      );

      expect(moduleAccess(plan, WorkspaceModule.courses), ModuleAccess.open);
      expect(moduleAccess(plan, WorkspaceModule.quizzes), ModuleAccess.open);
      expect(moduleAccess(plan, WorkspaceModule.assignments), ModuleAccess.open);
      expect(moduleAccess(plan, WorkspaceModule.live), ModuleAccess.locked);
      expect(moduleAccess(plan, WorkspaceModule.certificates), ModuleAccess.locked);
      expect(moduleAccess(plan, WorkspaceModule.reports), ModuleAccess.locked);
      expect(moduleAccess(plan, WorkspaceModule.branding), ModuleAccess.locked);
    });

    test('enforced: what the last plan had is read-only once it has ended', () {
      const plan = AcademyPlan(
        enforced: true,
        status: SubscriptionState.expired,
        restricted: true,
        lastFeatures: [FeatureKey.liveClasses, FeatureKey.coursesManage],
      );

      expect(moduleAccess(plan, WorkspaceModule.live), ModuleAccess.readOnly);
      expect(moduleAccess(plan, WorkspaceModule.courses), ModuleAccess.readOnly);
      expect(moduleAccess(plan, WorkspaceModule.reports), ModuleAccess.locked);
    });

    test('a feature served now wins over the same one in lastFeatures', () {
      const plan = AcademyPlan(
        enforced: true,
        features: [FeatureKey.liveClasses],
        lastFeatures: [FeatureKey.liveClasses],
      );

      expect(moduleAccess(plan, WorkspaceModule.live), ModuleAccess.open);
    });

    test('a brand-new academy has every gated module locked', () {
      const plan = AcademyPlan(enforced: true, restricted: true);
      for (final module in WorkspaceModule.values) {
        expect(moduleAccess(plan, module), ModuleAccess.locked, reason: module.name);
      }
    });
  });

  group('AcademyPlan, as the server says it', () {
    test('needs onboarding only when enforced and never subscribed', () {
      expect(const AcademyPlan(enforced: true).needsOnboarding, isTrue);
      expect(const AcademyPlan().needsOnboarding, isFalse);
      expect(
        const AcademyPlan(enforced: true, status: SubscriptionState.expired).needsOnboarding,
        isFalse,
        reason: 'a lapsed academy reviews its plan; it is not onboarded again',
      );
    });

    test('includes a feature only when it is served, or when plans are not enforced', () {
      const enforced = AcademyPlan(enforced: true, features: [FeatureKey.liveClasses]);
      expect(enforced.includes(FeatureKey.liveClasses), isTrue);
      expect(enforced.includes(FeatureKey.reportsBasic), isFalse);
      expect(enforced.includes(FeatureKey.unknown), isFalse);
      expect(const AcademyPlan().includes(FeatureKey.reportsBasic), isTrue);
    });

    test('counts a trial\'s days left by part days, and none once it has ended', () {
      final now = DateTime.utc(2026, 10, 3, 9, 30);
      AcademyPlan endingIn(Duration left) =>
          AcademyPlan(status: SubscriptionState.trialing, trialEndsAt: now.add(left));

      expect(endingIn(const Duration(days: 14)).trialDaysLeft(now), 14);
      expect(endingIn(const Duration(days: 13, hours: 1)).trialDaysLeft(now), 14);
      expect(endingIn(const Duration(hours: 3)).trialDaysLeft(now), 1);
      expect(endingIn(const Duration(minutes: -5)).trialDaysLeft(now), 0);
      expect(
        AcademyPlan(status: SubscriptionState.active, trialEndsAt: now).trialDaysLeft(now),
        isNull,
      );
    });
  });

  group('which academy notice shows: past due > restricted > trial', () {
    final trial = AcademyPlan(
      enforced: true,
      status: SubscriptionState.trialing,
      trialEndsAt: DateTime.utc(2026, 10, 17),
    );

    test('one at a time, by priority', () {
      expect(
        academyNoticeFor(
          const AcademyPlan(enforced: true, restricted: true, status: SubscriptionState.pastDue),
        ),
        AcademyNotice.pastDue,
      );
      expect(
        academyNoticeFor(const AcademyPlan(enforced: true, restricted: true)),
        AcademyNotice.restricted,
      );
      expect(academyNoticeFor(trial), AcademyNotice.trial);
    });

    test('nothing for a plan in good standing, an unread one, or restriction not enforced', () {
      expect(academyNoticeFor(const AcademyPlan(status: SubscriptionState.active)), isNull);
      expect(academyNoticeFor(null), isNull);
      expect(academyNoticeFor(const AcademyPlan(restricted: true)), isNull);
      expect(academyNoticeFor(trial.copyWith(trialEndsAt: null)), isNull);
    });
  });

  group('moduleOf — the module a staff route belongs to', () {
    test('every page below a module root is the module\'s', () {
      expect(moduleOf(AppRoutes.staffCourses), WorkspaceModule.courses);
      expect(moduleOf(AppRoutes.staffCurriculum('c1')), WorkspaceModule.courses);
      expect(moduleOf(AppRoutes.staffLesson('c1', 'l1')), WorkspaceModule.courses);
      expect(moduleOf(AppRoutes.staffQuiz('q1')), WorkspaceModule.quizzes);
      expect(moduleOf(AppRoutes.staffReview), WorkspaceModule.assignments);
      expect(moduleOf(AppRoutes.staffSubmissions('a1')), WorkspaceModule.assignments);
      expect(moduleOf(AppRoutes.staffSubmission('s1')), WorkspaceModule.assignments);
      expect(moduleOf(AppRoutes.staffCertificate('x')), WorkspaceModule.certificates);
      expect(moduleOf(AppRoutes.staffLiveNew), WorkspaceModule.live);
      expect(moduleOf(AppRoutes.staffLiveEdit('l1')), WorkspaceModule.live);
      expect(moduleOf(AppRoutes.staffReportsInstructors), WorkspaceModule.reports);
    });

    test('routes no plan feature governs belong to none', () {
      for (final path in [
        AppRoutes.staffDashboard,
        AppRoutes.staffStudents,
        AppRoutes.staffCalendar,
        AppRoutes.staffInstructors,
        AppRoutes.staffBilling,
        AppRoutes.staffBillingPlans,
        AppRoutes.staffGetStarted,
        AppRoutes.staffHelp,
        AppRoutes.staffProfile,
        // A learner's own pages are never gated by the academy's staff plan.
        AppRoutes.live,
        AppRoutes.certificates,
        AppRoutes.assignments,
      ]) {
        expect(moduleOf(path), isNull, reason: path);
      }
      // A prefix that is not a path segment is not the module.
      expect(moduleOf('/staff/coursesx'), isNull);
    });
  });
}
