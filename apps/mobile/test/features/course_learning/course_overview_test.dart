import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/course_learning/course_learning.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/pricing.dart';
import '../../helpers/public_harness.dart';

const _courseId = 'cmudqd8g30035mmgzwtgr0mcl';

/// A course as `GET /learning/courses/:id` serves it — free unless the test says otherwise (paid
/// courses are covered in course_purchase_test.dart).
Map<String, dynamic> _detail(String name, {String pricing = 'free'}) => withPricing(
  jsonDecode(jsonEncode(fixture('learning/$name.json'))) as Map<String, dynamic>,
  pricing,
);

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  /// The overview needs the course and, for the instructor rows, the public instructor list.
  void serve(Map<String, dynamic> detail) {
    adapter.handler = (options) async => switch (options.path) {
      '/catalog/instructors' => FakeAdapter.jsonResponse(fixture('catalog/instructors.json')),
      _ => FakeAdapter.jsonResponse(detail),
    };
  }

  Future<GoRouter> pumpOverview(
    WidgetTester tester, {
    String id = _courseId,
    Size size = const Size(400, 900),
  }) => pumpPublicRouter(
    tester,
    adapter: adapter,
    size: size,
    signedInAs: learner(),
    initialLocation: AppRoutes.learnCourse(id),
    routes: [
      GoRoute(
        path: AppRoutes.learnCoursePattern,
        builder: (_, state) => Scaffold(
          body: SafeArea(
            child: CourseOverviewScreen(courseId: state.pathParameters['courseId'] ?? ''),
          ),
        ),
      ),
      GoRoute(path: AppRoutes.explore, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.learnLessonPattern, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.catalogPreviewPattern, builder: (_, _) => const Placeholder()),
    ],
  );

  testWidgets('a free course the learner has not joined says so, with the way in', (tester) async {
    serve(_detail('course-detail-not-enrolled'));

    await pumpOverview(tester);
    await tester.pumpAndSettle();

    expect(find.text('Jaimini Astrology: Chara Karakas'), findsOneWidget);
    // "Free" sits beside Enrol in the bar at the bottom — a free course's stored price is not
    // shown as something to pay; Save is by the title.
    expect(
      find.descendant(of: find.byType(StickyActionBar), matching: find.text('Free')),
      findsOneWidget,
    );
    expect(find.text('₹4,999'), findsNothing);
    expect(find.text('Enrol'), findsOneWidget);
    expect(find.byTooltip('Save this course'), findsOneWidget);
    expect(find.text('Advanced'), findsWidgets);
  });

  testWidgets('an enrolled course shows progress instead of a price, and no enrol bar', (
    tester,
  ) async {
    serve(_detail('course-detail-enrolled'));

    await pumpOverview(tester);
    await tester.pumpAndSettle();

    expect(find.byType(ProgressRing), findsOneWidget);
    expect(find.text('1 of 4 lessons'), findsOneWidget);
    expect(find.text('Enrol'), findsNothing);
    expect(find.byType(StickyActionBar), findsNothing);
  });

  group('the order of the page', () {
    // Tall enough that the whole page is laid out, so sections can be compared by position.
    const tall = Size(400, 6000);
    double y(WidgetTester tester, String header) =>
        tester.getTopLeft(find.widgetWithText(SectionHeader, header)).dy;

    testWidgets('enrolled, the outline comes before what the course is about', (tester) async {
      serve(_detail('course-detail-enrolled'));
      await pumpOverview(tester, size: tall);
      await tester.pumpAndSettle();

      expect(y(tester, 'Next up'), lessThan(y(tester, 'Curriculum')));
      expect(y(tester, 'Curriculum'), lessThan(y(tester, 'About this course')));
    });

    testWidgets('before enrolling, what the course is about comes first', (tester) async {
      serve(_detail('course-detail-not-enrolled'));
      await pumpOverview(tester, size: tall);
      await tester.pumpAndSettle();

      expect(y(tester, 'About this course'), lessThan(y(tester, 'Curriculum')));
    });
  });

  testWidgets('enrolling asks first, then says so and keeps the page in step', (tester) async {
    final notEnrolled = _detail('course-detail-not-enrolled');
    var enrolled = false;
    adapter.handler = (options) async {
      if (options.path == '/catalog/instructors') {
        return FakeAdapter.jsonResponse(fixture('catalog/instructors.json'));
      }
      if (options.path.endsWith('/enroll')) {
        enrolled = true;
        return FakeAdapter.jsonResponse(fixture('learning/enroll.json'));
      }
      if (options.path.startsWith('/learning/courses/$_courseId')) {
        return FakeAdapter.jsonResponse({...notEnrolled, 'enrolled': enrolled});
      }
      return FakeAdapter.jsonResponse(fixture('learning/courses.json'));
    };

    await pumpOverview(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enrol'));
    await tester.pumpAndSettle();
    expect(find.text('Enrol in this course?'), findsOneWidget);
    expect(adapter.requests.any((r) => r.path.endsWith('/enroll')), isFalse);

    await tester.tap(find.widgetWithText(AppButton, 'Enrol').last);
    await tester.pumpAndSettle();

    expect(adapter.requests.any((r) => r.path.endsWith('/enroll')), isTrue);
    expect(find.text('You are enrolled. The course is in My Courses.'), findsOneWidget);
    expect(find.byType(StickyActionBar), findsNothing, reason: 'the enrol bar is gone');
  });

  testWidgets('a refused enrolment says what the academy said', (tester) async {
    final notEnrolled = _detail('course-detail-not-enrolled');
    adapter.handler = (options) async {
      if (options.path == '/catalog/instructors') {
        return FakeAdapter.jsonResponse(fixture('catalog/instructors.json'));
      }
      if (options.path.endsWith('/enroll')) {
        return FakeAdapter.jsonResponse(fixture('errors/enroll-approval.json'), status: 409);
      }
      return FakeAdapter.jsonResponse(notEnrolled);
    };

    await pumpOverview(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enrol'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Enrol').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Enrolment in this academy needs approval'), findsOneWidget);
  });

  testWidgets('the save toggle moves at once and goes back when it is refused', (tester) async {
    final notEnrolled = _detail('course-detail-not-enrolled');
    adapter.handler = (options) async {
      if (options.path == '/catalog/instructors') {
        return FakeAdapter.jsonResponse(fixture('catalog/instructors.json'));
      }
      if (options.path.endsWith('/save')) {
        return FakeAdapter.jsonResponse(fixture('errors/not-found.json'), status: 404);
      }
      return FakeAdapter.jsonResponse(notEnrolled);
    };

    await pumpOverview(tester);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Save this course'), findsOneWidget);
    await tester.tap(find.byTooltip('Save this course'));
    await tester.pump();
    expect(find.byTooltip('Remove from saved'), findsOneWidget, reason: 'optimistic');

    await tester.pumpAndSettle();
    expect(find.byTooltip('Save this course'), findsOneWidget, reason: 'the server said no');
  });

  testWidgets('a locked lesson says what unlocks it; a free preview opens', (tester) async {
    serve(_detail('course-detail-not-enrolled'));
    final router = await pumpOverview(tester);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Curriculum'), 300);
    await tester.pumpAndSettle();

    // The lesson rows carry their number, and a locked one says what would open it.
    expect(find.text('Enrol to unlock'), findsWidgets);
    await tester.tap(find.textContaining('The Atmakaraka in depth'));
    await tester.pumpAndSettle();
    expect(
      locationOf(router),
      AppRoutes.learnCourse(_courseId),
      reason: 'a locked lesson goes nowhere',
    );

    // The curriculum's own row for the free preview (the "Try it free" card is another way in).
    await tester.tap(find.text('1.1  Assigning the karakas'));
    await tester.pumpAndSettle();
    expect(locationOf(router), startsWith('/catalog/jaimini-chara-karakas/preview/'));
  });

  testWidgets('before enrolling, "Try it free" lists the free previews, and one opens', (
    tester,
  ) async {
    serve(_detail('course-detail-not-enrolled'));
    final router = await pumpOverview(tester);
    await tester.pumpAndSettle();

    expect(find.text('1 lesson free to preview'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Try it free'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assigning the karakas'));
    await tester.pumpAndSettle();
    expect(locationOf(router), startsWith('/catalog/jaimini-chara-karakas/preview/'));
  });

  testWidgets("an enrolled learner's locked lesson says what opens it, never \"Enrol\"", (
    tester,
  ) async {
    serve(_detail('course-detail-enrolled'));
    await pumpOverview(tester);
    await tester.pumpAndSettle();

    // The second chapter waits on the first, which is not finished yet.
    final chapter = find.text('Reading Antardashas');
    await tester.scrollUntilVisible(chapter, 300);
    await tester.pumpAndSettle();
    await tester.tap(chapter);
    await tester.pumpAndSettle();

    expect(find.text('Finish “How Vimshottari Works” to open this chapter.'), findsWidgets);
    expect(find.text('Enrol to unlock'), findsNothing, reason: 'they are enrolled');
  });

  testWidgets('a course that is not theirs to see is a not-found', (tester) async {
    adapter.handler = (options) async => options.path == '/catalog/instructors'
        ? FakeAdapter.jsonResponse(fixture('catalog/instructors.json'))
        : FakeAdapter.jsonResponse(fixture('errors/not-found.json'), status: 404);

    await pumpOverview(tester);
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundView), findsOneWidget);
  });
}
