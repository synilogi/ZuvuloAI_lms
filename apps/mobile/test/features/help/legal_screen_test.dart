import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/help/help.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

/// The academy publishes one policy text on the web; the app shows that page inside itself, without
/// the site's header and footer, rather than shipping a copy that could fall out of date.
void main() {
  /// The platform web view has no implementation under test: this one shows what it would load.
  Widget withView(Widget screen) => ProviderScope(
    overrides: [legalPageViewProvider.overrideWithValue((url) => Text('view:$url'))],
    child: screen,
  );

  testWidgets('the privacy policy is shown in the app, with the app\'s own title', (tester) async {
    final adapter = FakeAdapter();

    await pumpPublic(
      tester,
      withView(const LegalScreen(document: LegalDocument.privacy)),
      adapter: adapter,
    );
    await tester.pumpAndSettle();

    expect(find.text('Privacy policy'), findsOneWidget, reason: 'the title bar');
    expect(find.text('view:https://web.test/privacy?embed=app'), findsOneWidget);
    expect(find.text('Open on the web'), findsNothing, reason: 'nothing leaves the app');
    expect(adapter.requests, isEmpty, reason: 'no endpoint serves the policy');
  });

  testWidgets('the terms are shown in the app', (tester) async {
    await pumpPublic(
      tester,
      withView(const LegalScreen(document: LegalDocument.terms)),
      adapter: FakeAdapter(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Terms of use'), findsOneWidget);
    expect(find.text('view:https://web.test/terms?embed=app'), findsOneWidget);
  });

  test('each document points at the path the web app serves, without its header and footer', () {
    // `apps/web/src/app/router.tsx` serves `/privacy` and `/terms`; `?embed=app` drops the chrome.
    final web = Uri.parse('https://zuviloai.com');
    expect(
      legalPageUrl(web, LegalDocument.privacy).toString(),
      'https://zuviloai.com/privacy?embed=app',
    );
    expect(
      legalPageUrl(web, LegalDocument.terms).toString(),
      'https://zuviloai.com/terms?embed=app',
    );
  });

  test('only another policy on the same site opens inside the app', () {
    final web = Uri.parse('https://zuviloai.com');
    bool stays(String url) => legalPageStaysInApp(Uri.parse(url), web);

    expect(stays('https://zuviloai.com/privacy?embed=app'), isTrue);
    expect(stays('https://zuviloai.com/terms'), isTrue);
    expect(stays('https://zuviloai.com/pricing'), isFalse, reason: 'the rest of the site');
    expect(stays('https://zuviloai.com/'), isFalse);
    expect(stays('http://zuviloai.com/privacy'), isFalse, reason: 'never in the clear');
    expect(stays('https://evil.example/privacy'), isFalse, reason: 'another site');
    expect(stays('mailto:support@zuviloai.com'), isFalse);
  });
}
