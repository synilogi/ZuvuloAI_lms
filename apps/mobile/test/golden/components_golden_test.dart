@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/theme/theme.dart';
import 'package:syniastrolms_mobile/dev/gallery/gallery_entries.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../helpers/pump.dart';

/// Golden images of the design-system components (FLUTTER-001 acceptance), light and dark, at
/// compact width with reduced motion so animations are settled. Generated on macOS with the
/// bundled fonts loaded (test/flutter_test_config.dart); regenerate with
/// `flutter test --update-goldens test/golden` after an intended visual change.
const _specimens = {
  'buttons': 'AppButton variants',
  'inputs': 'AppTextField states',
  'cards': 'AppCard + SectionHeader',
  'lists': 'GroupedList of AppListTile',
  'status_badges': 'StatusBadge — every status',
  'progress_ring': 'ProgressRing and ProgressBar',
  'kpi_tile': 'KpiTile',
  'course_covers': 'CourseCover motifs',
  'dialog': 'AppDialog (inline)',
  'error_state': 'ErrorState',
  'empty_state': 'EmptyState',
  'permission_denied': 'PermissionDeniedView',
  'feature_unavailable': 'FeatureUnavailableView (member / admin)',
  'not_found': 'NotFoundView',
};

GalleryEntry _entry(String name) => galleryEntries.firstWhere((e) => e.name == name);

void main() {
  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';
    for (final specimen in _specimens.entries) {
      testWidgets('${specimen.key} $theme', (tester) async {
        await pumpThemed(
          tester,
          RepaintBoundary(
            key: const Key('golden'),
            child: Builder(builder: _entry(specimen.value).builder),
          ),
          dark: dark,
          reduceMotion: true,
          size: const Size(360, 1400),
        );
        await expectLater(
          find.byKey(const Key('golden')),
          matchesGoldenFile('goldens/${specimen.key}_$theme.png'),
        );
      });
    }

    testWidgets('bottom_sheet $theme', (tester) async {
      await pumpThemed(
        tester,
        RepaintBoundary(
          key: const Key('golden'),
          child: Builder(
            builder: (context) => Material(
              color: context.colors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
              ),
              child: FilterSheet(
                title: 'Filter students',
                onApply: () {},
                onReset: () {},
                children: const [
                  AppTextField(label: 'Course', initialValue: 'Foundations of Jyotish'),
                  AppSwitchRow(title: 'At risk only', value: true, onChanged: null),
                ],
              ),
            ),
          ),
        ),
        dark: dark,
        reduceMotion: true,
      );
      await expectLater(
        find.byKey(const Key('golden')),
        matchesGoldenFile('goldens/bottom_sheet_$theme.png'),
      );
    });
  }
}
