import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/pump.dart';

String? _asset(WidgetTester tester) =>
    (tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName;

/// The pixel size of a PNG file, read from its header.
Size _pngSize(String path) {
  final header = ByteData.sublistView(File(path).readAsBytesSync(), 16, 24);
  return Size(header.getUint32(0).toDouble(), header.getUint32(4).toDouble());
}

void main() {
  group('the bundled ZuviloAI artwork', () {
    testWidgets('every brand asset ships in the app bundle and decodes', (tester) async {
      for (final path in [BrandAssets.mark, BrandAssets.full, BrandAssets.fullDark]) {
        final data = await tester.runAsync(() => rootBundle.load(path));
        final codec = await tester.runAsync(
          () => ui.instantiateImageCodec(data!.buffer.asUint8List()),
        );
        expect(codec!.frameCount, 1, reason: path);
      }
    });

    testWidgets('the logo uses the light artwork on a light theme', (tester) async {
      await pumpThemed(tester, const BrandLogo());
      expect(_asset(tester), BrandAssets.full);
    });

    testWidgets('the logo uses the dark artwork on a dark theme', (tester) async {
      await pumpThemed(tester, const BrandLogo(), dark: true);
      expect(_asset(tester), BrandAssets.fullDark);
    });

    testWidgets('the logo keeps its proportions: only its width is set', (tester) async {
      await pumpThemed(tester, const BrandLogo(width: 160));
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, 160);
      expect(image.height, isNull);
      expect(image.fit, BoxFit.contain);
    });

    testWidgets('the mark is a square of the size asked for, and is not announced', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpThemed(tester, const BrandMark(size: 56));
      expect(_asset(tester), BrandAssets.mark);
      expect(tester.getSize(find.byType(Image)), const Size(56, 56));
      expect(tester.widget<Image>(find.byType(Image)).excludeFromSemantics, isTrue);
      handle.dispose();
    });
  });

  group('the auth frame', () {
    testWidgets('shows the mark above the title only where asked', (tester) async {
      await tester.pumpWidget(
        themedHarness(
          const AuthScaffold(brand: true, title: 'Sign in', children: []),
          scroll: false,
        ),
      );
      expect(find.byType(BrandMark), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(BrandMark)).dy,
        lessThan(tester.getTopLeft(find.text('Sign in')).dy),
      );

      await tester.pumpWidget(
        themedHarness(const AuthScaffold(title: 'Join', children: []), scroll: false),
      );
      expect(find.byType(BrandMark), findsNothing);
    });
  });

  group('the Android launcher icon', () {
    const res = 'android/app/src/main/res';
    const densities = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};

    test(
      'has every density of the legacy, foreground and monochrome layers, at the right size',
      () {
        for (final MapEntry(key: name, value: scale) in densities.entries) {
          expect(
            _pngSize('$res/mipmap-$name/ic_launcher.png'),
            Size.square(48 * scale),
            reason: name,
          );
          for (final layer in ['ic_launcher_foreground', 'ic_launcher_monochrome']) {
            expect(
              _pngSize('$res/mipmap-$name/$layer.png'),
              Size.square(108 * scale),
              reason: '$name $layer',
            );
          }
        }
        expect(_pngSize('store/play_store_icon_512.png'), const Size.square(512));
      },
    );

    test('is an adaptive icon over the logo’s white ground', () {
      final adaptive = File('$res/mipmap-anydpi-v26/ic_launcher.xml').readAsStringSync();
      expect(adaptive, contains('@mipmap/ic_launcher_foreground'));
      expect(adaptive, contains('@mipmap/ic_launcher_monochrome'));
      expect(adaptive, contains('@color/ic_launcher_background'));
      expect(
        File('$res/values/ic_launcher_background.xml').readAsStringSync(),
        contains('#FFFFFF'),
      );
    });
  });
}
