import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/app.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/theme/theme.dart';
import 'package:syniastrolms_mobile/dev/gallery/gallery_screen.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/shared/widgets/navigation/app_nav_bar.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_auth_repository.dart';

const _learner = UserProfile(
  id: 'u1',
  name: 'Asha Verma',
  email: 'asha@syniastrolms.test',
  role: UserRole.student,
  descriptor: 'Learner',
);

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  Future<void> pumpApp(
    WidgetTester tester, {
    Flavor flavor = Flavor.dev,
    Map<String, WidgetBuilder> devRoutes = const {},
  }) async {
    useSurface(tester);
    await tester.pumpWidget(
      await testApp(repository: repository, flavor: flavor, devRoutes: devRoutes),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('a signed-out launch shows the welcome screen', (tester) async {
    await pumpApp(tester);

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text(kAppName), findsNothing, reason: 'the welcome screen leads with the tagline');
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('no flavor shows the debug banner', (tester) async {
    await pumpApp(tester);
    expect(find.byType(CheckedModeBanner), findsNothing);

    await pumpApp(tester, flavor: Flavor.prod);
    expect(find.byType(CheckedModeBanner), findsNothing);
  });

  testWidgets('the app uses the Celestial Ink themes', (tester) async {
    await pumpApp(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      app.theme?.extension<AppColors>()?.accent,
      AppTheme.light().extension<AppColors>()?.accent,
    );
    expect(app.darkTheme?.brightness, Brightness.dark);
  });

  Future<void> openProfile(WidgetTester tester) async {
    await tester.pumpAndSettle();
    // Profile is a tab of the learner's bar.
    await tester.tap(
      find.descendant(of: find.byType(AppNavBar), matching: find.text('Profile')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('prod builds have no developer gallery', (tester) async {
    repository.profile = _learner;
    repository.token = 'stored-token';

    await pumpApp(tester, flavor: Flavor.prod);
    await openProfile(tester);

    expect(find.text('Asha Verma'), findsOneWidget);
    expect(find.text('Component gallery'), findsNothing);
  });

  testWidgets('the dev entry point can reach the component gallery', (tester) async {
    repository.profile = _learner;
    repository.token = 'stored-token';

    await pumpApp(tester, devRoutes: {GalleryScreen.routeName: (_) => const GalleryScreen()});
    await openProfile(tester);
    // The gallery link is the last row of the profile's links; scrolling to the end of the page
    // brings it clear of the bottom navigation before tapping it.
    await tester.scrollUntilVisible(
      find.text('Delete account'),
      200,
      // The page itself — the activity card inside it has a scrollable of its own.
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Component gallery'));
    // The gallery shows perpetual animations (live dot, busy spinner), so it never settles;
    // pump past the route transition instead.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(GalleryScreen), findsOneWidget);
  });

  test('main_prod.dart and main_staging.dart do not reference developer screens', () {
    for (final entry in ['lib/main_prod.dart', 'lib/main_staging.dart']) {
      expect(File(entry).readAsStringSync(), isNot(contains('dev/')), reason: entry);
    }
  });
}
