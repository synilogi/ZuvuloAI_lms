import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/theme/theme.dart';
import 'package:syniastrolms_mobile/features/public_catalog/public_catalog.dart';
import 'package:syniastrolms_mobile/l10n/generated/app_localizations_en.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/pricing.dart';
import '../../helpers/public_harness.dart';

/// The catalogue's courses as the seed serves them.
List<Map<String, dynamic>> _courses() {
  final raw = withPricing(jsonDecode(jsonEncode(fixture('catalog/courses.json'))), 'paid');
  final list = raw is List ? raw : (raw as Map<String, dynamic>)['courses'] as List<dynamic>;
  return [for (final c in list) c as Map<String, dynamic>];
}

Course _course(String slug) => Course.fromJson(_courses().firstWhere((c) => c['slug'] == slug));

void main() {
  final l10n = AppLocalizationsEn();

  group('what a course includes', () {
    test('is counted from its own outline, and nothing it lacks is listed', () {
      // Foundations: 2 videos, 2 readings + 1 practice, 1 quiz, 1 assignment, 1 live session,
      // one lesson open as a free preview.
      final lines = [
        for (final (_, label) in CourseIncludes.linesFor(l10n, _course('foundations-vedic'))) label,
      ];
      expect(lines, [
        '2 video lessons',
        '3 readings',
        '1 test',
        '1 assignment',
        '1 live class',
        '1 lesson free to preview',
        'Certificate: Certificate in Foundations of Vedic Astrology',
      ]);
      expect(lines.any((l) => l.contains('PDF')), isFalse, reason: 'no documents in the outline');
    });

    test('says one, not ones', () {
      final lines = [
        for (final (_, label) in CourseIncludes.linesFor(l10n, _course('kp-fundamentals'))) label,
      ];
      expect(lines, containsAll(['1 video lesson', '1 reading']));
    });
  });

  group('the catalogue card', () {
    late FakeAdapter adapter;
    setUp(() => adapter = FakeAdapter());

    Future<List<int>> pumpCard(WidgetTester tester, {bool enrolled = false}) async {
      final taps = <int>[];
      await pumpPublic(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: CourseCard(
              course: _course('foundations-vedic'),
              levelName: 'Beginner',
              instructorNames: const ['Dr. Meenakshi Iyer'],
              enrolled: enrolled,
              onTap: () => taps.add(1),
            ),
          ),
        ),
        adapter: adapter,
      );
      await tester.pumpAndSettle();
      return taps;
    }

    testWidgets('shows the academy\'s price and one button that opens the course', (tester) async {
      final taps = await pumpCard(tester);

      expect(find.text('₹2,999'), findsOneWidget);
      expect(find.text('Beginner'), findsOneWidget);
      expect(
        find.textContaining('Off'),
        findsNothing,
        reason: 'there is no list price to discount',
      );
      await tester.tap(find.widgetWithText(AppButton, 'View course'));
      expect(taps, hasLength(1));
    });

    testWidgets('the price is at the start of its row and the button at the far end', (
      tester,
    ) async {
      await pumpCard(tester);

      final card = tester.getRect(find.byType(CourseCard));
      final button = tester.getRect(find.widgetWithText(AppButton, 'View course'));
      final price = tester.getRect(find.text('₹2,999'));
      expect(button.top, closeTo(price.top, button.height), reason: 'one row');
      // Within the card's own padding of its right edge.
      expect(card.right - button.right, lessThan(Space.s6));
    });

    testWidgets('a course already joined says so and continues', (tester) async {
      await pumpCard(tester, enrolled: true);

      expect(find.widgetWithText(AppButton, 'Continue'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'View course'), findsNothing);
      expect(find.byType(StatusBadge), findsOneWidget);
    });

    testWidgets('fits at 200% text on a small phone', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpCard(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('View course'), findsOneWidget);
    });
  });
}
