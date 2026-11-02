import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/features/course_learning/course_learning.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

const _lesson = LessonRef(courseId: 'course_1', lessonId: 'lesson_2');

void main() {
  late FakeAdapter adapter;
  late ProviderContainer container;

  setUp(() {
    adapter = FakeAdapter();
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: publicScope(
        adapter: adapter,
        signedInAs: learner(),
        child: const SizedBox(),
      ).overrides,
    );
    addTearDown(container.dispose);
    // Kept alive for the test, as the player would.
    container.listen(lessonActionsProvider, (_, _) {});
    container.listen(lessonNoteProvider, (_, _) {});
  });

  group('completing', () {
    test('the server\'s answer is what the app acts on', () async {
      adapter
        ..enqueueJson(fixture('learning/complete-result.json'))
        ..enqueueJson(fixture('learning/lesson-video.json'));

      final result = await container.read(lessonActionsProvider.notifier).complete(_lesson);

      expect(result, isNotNull);
      expect(result!.progress.percent, 63);
      expect(container.read(lessonActionsProvider).moment, result);
      expect(container.read(lessonActionsProvider).hint, isNull);
    });

    test('a rule not yet met becomes the hint, not an error to apologise for', () async {
      adapter.enqueueJson(fixture('errors/complete-needs-watching.json'), status: 409);

      final result = await container.read(lessonActionsProvider.notifier).complete(_lesson);

      expect(result, isNull);
      final state = container.read(lessonActionsProvider);
      expect(state.hint, 'Watch at least 90% of the lesson to complete it.');
      expect(state.failure, isNull, reason: 'the academy is not apologising');
      expect(state.moment, isNull);
    });

    test('a real failure stays a failure', () async {
      adapter.enqueueJson({'message': 'Server error.'}, status: 500);

      await container.read(lessonActionsProvider.notifier).complete(_lesson);

      expect(container.read(lessonActionsProvider).failure, isA<ServerFailure>());
      expect(container.read(lessonActionsProvider).hint, isNull);
    });

    test('a second tap while one is in flight is ignored', () async {
      adapter
        ..enqueueJson(fixture('learning/complete-result.json'))
        ..enqueueJson(fixture('learning/lesson-video.json'));

      final first = container.read(lessonActionsProvider.notifier).complete(_lesson);
      final second = await container.read(lessonActionsProvider.notifier).complete(_lesson);
      await first;

      expect(second, isNull);
      expect(adapter.requests.where((r) => r.path.endsWith('/complete')), hasLength(1));
    });

    test('a moment is shown once and then forgotten', () async {
      adapter
        ..enqueueJson(fixture('learning/complete-course.json'))
        ..enqueueJson(fixture('learning/lesson-video.json'));

      await container.read(lessonActionsProvider.notifier).complete(_lesson);
      expect(container.read(lessonActionsProvider).moment?.courseCompleted, isTrue);

      container.read(lessonActionsProvider.notifier).momentSeen();
      expect(container.read(lessonActionsProvider).moment, isNull);
    });
  });

  group('reporting a watched position', () {
    test('the same second is not sent twice', () async {
      adapter.enqueueStatus(204);
      final notifier = container.read(lessonActionsProvider.notifier);

      await notifier.reportPosition(_lesson, positionSec: 120, fraction: 0.4);
      await notifier.reportPosition(_lesson, positionSec: 120, fraction: 0.4);

      expect(adapter.requests, hasLength(1));
    });

    test('a lost report is retried once, and then let go', () async {
      var attempts = 0;
      adapter.handler = (options) async {
        attempts++;
        throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
      };

      await container
          .read(lessonActionsProvider.notifier)
          .reportPosition(_lesson, positionSec: 300, fraction: 0.8);

      // Two attempts of ours; the client's own retry policy sits underneath.
      expect(attempts, greaterThanOrEqualTo(2));
      expect(container.read(lessonActionsProvider).failure, isNull, reason: 'nothing to say');
    });

    test('a refusal that is not a network failure is not retried', () async {
      adapter.enqueueJson({'message': 'Enrol in this course to continue.'}, status: 403);

      await container
          .read(lessonActionsProvider.notifier)
          .reportPosition(_lesson, positionSec: 10, fraction: 0.1);

      expect(adapter.requests, hasLength(1));
    });
  });

  group('the notes', () {
    test('typing saves a moment after it stops, once', () async {
      adapter.enqueueJson({'savedAt': '2026-09-23T12:00:00.000Z'});
      final notes = container.read(lessonNoteProvider.notifier)..load('');

      notes
        ..edit(_lesson, 'My')
        ..edit(_lesson, 'My wor')
        ..edit(_lesson, 'My working');
      expect(adapter.requests, isEmpty, reason: 'nothing is sent while the typing continues');

      await waitFor(
        () => container.read(lessonNoteProvider).status == NoteStatus.saved,
        reason: 'the note should be saved once the typing has stopped for the debounce',
      );

      expect(adapter.requests, hasLength(1));
      expect((adapter.lastRequest.data! as Map)['text'], 'My working');
      expect(container.read(lessonNoteProvider).status, NoteStatus.saved);
      expect(container.read(lessonNoteProvider).savedAt, DateTime.utc(2026, 9, 23, 12));
    });

    test('Save sends what is on screen straight away', () async {
      adapter.enqueueJson({'savedAt': '2026-09-23T12:00:00.000Z'});
      final notes = container.read(lessonNoteProvider.notifier)..load('before');

      notes.edit(_lesson, 'after');
      await notes.save(_lesson);

      expect(adapter.requests, hasLength(1));
      expect((adapter.lastRequest.data! as Map)['text'], 'after');
    });

    test('a refused save says so and keeps what was typed', () async {
      adapter.enqueueJson({'message': 'Enrol in this course to continue.'}, status: 403);
      final notes = container.read(lessonNoteProvider.notifier)..load('');

      notes.edit(_lesson, 'My working');
      await notes.save(_lesson);

      final state = container.read(lessonNoteProvider);
      expect(state.status, NoteStatus.failed);
      expect(state.text, 'My working');
      expect(state.failure, isA<ForbiddenFailure>());
    });

    test('a note longer than the route accepts is never sent', () async {
      final notes = container.read(lessonNoteProvider.notifier)..load('x' * 20001);

      await notes.save(_lesson);

      expect(adapter.requests, isEmpty);
    });
  });

  group('bookmarking', () {
    test('the toggle moves at once and keeps the server\'s answer', () async {
      adapter.enqueueJson({'bookmarked': true});
      final notifier = container.read(lessonActionsProvider.notifier);

      final pending = notifier.toggleBookmark(_lesson, current: false);
      expect(container.read(lessonActionsProvider).bookmarkedOverride, isTrue);

      await pending;
      expect(container.read(lessonActionsProvider).bookmarkedOverride, isTrue);
    });

    test('a refusal puts it back', () async {
      adapter.enqueueJson({'message': 'Lesson not found.'}, status: 404);

      await container.read(lessonActionsProvider.notifier).toggleBookmark(_lesson, current: true);

      expect(container.read(lessonActionsProvider).bookmarkedOverride, isTrue);
      expect(container.read(lessonActionsProvider).failure, isA<NotFoundFailure>());
    });
  });
}
