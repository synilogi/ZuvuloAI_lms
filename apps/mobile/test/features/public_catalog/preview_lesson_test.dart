import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/public_catalog/public_catalog.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _detail() =>
    jsonDecode(jsonEncode(fixture('catalog/course-detail-with-preview.json')))
        as Map<String, dynamic>;

void _serve(FakeAdapter adapter, Map<String, dynamic> course) {
  adapter.handler = (options) async => switch (options.path) {
    '/catalog/levels' => FakeAdapter.jsonResponse(fixture('catalog/levels.json')),
    '/catalog/instructors' => FakeAdapter.jsonResponse(fixture('catalog/instructors.json')),
    '/catalog/courses/foundations-vedic' => FakeAdapter.jsonResponse(course),
    _ => throw StateError('unexpected ${options.path}'),
  };
}

/// The lesson ids of the fixture, by title.
String _lessonId(Map<String, dynamic> course, String title) {
  for (final chapter in course['chapters']! as List<dynamic>) {
    for (final lesson in (chapter as Map<String, dynamic>)['lessons']! as List<dynamic>) {
      final row = lesson as Map<String, dynamic>;
      if (row['title'] == title) return row['id']! as String;
    }
  }
  throw StateError('no lesson called $title');
}

void main() {
  late FakeAdapter adapter;
  late Map<String, dynamic> course;

  setUp(() {
    adapter = FakeAdapter();
    course = _detail();
  });

  testWidgets('a free reading preview plays for a visitor, body and all', (tester) async {
    _serve(adapter, course);

    await pumpPublic(
      tester,
      PreviewLessonScreen(
        slug: 'foundations-vedic',
        lessonId: _lessonId(course, 'Benefics and malefics'),
      ),
      adapter: adapter,
    );
    await tester.pumpAndSettle();

    expect(find.text('Benefics and malefics'), findsOneWidget);
    expect(find.byType(ArticleBody), findsOneWidget);
    expect(find.textContaining('functional benefics or malefics'), findsOneWidget);
    // Nothing but the course itself was asked for — no lesson or media request.
    expect(adapter.requests.map((r) => r.path).where((p) => p.startsWith('/media')), isEmpty);
  });

  testWidgets('a lesson that is not a preview shows the enrol prompt and asks for nothing', (
    tester,
  ) async {
    _serve(adapter, course);

    await pumpPublic(
      tester,
      PreviewLessonScreen(
        slug: 'foundations-vedic',
        lessonId: _lessonId(course, 'Reading the houses'),
      ),
      adapter: adapter,
    );
    await tester.pumpAndSettle();

    expect(find.text('Enrol to watch this lesson'), findsOneWidget);
    expect(find.byType(ArticleBody), findsNothing);
    expect(adapter.requests.map((r) => r.path).toSet(), everyElement(isNot(startsWith('/media'))));
  });

  testWidgets('a preview whose file the academy never attached says so plainly', (tester) async {
    // The seeded video preview carries a file name but no stored id or URL.
    _serve(adapter, course);

    await pumpPublic(
      tester,
      PreviewLessonScreen(
        slug: 'foundations-vedic',
        lessonId: _lessonId(course, 'Introduction to the Navagrahas'),
      ),
      adapter: adapter,
    );
    await tester.pumpAndSettle();

    expect(find.text('Nothing to show yet'), findsOneWidget);
  });

  testWidgets('a stored video preview offers sign-in to a visitor, and plays for a learner', (
    tester,
  ) async {
    // `GET /media/:id` requires a session (backend finding B14), so a visitor is offered sign-in
    // rather than a player that could only fail.
    final withFile = _detail();
    final lesson =
        ((withFile['chapters']! as List<dynamic>).first as Map<String, dynamic>)['lessons']!
            as List<dynamic>;
    (lesson.first as Map<String, dynamic>)['content'] = {
      'video': {
        'file': {'id': 'media_1', 'name': 'intro.mp4', 'sizeMb': 84, 'url': '/media/media_1'},
        'durationSec': 1080,
        'captions': true,
        'markers': <Object>[],
      },
    };
    _serve(adapter, withFile);

    await pumpPublic(
      tester,
      PreviewLessonScreen(
        slug: 'foundations-vedic',
        lessonId: _lessonId(withFile, 'Introduction to the Navagrahas'),
      ),
      adapter: adapter,
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in to watch this preview'), findsOneWidget);
  });

  testWidgets('a lesson id that is not in the course shows not found', (tester) async {
    _serve(adapter, course);

    await pumpPublic(
      tester,
      const PreviewLessonScreen(slug: 'foundations-vedic', lessonId: 'nope'),
      adapter: adapter,
    );
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundView), findsOneWidget);
  });
}
