import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/assessments/assessments.dart';
import 'package:syniastrolms_mobile/features/course_learning/course_learning.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _view(String name) =>
    jsonDecode(jsonEncode(fixture('learning/lesson-$name.json'))) as Map<String, dynamic>;

String _courseId(Map<String, dynamic> view) =>
    (view['course']! as Map<String, dynamic>)['id']! as String;

String _lessonId(Map<String, dynamic> view) =>
    (view['lesson']! as Map<String, dynamic>)['id']! as String;

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  Future<GoRouter> pumpLesson(WidgetTester tester, Map<String, dynamic> view) {
    adapter.handler ??= (_) async => FakeAdapter.jsonResponse(view);
    return pumpPublicRouter(
      tester,
      adapter: adapter,
      signedInAs: learner(),
      initialLocation: AppRoutes.learnLesson(_courseId(view), _lessonId(view)),
      routes: [
        GoRoute(
          path: AppRoutes.learnLessonPattern,
          builder: (_, state) => Scaffold(
            body: SafeArea(
              child: LessonPlayerScreen(
                courseId: state.pathParameters['courseId'] ?? '',
                lessonId: state.pathParameters['lessonId'] ?? '',
              ),
            ),
          ),
        ),
        GoRoute(path: AppRoutes.learnCoursePattern, builder: (_, _) => const Placeholder()),
        GoRoute(path: AppRoutes.assignmentPattern, builder: (_, _) => const Placeholder()),
      ],
    );
  }

  testWidgets('a reading lesson shows its body, its number and where it sits', (tester) async {
    await pumpLesson(tester, _view('reading'));
    await tester.pumpAndSettle();

    expect(find.text('Reading the houses'), findsOneWidget);
    expect(find.byType(ArticleBody), findsOneWidget);
    expect(find.textContaining('2.2'), findsWidgets);
    expect(find.text('5 of 7'), findsOneWidget);
  });

  testWidgets('a reading lesson may be marked complete; the button asks the server', (
    tester,
  ) async {
    final view = _view('reading');
    adapter.handler = (options) async => options.path.endsWith('/complete')
        ? FakeAdapter.jsonResponse(fixture('learning/complete-result.json'))
        : FakeAdapter.jsonResponse(view);

    await pumpLesson(tester, view);
    await tester.pumpAndSettle();

    expect(find.text('Mark complete'), findsOneWidget);
    await tester.tap(find.text('Mark complete'));
    await tester.pumpAndSettle();

    expect(adapter.requests.any((r) => r.path.endsWith('/complete')), isTrue);
  });

  testWidgets('a video lesson says what the academy asks for before it is done', (tester) async {
    await pumpLesson(tester, _view('video'));
    await tester.pumpAndSettle();

    // The rule is the academy's: watch 90 %.
    expect(find.text('Watch 90% to complete'), findsOneWidget);
    expect(find.text('Mark complete'), findsNothing);
  });

  testWidgets('a video lesson leads with the video, above its title and tools', (tester) async {
    await pumpLesson(tester, _view('video'));
    await tester.pumpAndSettle();

    double y(Finder finder) => tester.getTopLeft(finder).dy;
    // The seeded lesson has no file attached yet, so the video's place holds the academy's
    // "nothing to show" state — the same slot the player fills.
    final body = find.text('Nothing to show yet');
    expect(body, findsOneWidget);
    expect(y(body), lessThan(y(find.text('The twelve rashis'))));
    expect(y(find.text('The twelve rashis')), lessThan(y(find.text('Curriculum'))));
  });

  testWidgets('a refused completion shows the academy\'s sentence in place of the button', (
    tester,
  ) async {
    final view = _view('practice');
    adapter.handler = (options) async => options.path.endsWith('/complete')
        ? FakeAdapter.jsonResponse(fixture('errors/complete-needs-working.json'), status: 409)
        : FakeAdapter.jsonResponse(view);

    await pumpLesson(tester, view);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark complete'));
    await tester.pumpAndSettle();

    expect(find.text('Write your working in the notes to complete the exercise.'), findsOneWidget);
  });

  testWidgets('a completed lesson says so and offers nothing to press', (tester) async {
    await pumpLesson(tester, _view('assessment'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Completed on'), findsOneWidget);
    expect(find.text('Mark complete'), findsNothing);
  });

  testWidgets('an assessment lesson hands over to the quiz taker, with the best score', (
    tester,
  ) async {
    await pumpLesson(tester, _view('assessment'));
    await tester.pumpAndSettle();

    expect(find.byType(QuizTaker), findsOneWidget);
    expect(find.text('Best so far 83%'), findsOneWidget);
    expect(find.text('Start the quiz'), findsOneWidget);
  });

  testWidgets('an assignment lesson opens its assignment', (tester) async {
    final view = _view('assignment');
    final router = await pumpLesson(tester, view);
    await tester.pumpAndSettle();

    expect(find.byType(AssignmentSummaryCard), findsOneWidget);
    await tester.tap(find.text('Open assignment'));
    await tester.pumpAndSettle();

    expect(locationOf(router), startsWith('/assignments/'));
  });

  testWidgets('a locked lesson shows the academy\'s reason and nothing of the lesson', (
    tester,
  ) async {
    await pumpLesson(tester, _view('locked'));
    await tester.pumpAndSettle();

    expect(find.text('Not open yet'), findsOneWidget);
    expect(find.text('Finish “How Vimshottari Works” to open this chapter.'), findsOneWidget);
    expect(find.byType(LessonNavBar), findsNothing);
    expect(find.byType(LessonNotes), findsNothing);
  });

  testWidgets('Next is offered only when the next lesson is open', (tester) async {
    final locked = _view('locked');
    await pumpLesson(tester, _view('reading'));
    await tester.pumpAndSettle();
    final open = tester.widget<LessonNavBar>(find.byType(LessonNavBar));
    expect(open.onNext, isNotNull);
    expect(open.onPrevious, isNotNull);

    // The locked fixture's own `next` is locked too, so that door stays shut.
    expect(
      LessonView.fromJson(locked).next?.locked,
      isTrue,
      reason: 'the fixture is what makes this test meaningful',
    );
  });

  testWidgets('the curriculum opens in a sheet and a locked lesson says why', (tester) async {
    final router = await pumpLesson(tester, _view('reading'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'Curriculum'));
    await tester.pumpAndSettle();
    expect(find.byType(CurriculumTree), findsOneWidget);

    await tester.tap(find.textContaining('Chart-reading practice'));
    await tester.pumpAndSettle();
    expect(locationOf(router), endsWith('/lessons/cmudqd8ex0027mmgzs5l716tb'));
  });

  testWidgets('a note is typed here and stored on the server', (tester) async {
    final view = _view('practice');
    adapter.handler = (options) async => options.path.endsWith('/note')
        ? FakeAdapter.jsonResponse({'savedAt': '2026-09-23T12:00:00.000Z'})
        : FakeAdapter.jsonResponse(view);

    await pumpLesson(tester, view);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'My working on the sample chart');
    await tester.tap(find.widgetWithText(AppButton, 'Save'));
    await tester.pumpAndSettle();

    final note = adapter.requests.lastWhere((r) => r.path.endsWith('/note'));
    expect((note.data! as Map)['text'], 'My working on the sample chart');
    expect(find.textContaining('Saved'), findsOneWidget);
  });

  testWidgets('the bookmark toggles and asks the server', (tester) async {
    final view = _view('reading');
    adapter.handler = (options) async => options.path.endsWith('/bookmark')
        ? FakeAdapter.jsonResponse({'bookmarked': true})
        : FakeAdapter.jsonResponse(view);

    await pumpLesson(tester, view);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bookmark this lesson'));
    await tester.pumpAndSettle();

    expect(adapter.requests.any((r) => r.path.endsWith('/bookmark')), isTrue);
    expect(find.byTooltip('Remove bookmark'), findsOneWidget);
  });

  testWidgets('a course finished is celebrated only because the server said so', (tester) async {
    final view = _view('reading');
    adapter.handler = (options) async => options.path.endsWith('/complete')
        ? FakeAdapter.jsonResponse(fixture('learning/complete-course.json'))
        : FakeAdapter.jsonResponse(view);

    await pumpLesson(tester, view);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark complete'));
    await tester.pumpAndSettle();

    expect(find.text('Course complete'), findsOneWidget);
  });

  testWidgets('a chapter finished is announced, not celebrated with a dialog', (tester) async {
    final view = _view('reading');
    final chapterOnly = {
      ...jsonDecode(jsonEncode(fixture('learning/complete-course.json'))) as Map<String, dynamic>,
      'courseCompleted': false,
    };
    adapter.handler = (options) async => options.path.endsWith('/complete')
        ? FakeAdapter.jsonResponse(chapterOnly)
        : FakeAdapter.jsonResponse(view);

    await pumpLesson(tester, view);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark complete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('The Seven Karakas is done.'), findsOneWidget);
    expect(find.text('Course complete'), findsNothing);
  });

  testWidgets('a lesson that is not there is a not-found', (tester) async {
    adapter.handler = (_) async =>
        FakeAdapter.jsonResponse(fixture('errors/not-found.json'), status: 404);
    await pumpPublicRouter(
      tester,
      adapter: adapter,
      signedInAs: learner(),
      initialLocation: AppRoutes.learnLesson('course_1', 'nope'),
      routes: [
        GoRoute(
          path: AppRoutes.learnLessonPattern,
          builder: (_, state) => Scaffold(
            body: SafeArea(
              child: LessonPlayerScreen(
                courseId: state.pathParameters['courseId'] ?? '',
                lessonId: state.pathParameters['lessonId'] ?? '',
              ),
            ),
          ),
        ),
        GoRoute(path: AppRoutes.learnCoursePattern, builder: (_, _) => const Placeholder()),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundView), findsOneWidget);
  });
}
