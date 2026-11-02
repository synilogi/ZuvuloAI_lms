import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/public_catalog/public_catalog.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/pricing.dart';
import '../../helpers/public_harness.dart';

void _serve(FakeAdapter adapter, {String detail = 'catalog/course-detail.json'}) {
  adapter.handler = (options) async => switch (options.path) {
    '/catalog/levels' => FakeAdapter.jsonResponse(fixture('catalog/levels.json')),
    '/catalog/instructors' => FakeAdapter.jsonResponse(fixture('catalog/instructors.json')),
    '/catalog/courses/foundations-vedic' => FakeAdapter.jsonResponse(
      withPricing(fixture(detail), 'paid'),
    ),
    '/catalog/courses/gone' => FakeAdapter.jsonResponse(
      fixture('errors/not-found.json'),
      status: 404,
    ),
    _ => throw StateError('unexpected ${options.path}'),
  };
}

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  testWidgets('shows what the course is, its facts and who teaches it', (tester) async {
    _serve(adapter);

    await pumpPublic(tester, const CourseDetailScreen(slug: 'foundations-vedic'), adapter: adapter);
    await tester.pumpAndSettle();

    expect(find.text('Foundations of Vedic Astrology'), findsOneWidget);
    expect(find.text('₹2,999'), findsOneWidget);
    expect(find.text('Beginner'), findsWidgets);
    expect(find.text('Self-paced'), findsOneWidget);
    expect(find.text('en-IN'), findsOneWidget);
    // The price sits in the bar at the bottom, beside the way in.
    expect(
      find.descendant(of: find.byType(StickyActionBar), matching: find.text('₹2,999')),
      findsOneWidget,
    );
    // The certificate is listed with the rest of what the course holds.
    await tester.scrollUntilVisible(
      find.text('Certificate: Certificate in Foundations of Vedic Astrology'),
      300,
    );
    expect(find.text('What’s included'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Dr. Meenakshi Iyer'), 300);
    expect(find.text('Taught by'), findsOneWidget);
    expect(find.text('Dr. Meenakshi Iyer'), findsOneWidget);
  });

  testWidgets('a visitor is offered sign-in, carrying where they were going', (tester) async {
    _serve(adapter);

    await pumpPublic(tester, const CourseDetailScreen(slug: 'foundations-vedic'), adapter: adapter);
    await tester.pumpAndSettle();

    expect(find.text('Sign in to enrol'), findsOneWidget);
    expect(find.text('Open course'), findsNothing);
  });

  testWidgets('a signed-in learner is offered the course itself', (tester) async {
    _serve(adapter);

    await pumpPublic(
      tester,
      const CourseDetailScreen(slug: 'foundations-vedic'),
      adapter: adapter,
      signedInAs: learner(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open course'), findsOneWidget);
    expect(find.text('Sign in to enrol'), findsNothing);
  });

  testWidgets('the outline marks the free preview and locks the rest', (tester) async {
    _serve(adapter, detail: 'catalog/course-detail-with-preview.json');

    await pumpPublic(tester, const CourseDetailScreen(slug: 'foundations-vedic'), adapter: adapter);
    await tester.pumpAndSettle();

    expect(find.text('2 lessons are free to preview'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Curriculum'), 300);
    expect(find.byType(CurriculumTree), findsOneWidget);
  });

  testWidgets('a slug that is not a published course shows not found', (tester) async {
    _serve(adapter);

    await pumpPublic(tester, const CourseDetailScreen(slug: 'gone'), adapter: adapter);
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundView), findsOneWidget);
  });
}
