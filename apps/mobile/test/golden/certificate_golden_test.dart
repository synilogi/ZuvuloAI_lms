@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/certificates/certificates.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../helpers/pump.dart';

/// The certificate canvas drawn from a **real** captured certificate and its template, light and
/// dark, at phone width and in landscape (FLUTTER-014 acceptance). The paper itself is always drawn
/// in the light palette — it is a document — so the two themes differ only in the page around it.
///
/// Regenerate with `flutter test --update-goldens test/golden` after an intended visual change.
CertificateDetail _detail() => CertificateDetail.fromJson(
  jsonDecode(File('test/fixtures/learning/certificate-issued.json').readAsStringSync())
      as Map<String, dynamic>,
);

void main() {
  final sizes = {'portrait': const Size(360, 800), 'landscape': const Size(800, 360)};

  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';
    for (final size in sizes.entries) {
      testWidgets('certificate_canvas_${size.key} $theme', (tester) async {
        final detail = _detail();
        await pumpThemed(
          tester,
          RepaintBoundary(
            key: const Key('golden'),
            child: Builder(
              builder: (context) => CertificateCanvas(
                data: canvasDataOf(context, detail, detail.template!),
                semanticLabel: detail.certificate.title,
              ),
            ),
          ),
          dark: dark,
          reduceMotion: true,
          size: size.value,
        );
        await expectLater(
          find.byKey(const Key('golden')),
          matchesGoldenFile('goldens/certificate_canvas_${size.key}_$theme.png'),
        );
      });
    }
  }

  testWidgets('the canvas stays legible at the largest text size', (tester) async {
    final detail = _detail();
    await pumpThemed(
      tester,
      Builder(
        builder: (context) => CertificateCanvas(
          data: canvasDataOf(context, detail, detail.template!),
          semanticLabel: detail.certificate.title,
        ),
      ),
      textScale: 2,
      reduceMotion: true,
    );

    // The paper is drawn at its design size and scaled to fit, so a larger text setting cannot
    // overflow it — and the drawn text keeps its proportions.
    expect(tester.takeException(), isNull);
    final canvas = tester.getSize(find.byType(CertificateCanvas));
    expect(canvas.width / canvas.height, closeTo(CertificateCanvas.designSize.aspectRatio, 0.01));
  });
}
