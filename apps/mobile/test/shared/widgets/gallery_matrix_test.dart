import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/dev/gallery/gallery_entries.dart';

import '../../helpers/pump.dart';

/// Every gallery specimen — i.e. every component in its states — rendered in light and dark at
/// 100 % and 200 % text scale on a 360 dp phone: no overflow or exception (any layout overflow
/// fails the test), tap targets ≥ 48 dp and every tappable element labelled.
void main() {
  for (final entry in galleryEntries) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        final variant = '${dark ? 'dark' : 'light'} ${(scale * 100).round()}%';
        testWidgets('${entry.group} / ${entry.name} — $variant', (tester) async {
          final semantics = tester.ensureSemantics();
          await pumpThemed(
            tester,
            Builder(builder: entry.builder),
            dark: dark,
            textScale: scale,
            reduceMotion: true,
          );
          expect(tester.takeException(), isNull);
          if (scale == 1.0) {
            await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
            await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          }
          semantics.dispose();
        });
      }
    }
  }

  test('every public component in lib/shared/widgets has a gallery entry', () {
    final gallery = File('lib/dev/gallery/gallery_entries.dart').readAsStringSync();
    // Building blocks shown through the component that composes them.
    const composedOnly = {
      'StateLayout': 'EmptyState, ErrorState and every state view',
      'SelectSheet': 'AppSelectField',
      'AppBottomSheet': 'FilterSheet',
      'AppIcon': 'every icon in the gallery',
      'FieldLabel': 'AppTextField, AppSelectField and AppDateTimeField',
      'LabelledField': 'AppTextField, AppSelectField and AppDateTimeField',
    };
    final missing = <String>[];
    final classPattern = RegExp(
      r'^class ([A-Z]\w*) extends (StatelessWidget|StatefulWidget)',
      multiLine: true,
    );
    for (final file in Directory(
      'lib/shared/widgets',
    ).listSync(recursive: true).whereType<File>()) {
      for (final match in classPattern.allMatches(file.readAsStringSync())) {
        final name = match.group(1)!;
        if (composedOnly.containsKey(name)) continue;
        if (!RegExp('\\b$name\\b').hasMatch(gallery)) missing.add(name);
      }
    }
    expect(missing, isEmpty, reason: 'No gallery entry for: ${missing.join(', ')}');
  });
}
