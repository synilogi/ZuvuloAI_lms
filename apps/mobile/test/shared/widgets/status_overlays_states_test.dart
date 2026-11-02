import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/l10n/generated/app_localizations_en.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/pump.dart';

void main() {
  group('StatusBadge registry', () {
    final l10n = AppLocalizationsEn();

    test('every status has a non-empty label and an icon or dot', () {
      for (final kind in StatusKind.values) {
        final style = statusStyle(kind);
        expect(statusLabel(l10n, kind), isNotEmpty, reason: kind.name);
        expect(style.icon != null || style.dot, isTrue, reason: kind.name);
      }
    });

    test('mirrors the web registry for representative states', () {
      expect(statusLabel(l10n, StatusKind.live), 'Live now');
      expect(statusStyle(StatusKind.live).pulse, isTrue);
      expect(statusLabel(l10n, StatusKind.notPassed), 'Not passed');
      expect(statusLabel(l10n, StatusKind.resubmissionRequested), 'Resubmission requested');
      expect(statusLabel(l10n, StatusKind.readyToIssue), 'Ready to issue');
      expect(statusLabel(l10n, StatusKind.voided), 'Void');
    });

    testWidgets('a badge is announced by its label only', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpThemed(tester, const StatusBadge(StatusKind.overdue));
      expect(find.bySemanticsLabel('Overdue'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the live dot pulses, and stays still under reduced motion', (tester) async {
      await pumpThemed(tester, const StatusBadge(StatusKind.live));
      expect(find.byType(FadeTransition), findsWidgets);
      await pumpThemed(tester, const StatusBadge(StatusKind.live), reduceMotion: true);
      expect(
        find.descendant(of: find.byType(StatusBadge), matching: find.byType(FadeTransition)),
        findsNothing,
      );
    });

    testWidgets('a label override replaces the text', (tester) async {
      await pumpThemed(
        tester,
        const StatusBadge(StatusKind.startingSoon, labelOverride: 'Starts in 5 min'),
      );
      expect(find.text('Starts in 5 min'), findsOneWidget);
    });
  });

  testWidgets('ProgressRing clamps and announces its percentage', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpThemed(tester, const ProgressRing(value: 1.4), reduceMotion: true);
    expect(find.bySemanticsLabel('100% complete'), findsOneWidget);
    handle.dispose();
  });

  group('KpiTile', () {
    testWidgets('describes an increase in words', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpThemed(
        tester,
        const KpiTile(
          label: 'Learners',
          value: '120',
          delta: 12.5,
          comparisonLabel: 'vs previous 90 days',
        ),
      );
      expect(find.text('+12.5%'), findsOneWidget);
      expect(find.bySemanticsLabel('Learners, 120, Up 12.5% vs previous 90 days'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('describes a decrease with a true minus sign', (tester) async {
      await pumpThemed(tester, const KpiTile(label: 'Reviews', value: '3', delta: -40));
      expect(find.text('−40%'), findsOneWidget);
    });
  });

  test('AvatarInitials matches the web: honorifics dropped, first two words', () {
    expect(AvatarInitials.initialsOf('Meera Krishnan Iyer'), 'MK');
    expect(AvatarInitials.initialsOf('Dr. Meera Iyer'), 'MI');
    expect(AvatarInitials.initialsOf('Acharya Ravi Shankar'), 'RS');
    expect(AvatarInitials.initialsOf('ravi'), 'R');
    expect(AvatarInitials.initialsOf('  '), '?');
  });

  test('a greeting uses the first name after any honorific, never "Dr."', () {
    expect(AvatarInitials.firstNameOf('Dr. Meenakshi Iyer'), 'Meenakshi');
    expect(AvatarInitials.firstNameOf('Acharya Vinod Shastri'), 'Vinod');
    expect(AvatarInitials.firstNameOf('Ananya Rao'), 'Ananya');
    expect(AvatarInitials.firstNameOf('Kavita'), 'Kavita');
  });

  group('AppDialog', () {
    testWidgets('a destructive action needs the acknowledgement first', (tester) async {
      var confirmed = 0;
      await pumpThemed(
        tester,
        AppDialog(
          title: 'Revoke?',
          confirmLabel: 'Revoke',
          destructive: true,
          onConfirm: () async {
            confirmed++;
            return null;
          },
        ),
        scroll: false,
      );
      await tester.tap(find.text('Revoke'));
      await tester.pump();
      expect(confirmed, 0);
      await tester.tap(find.text("I understand this can't be undone"));
      await tester.pump();
      await tester.tap(find.text('Revoke'));
      await tester.pump();
      expect(confirmed, 1);
    });

    testWidgets('a failed action keeps the dialog open with the error', (tester) async {
      await tester.pumpWidget(
        themedHarness(
          Builder(
            builder: (context) => AppButton(
              label: 'Open',
              onPressed: () => showConfirmDialog(
                context,
                title: 'Archive?',
                confirmLabel: 'Archive',
                onConfirm: () async => 'The course has live classes scheduled.',
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(find.text('The course has live classes scheduled.'), findsOneWidget);
      expect(find.text('Archive?'), findsOneWidget);
    });

    testWidgets('confirm resolves true and cancel resolves false', (tester) async {
      final results = <bool>[];
      await tester.pumpWidget(
        themedHarness(
          Builder(
            builder: (context) => AppButton(
              label: 'Open',
              onPressed: () async => results.add(
                await showConfirmDialog(context, title: 'Publish?', confirmLabel: 'Publish'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(results, [true, false]);
    });
  });

  testWidgets('showAppSnackbar shows the message and runs Undo', (tester) async {
    var undone = false;
    await tester.pumpWidget(
      themedHarness(
        Builder(
          builder: (context) => AppButton(
            label: 'Remove',
            onPressed: () => showAppSnackbar(context, 'Removed', onUndo: () => undone = true),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Removed'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    expect(undone, isTrue);
  });

  testWidgets('FilterSheet applies and resets', (tester) async {
    var applied = false;
    var reset = false;
    await pumpThemed(
      tester,
      FilterSheet(
        title: 'Filters',
        onApply: () => applied = true,
        onReset: () => reset = true,
        children: const [Text('field')],
      ),
      scroll: false,
    );
    await tester.tap(find.text('Apply'));
    await tester.tap(find.text('Reset'));
    expect([applied, reset], [true, true]);
  });

  group('DelayedLoading', () {
    testWidgets('shows nothing for 150 ms, then the skeleton, then "Still working…" at 8 s', (
      tester,
    ) async {
      await tester.pumpWidget(
        themedHarness(const DelayedLoading(skeleton: SkeletonBox(key: Key('sk')))),
      );
      expect(find.byKey(const Key('sk')), findsNothing);
      await tester.pump(const Duration(milliseconds: 160));
      expect(find.byKey(const Key('sk')), findsOneWidget);
      expect(find.text('Still working…'), findsNothing);
      await tester.pump(const Duration(seconds: 8));
      expect(find.text('Still working…'), findsOneWidget);
    });
  });

  group('state views', () {
    testWidgets('ErrorState retries', (tester) async {
      var retried = false;
      await pumpThemed(tester, ErrorState(onRetry: () => retried = true), scroll: false);
      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    });

    testWidgets('FeatureUnavailableView offers Review plan only to billing admins', (tester) async {
      await pumpThemed(tester, const FeatureUnavailableView(), scroll: false);
      expect(find.text('Review plan'), findsNothing);
      expect(find.text("Your LMS plan doesn't include this. Contact your admin."), findsOneWidget);
      await pumpThemed(tester, FeatureUnavailableView(onReviewPlan: () {}), scroll: false);
      expect(find.text('Review plan'), findsOneWidget);
    });

    testWidgets('SubscriptionStateView words required and expired differently', (tester) async {
      await pumpThemed(
        tester,
        const SubscriptionStateView(problem: SubscriptionProblem.required),
        scroll: false,
      );
      expect(find.text('Your LMS needs an active plan.'), findsOneWidget);
      await pumpThemed(
        tester,
        const SubscriptionStateView(problem: SubscriptionProblem.expired),
        scroll: false,
      );
      expect(find.text("Your LMS's subscription has ended."), findsOneWidget);
    });

    testWidgets('EmptyState.noMatches offers Clear filters', (tester) async {
      var cleared = false;
      await pumpThemed(
        tester,
        EmptyState.noMatches(onClearFilters: () => cleared = true),
        scroll: false,
      );
      await tester.tap(find.text('Clear filters'));
      expect(cleared, isTrue);
    });

    testWidgets('UnavailableLessonView shows the server reason', (tester) async {
      await pumpThemed(
        tester,
        const UnavailableLessonView(lockedReason: 'Pass the Chapter 1 quiz.'),
        scroll: false,
      );
      expect(find.text('Pass the Chapter 1 quiz.'), findsOneWidget);
    });
  });
}
