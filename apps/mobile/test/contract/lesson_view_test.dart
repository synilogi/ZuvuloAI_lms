import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/course_learning/course_learning.dart';
import 'package:syniastrolms_mobile/shared/domain/course.dart';
import 'package:syniastrolms_mobile/shared/domain/progress.dart';

/// Contract tests (§23) for the lesson player, against what the real API returned for the seeded
/// learner — one fixture per lesson type, plus the completion answers.
Map<String, dynamic> _json(String path) =>
    jsonDecode(File('test/fixtures/$path').readAsStringSync()) as Map<String, dynamic>;

LessonView _lesson(String name) => LessonView.fromJson(_json('learning/lesson-$name.json'));

void main() {
  test('a video lesson brings its file, the position to resume from and the threshold', () {
    final view = _lesson('video');

    expect(view.access, LessonAccess.open);
    expect(view.lesson.type, 'video');
    expect(view.lesson.content?.video?.file?.name, isNotEmpty);
    expect(view.lessonProgress?.positionSec, 300);
    expect(view.lessonProgress?.fraction, 0.4);
    expect(view.threshold, 90);
    expect(view.rule, CompletionRule.watched);
    expect(view.number, '2.1');
    expect(view.position.oneBased, 4);
    expect(view.position.total, 7);
  });

  test('a reading lesson brings its body', () {
    final view = _lesson('reading');

    expect(view.lesson.content?.article?.body, isNotEmpty);
    expect(view.state, ProgressState.notStarted);
    expect(view.rule, CompletionRule.opened);
    expect(view.previous?.title, 'The twelve rashis');
    expect(view.next?.locked, isFalse);
  });

  test('an assessment lesson brings the quiz mirror and the learner\'s best score', () {
    final view = _lesson('assessment');

    expect(view.lesson.content?.quiz, isNotNull);
    expect(view.lesson.content!.quiz!.questions, greaterThan(0));
    expect(view.lesson.content!.quiz!.passMark, greaterThan(0));
    expect(view.quizBest, 83);
    expect(view.rule, CompletionRule.passed);
  });

  test('an assignment lesson brings the linked assignment and its state', () {
    final view = _lesson('assignment');

    expect(view.assignment, isNotNull);
    expect(view.assignment!.id, isNotEmpty);
    expect(view.assignment!.title, isNotEmpty);
    expect(view.assignment!.state, isNotEmpty);
    expect(view.rule, CompletionRule.submitted);
    expect(view.next, isNull, reason: 'it is the last lesson of the course');
  });

  test('a practice lesson brings its instructions; the notes are the working', () {
    final view = _lesson('practice');

    expect(view.lesson.type, 'practice');
    expect(view.lesson.content?.article?.body, isNotEmpty);
    expect(view.rule, CompletionRule.submitted);
    expect(view.note, '');
  });

  test('a locked lesson brings its outline and the academy\'s reason, and no body at all', () {
    final view = _lesson('locked');

    expect(view.access, LessonAccess.locked);
    expect(view.state, ProgressState.locked);
    expect(view.lesson.content == null || view.lesson.content!.isEmpty, isTrue);
    expect(view.lockedReason, 'Finish “How Vimshottari Works” to open this chapter.');
    expect(view.next?.locked, isTrue);
    expect(view.isOpen, isFalse);
  });

  test('the snapshot the player carries is the whole course, states and all', () {
    final view = _lesson('video');
    final states = view.snapshot.lessons.values.map((l) => l.state).toSet();

    expect(view.snapshot.courseId, view.course.id);
    expect(states, contains(ProgressState.completed));
    // Only the lessons the learner has touched carry a row; the rest are simply not started.
    expect(view.snapshot.lessons.length, lessThan(view.course.lessons.length));
    final untouched = view.course.lessons.firstWhere(
      (l) => !view.snapshot.lessons.containsKey(l.id),
    );
    expect(view.snapshot.stateOf(untouched.id), ProgressState.notStarted);
  });

  group('completing', () {
    test('the server answers with the new snapshot and progress', () {
      final result = CompleteResult.fromJson(_json('learning/complete-result.json'));

      expect(result.progress.completed, 4);
      expect(result.progress.percent, 63);
      expect(result.courseCompleted, isFalse);
      expect(result.chapterCompleted, isNull);
      expect(
        result.snapshot.lessons.values.where((l) => l.state == ProgressState.completed),
        hasLength(4),
      );
    });

    test('a chapter and a course moment are only ever the server\'s word', () {
      final result = CompleteResult.fromJson(_json('learning/complete-course.json'));

      expect(result.chapterCompleted, 'The Seven Karakas');
      expect(result.courseCompleted, isTrue);
      expect(result.progress.percent, 100);
    });

    test('each rule refuses in the academy\'s own words', () {
      expect(
        _json('errors/complete-needs-pass.json')['message'],
        'Pass the quiz to complete this lesson.',
      );
      expect(
        _json('errors/complete-needs-working.json')['message'],
        'Write your working in the notes to complete the exercise.',
      );
      expect(
        _json('errors/complete-needs-watching.json')['message'],
        'Watch at least 90% of the lesson to complete it.',
      );
    });
  });

  test('a completion rule this build does not know is not guessed at', () {
    expect(defaultCompletionFor('seminar'), CompletionRule.unknown);
    expect(defaultCompletionFor('video'), CompletionRule.watched);
    expect(defaultCompletionFor('assessment'), CompletionRule.passed);
  });

  test('an academy that sets its own rule on a lesson overrides the default', () {
    final view = _lesson('video');
    final overridden = view.copyWith(
      lesson: view.lesson.copyWith(
        settings: const LessonSettings(completion: CompletionRule.opened),
      ),
    );

    expect(view.rule, CompletionRule.watched);
    expect(overridden.rule, CompletionRule.opened);
  });
}
