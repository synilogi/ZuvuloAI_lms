import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/format/ist.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/pump.dart';

void main() {
  group('AppButton', () {
    testWidgets('fires once per tap and meets the tap-target minimum', (tester) async {
      var taps = 0;
      await pumpThemed(tester, AppButton(label: 'Save', onPressed: () => taps++));
      await tester.tap(find.byType(AppButton));
      expect(taps, 1);
      expectMinTapTarget(tester, find.byType(TextButton));
    });

    testWidgets('while busy it ignores taps and keeps its label for screen readers', (
      tester,
    ) async {
      var taps = 0;
      await pumpThemed(tester, AppButton(label: 'Save', busy: true, onPressed: () => taps++));
      await tester.tap(find.byType(AppButton));
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Save'), findsOneWidget);
    });

    testWidgets('a null callback renders disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpThemed(tester, const AppButton(label: 'Save', onPressed: null));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Save')),
        matchesSemantics(label: 'Save', isButton: true, hasEnabledState: true),
      );
      handle.dispose();
    });
  });

  testWidgets('AppIconButton exposes its label and caps the badge at 99+', (tester) async {
    await pumpThemed(
      tester,
      AppIconButton(
        icon: AppIcons.notifications,
        label: 'Notifications',
        badgeCount: 250,
        onPressed: () {},
      ),
    );
    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(find.text('99+'), findsOneWidget);
  });

  group('AppTextField', () {
    testWidgets('the password toggle shows and hides the text', (tester) async {
      await pumpThemed(tester, const AppTextField(label: 'Password', obscure: true));
      TextField field() => tester.widget<TextField>(find.byType(TextField));
      expect(field().obscureText, isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(field().obscureText, isFalse);
      expect(find.byTooltip('Hide password'), findsOneWidget);
    });

    testWidgets('shows the server error, keeps the label visible and marks required', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        const AppTextField(label: 'Title', required: true, errorText: 'Enter a title.'),
      );
      expect(find.text('Enter a title.'), findsOneWidget);
      expect(find.text('Title · Required'), findsOneWidget);
    });

    testWidgets('runs the client validator on input', (tester) async {
      await pumpThemed(
        tester,
        AppTextField(
          label: 'Email',
          validator: (v) => (v ?? '').contains('@') ? null : 'Enter an email.',
        ),
      );
      await tester.enterText(find.byType(TextField), 'nope');
      await tester.pump();
      expect(find.text('Enter an email.'), findsOneWidget);
    });
  });

  testWidgets('AppSearchField clears and reports an empty query', (tester) async {
    final queries = <String>[];
    await pumpThemed(tester, AppSearchField(onChanged: queries.add));
    await tester.enterText(find.byType(TextField), 'asha');
    await tester.pump();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(queries, ['asha', '']);
    expect(find.text('asha'), findsNothing);
  });

  testWidgets('AppSelectField opens a sheet and reports the chosen value', (tester) async {
    String? chosen;
    await pumpThemed(
      tester,
      AppSelectField<String>(
        label: 'Level',
        value: null,
        onChanged: (v) => chosen = v,
        options: const [SelectOption('b', 'Beginner'), SelectOption('a', 'Advanced')],
      ),
    );
    expect(find.text('Select'), findsOneWidget);
    await tester.tap(find.byType(AppSelectField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    expect(chosen, 'a');
  });

  testWidgets('AppSwitchRow with a locked reason cannot be toggled', (tester) async {
    var changed = false;
    await pumpThemed(
      tester,
      AppSwitchRow(
        title: 'In-app',
        value: true,
        onChanged: (_) => changed = true,
        lockedReason: 'Always on.',
      ),
    );
    await tester.tap(find.byType(Switch));
    expect(changed, isFalse);
    expect(find.text('Always on.'), findsOneWidget);
  });

  testWidgets('AppRadioGroup reports the tapped option', (tester) async {
    String? picked;
    await pumpThemed(
      tester,
      AppRadioGroup<String>(
        label: 'Cycle',
        value: 'm',
        onChanged: (v) => picked = v,
        options: const [RadioOption('m', 'Monthly'), RadioOption('y', 'Annual')],
      ),
    );
    await tester.tap(find.text('Annual'));
    expect(picked, 'y');
  });

  testWidgets('AppDateTimeField shows the formatted instant', (tester) async {
    await pumpThemed(
      tester,
      AppDateTimeField(
        label: 'Starts',
        value: DateTime.utc(2026, 9, 22, 18, 30),
        format: (d) =>
            'IST ${Ist.wallClock(d).day}/${Ist.wallClock(d).month} ${Ist.wallClock(d).hour}h',
        onChanged: (_) {},
      ),
    );
    expect(find.text('IST 23/9 0h'), findsOneWidget);
  });

  group('AppFilePickerTile', () {
    testWidgets('while uploading shows progress and a cancel action', (tester) async {
      var cancelled = false;
      await pumpThemed(
        tester,
        AppFilePickerTile(
          name: 'a.pdf',
          sizeLabel: '2 MB',
          progress: 0.5,
          onCancel: () => cancelled = true,
        ),
      );
      expect(find.text('Uploading 50%'), findsOneWidget);
      await tester.tap(find.byTooltip('Cancel upload'));
      expect(cancelled, isTrue);
    });

    testWidgets('after a failure keeps the file and offers a retry', (tester) async {
      var retried = false;
      await pumpThemed(
        tester,
        AppFilePickerTile(
          name: 'a.pdf',
          sizeLabel: '2 MB',
          failed: true,
          onRetry: () => retried = true,
        ),
      );
      expect(find.text('a.pdf'), findsOneWidget);
      expect(find.text('Upload failed — try again'), findsOneWidget);
      await tester.tap(find.byTooltip('Try again'));
      expect(retried, isTrue);
    });
  });

  testWidgets('FilterChipBar selects a chip and announces its count', (tester) async {
    String? selected;
    final handle = tester.ensureSemantics();
    await pumpThemed(
      tester,
      FilterChipBar<String>(
        selected: 'a',
        onSelected: (v) => selected = v,
        options: const [
          FilterOption('a', 'To review', count: 12),
          FilterOption('b', 'Graded', count: 4),
        ],
      ),
    );
    expect(find.bySemanticsLabel('Graded, 4'), findsOneWidget);
    await tester.tap(find.text('Graded'));
    expect(selected, 'b');
    handle.dispose();
  });

  testWidgets('FormErrorSummary counts issues and focuses the field on tap', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await pumpThemed(
      tester,
      Column(
        children: [
          FormErrorSummary(
            issues: [
              FormIssue(fieldLabel: 'Title', message: 'Enter a title.', focusNode: node),
              const FormIssue(message: 'Something else.'),
            ],
          ),
          TextField(focusNode: node),
        ],
      ),
    );
    expect(find.text('Fix 2 problems to continue'), findsOneWidget);
    await tester.tap(find.text('Title: Enter a title.'));
    await tester.pump();
    expect(node.hasFocus, isTrue);
  });

  group('Ist', () {
    test('18:30 UTC is midnight the next day in IST', () {
      final wall = Ist.wallClock(DateTime.utc(2026, 9, 22, 18, 30));
      expect([wall.year, wall.month, wall.day, wall.hour, wall.minute], [2026, 9, 23, 0, 0]);
    });

    test('an IST wall-clock reading converts back to the same instant', () {
      expect(Ist.instantFromWallClock(2026, 9, 23), DateTime.utc(2026, 9, 22, 18, 30));
    });
  });
}
