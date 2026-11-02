import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/l10n/generated/app_localizations_en.dart';
import 'package:syniastrolms_mobile/shared/entitlements/entitlements.dart';

import '../../helpers/pump.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('recognising a refusal', () {
    test('maps each code the backend can send', () {
      expect(refusalKindOf(const PermissionFailure()), RefusalKind.permission);
      expect(
        refusalKindOf(const EntitlementFailure(EntitlementProblem.subscriptionRequired)),
        RefusalKind.subscriptionRequired,
      );
      expect(
        refusalKindOf(const EntitlementFailure(EntitlementProblem.subscriptionExpired)),
        RefusalKind.subscriptionExpired,
      );
      expect(
        refusalKindOf(const EntitlementFailure(EntitlementProblem.subscriptionPastDue)),
        RefusalKind.subscriptionExpired,
      );
      expect(
        refusalKindOf(const EntitlementFailure(EntitlementProblem.featureNotIncluded)),
        RefusalKind.featureNotIncluded,
      );
      expect(
        refusalKindOf(const EntitlementFailure(EntitlementProblem.limitReached)),
        RefusalKind.limitReached,
      );
    });

    test('an ordinary failure is not one of these', () {
      for (final failure in [
        const NetworkFailure(NetworkProblem.offline),
        const NotFoundFailure(),
        const ForbiddenFailure(message: 'This account has been deactivated.'),
        const ServerFailure(status: 500),
        const ValidationFailure(),
      ]) {
        expect(refusalKindOf(failure), isNull, reason: failure.runtimeType.toString());
      }
    });

    test('the short message leads with the app\'s words and adds the server\'s', () {
      expect(
        refusalMessage(l10n, RefusalKind.limitReached, serverMessage: 'Learners: 500 of 500 used.'),
        'This is as far as your plan goes Learners: 500 of 500 used.',
      );
      expect(refusalMessage(l10n, RefusalKind.permission), l10n.permissionDeniedInline);
    });
  });

  group('the view a refusal renders', () {
    testWidgets('permission denied never mentions the plan', (tester) async {
      await pumpThemed(
        tester,
        const RefusalView(kind: RefusalKind.permission, serverMessage: 'Not allowed'),
        scroll: false,
      );

      expect(find.text("You don't have access to this."), findsOneWidget);
      expect(find.text('Ask your admin.'), findsOneWidget);
      expect(find.text('Review plan'), findsNothing);
    });

    testWidgets('a learner or instructor is told to contact the academy', (tester) async {
      await pumpThemed(
        tester,
        const RefusalView(kind: RefusalKind.featureNotIncluded),
        scroll: false,
      );

      expect(find.text('Not included in your LMS plan.'), findsOneWidget);
      expect(find.text("Your LMS plan doesn't include this. Contact your admin."), findsOneWidget);
      expect(find.text('Review plan'), findsNothing, reason: 'billing details are not theirs');
    });

    testWidgets('an admin who can read billing is offered Review plan', (tester) async {
      var reviewed = false;
      await pumpThemed(
        tester,
        RefusalView(
          kind: RefusalKind.featureNotIncluded,
          serverMessage: 'Live classes are not in your plan.',
          onReviewPlan: () => reviewed = true,
        ),
        scroll: false,
      );

      expect(find.text('Live classes are not in your plan.'), findsOneWidget);
      await tester.tap(find.text('Review plan'));
      expect(reviewed, isTrue);
    });

    testWidgets('subscription required and expired read differently', (tester) async {
      await pumpThemed(
        tester,
        const RefusalView(kind: RefusalKind.subscriptionRequired),
        scroll: false,
      );
      expect(find.text('Your LMS needs an active plan.'), findsOneWidget);

      await pumpThemed(
        tester,
        const RefusalView(kind: RefusalKind.subscriptionExpired),
        scroll: false,
      );
      expect(find.text("Your LMS's subscription has ended."), findsOneWidget);
    });

    testWidgets('a limit reached explains itself with the server\'s numbers', (tester) async {
      await pumpThemed(
        tester,
        RefusalView(
          kind: RefusalKind.limitReached,
          serverMessage: 'This LMS has reached its learner limit.',
          onReviewPlan: () {},
        ),
        scroll: false,
      );

      expect(find.text('This is as far as your plan goes'), findsOneWidget);
      expect(find.text('This LMS has reached its learner limit.'), findsOneWidget);
    });

    testWidgets('forFailure builds the view, or nothing for an ordinary failure', (tester) async {
      expect(RefusalView.forFailure(const NotFoundFailure()), isNull);
      final view = RefusalView.forFailure(
        const EntitlementFailure(EntitlementProblem.limitReached, message: 'Full.'),
      );
      expect(view, isNotNull);

      await pumpThemed(tester, view!, scroll: false);
      expect(find.text('Full.'), findsOneWidget);
    });
  });
}
