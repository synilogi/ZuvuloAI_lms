import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/media/media_auth_headers.dart';
import 'package:syniastrolms_mobile/shared/widgets/learning/course_cover.dart';

import '../../helpers/pump.dart';
import '../../helpers/test_config.dart';

/// The uploaded cover is laid over the motif; anything that is not one of the API's own image
/// paths draws the motif alone, in the same box.
void main() {
  Future<void> pumpCover(WidgetTester tester, String? imageUrl) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(testConfig()),
          mediaAuthHeadersProvider.overrideWith((ref) async => const <String, String>{}),
        ],
        child: themedHarness(
          SizedBox(
            width: 320,
            child: CourseCover(motif: CoverMotif.houses, imageUrl: imageUrl),
          ),
          scroll: false,
        ),
      ),
    );
    await tester.pump();
  }

  Size coverSize(WidgetTester tester) => tester.getSize(find.byType(CourseCover));

  testWidgets('no image, an empty one, or another host: the motif alone, at the same size', (
    tester,
  ) async {
    await pumpCover(tester, null);
    final plain = coverSize(tester);
    expect(find.byType(CachedNetworkImage), findsNothing);

    for (final url in ['', 'https://elsewhere.example/catalog/covers/x', '//elsewhere.example/x']) {
      await pumpCover(tester, url);
      expect(find.byType(CachedNetworkImage), findsNothing, reason: url);
      expect(coverSize(tester), plain, reason: url);
    }
  });

  testWidgets('an API cover path is fetched over the motif, without moving the layout', (
    tester,
  ) async {
    await pumpCover(tester, null);
    final plain = coverSize(tester);
    await pumpCover(tester, '/catalog/covers/abc123');
    final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(image.imageUrl, endsWith('/catalog/covers/abc123'));
    expect(image.fit, BoxFit.cover);
    expect(coverSize(tester), plain);
    // The motif stays painted beneath, as the placeholder and the fallback.
    expect(
      find.descendant(of: find.byType(CourseCover), matching: find.byType(CustomPaint)),
      findsWidgets,
    );
  });
}
