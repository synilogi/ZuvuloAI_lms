import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/dev/gallery/gallery_screen.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('gallery toggles switch the theme, text scale and width', (tester) async {
    await pumpThemed(tester, const GalleryScreen(), scroll: false, size: const Size(800, 1000));

    Brightness brightness() => Theme.of(tester.element(find.text('Actions'))).brightness;
    double textScale() =>
        MediaQuery.textScalerOf(tester.element(find.text('Actions'))).scale(10) / 10;
    double contentWidth() => tester.getSize(find.byType(ListView)).width;

    expect(brightness(), Brightness.light);
    expect(contentWidth(), 400);

    await tester.tap(find.text('Dark'));
    await tester.pump();
    expect(brightness(), Brightness.dark);

    await tester.tap(find.text('200%'));
    await tester.pump();
    expect(textScale(), 2);

    await tester.tap(find.text('Medium width'));
    await tester.pump();
    expect(contentWidth(), 720);
  });
}
