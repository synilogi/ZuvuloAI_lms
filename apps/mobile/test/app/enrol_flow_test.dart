import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/app.dart';
import 'package:syniastrolms_mobile/app/routing/app_router.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/shared/widgets/navigation/app_nav_bar.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_adapter.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/pricing.dart';
import '../helpers/public_harness.dart';

const _learner = UserProfile(
  id: 'u1',
  name: 'Ananya Rao',
  email: 'ananya@syniastrolms.test',
  role: UserRole.student,
  descriptor: 'Learner',
);

const _courseId = 'cmudqd8g30035mmgzwtgr0mcl';

Map<String, dynamic> _copy(String path) =>
    jsonDecode(jsonEncode(fixture(path))) as Map<String, dynamic>;

void main() {
  late FakeAuthRepository repository;
  late FakeAdapter adapter;

  setUp(() {
    repository = FakeAuthRepository()..profile = _learner;
    adapter = FakeAdapter();
  });

  String locationIn(WidgetTester tester) {
    final container = ProviderScope.containerOf(tester.element(find.byType(SyniastroApp)));
    return container.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();
  }

  testWidgets('enrolling from the Courses tab puts the course into My Courses, with no restart', (
    tester,
  ) async {
    // The server's state, as the app will find it before and after enrolling.
    final workspaceBefore = _copy('learning/courses.json');
    final workspaceAfter = _copy('learning/courses-with-saved.json');
    // A free course: Enrol opens it (a paid one is bought instead).
    final detail = withPricing(_copy('learning/course-detail-not-enrolled.json'), 'free');
    var enrolled = false;

    adapter.handler = (options) async {
      final path = options.path;
      if (path == '/learning/courses' && options.method == 'GET') {
        return FakeAdapter.jsonResponse(enrolled ? workspaceAfter : workspaceBefore);
      }
      if (path.endsWith('/enroll')) {
        enrolled = true;
        return FakeAdapter.jsonResponse(fixture('learning/enroll.json'));
      }
      if (path.startsWith('/learning/courses/')) {
        return FakeAdapter.jsonResponse({...detail, 'enrolled': enrolled});
      }
      return FakeAdapter.jsonResponse(switch (path) {
        '/learning/home' => fixture('learning/home.json'),
        '/catalog/levels' => fixture('catalog/levels.json'),
        '/catalog/categories' => fixture('catalog/categories.json'),
        '/catalog/instructors' => fixture('catalog/instructors.json'),
        '/catalog/courses' => fixture('catalog/courses.json'),
        // Home reads the live schedule for its next-class card.
        '/live/learner' => fixture('live/learner.json'),
        _ => throw StateError('unexpected $path'),
      });
    };

    useSurface(tester);
    await tester.pumpWidget(await testApp(repository: repository, adapter: adapter));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'ananya@syniastrolms.test');
    await tester.enterText(find.byType(TextField).at(1), 'syniastrolms123');
    await tester.tap(find.widgetWithText(AppButton, 'Sign in'));
    await tester.pumpAndSettle();

    Finder inBar(String label) =>
        find.descendant(of: find.byType(AppNavBar), matching: find.text(label));

    // The Courses tab is the catalogue → the course the learner has not joined.
    await tester.tap(inBar('Courses'));
    await tester.pumpAndSettle();
    expect(locationIn(tester), '/explore');

    await tester.scrollUntilVisible(
      find.text('Jaimini Astrology: Chara Karakas'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jaimini Astrology: Chara Karakas'));
    await tester.pumpAndSettle();
    expect(locationIn(tester), '/learn/$_courseId');

    await tester.tap(find.text('Enrol'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Enrol').last);
    await tester.pumpAndSettle();

    expect(find.text('You are enrolled. The course is in My Courses.'), findsOneWidget);

    // My Courses (under Profile) was read again, without the app being restarted.
    await tester.tap(inBar('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Courses'));
    await tester.pumpAndSettle();
    expect(locationIn(tester), '/my-learning/in-progress');
    expect(
      adapter.requests.where((r) => r.path == '/learning/courses').length,
      greaterThan(1),
      reason: 'the workspace is re-read after enrolling',
    );
  });
}
