import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/assignments/assignments.dart';

/// Contract tests (§23) for the learner's coursework, against what the real API returned.
Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

LearnerAssignment _detail(String name) =>
    LearnerAssignment.fromJson(_fixture('learning/$name.json')! as Map<String, dynamic>);

void main() {
  test('GET /learning/assignments — every course\'s coursework, soonest deadline first', () {
    final rows = [
      for (final row in _fixture('learning/assignments.json')! as List<dynamic>)
        LearnerAssignment.fromJson(row as Map<String, dynamic>),
    ];

    expect(rows, hasLength(greaterThan(1)));
    final deadlines = [for (final row in rows) row.dueAt].nonNulls.toList();
    expect(
      deadlines,
      orderedEquals(List<DateTime>.from(deadlines)..sort()),
      reason: 'the server sorts by deadline and the app keeps its order',
    );
    // Every deadline is read as the instant the server sent, never as local time.
    expect(deadlines.every((d) => d.isUtc), isTrue);
    expect(rows.map((r) => r.assignment.format), everyElement(isNot(SubmissionFormat.unknown)));
    expect(rows.map((r) => r.state), everyElement(isNot(AssignmentState.unknown)));
  });

  test('a written assignment past its deadline is overdue, and can still be handed in', () {
    final row = _detail('assignment-not-started');

    expect(row.assignment.format, SubmissionFormat.text);
    expect(row.state, AssignmentState.overdue);
    expect(row.assignment.acceptsLate, isTrue);
    expect(row.assignment.latePenalty, 10);
    expect(row.submission, isNull);
    expect(row.canSubmit, isTrue);
    expect(row.startingWork.isEmpty, isTrue);
  });

  test('a saved draft is where the work area starts again', () {
    final row = _detail('assignment-draft');

    expect(row.draft, isNotNull);
    expect(row.startingWork.text, startsWith('Mahadasha of Jupiter'));
    expect(row.startingWork.wordCount, 9);
    expect(row.canSubmit, isTrue);
  });

  test('a hand-in waiting for review carries no score and cannot be sent again', () {
    final row = _detail('assignment-submitted');

    expect(row.state, AssignmentState.submitted);
    expect(row.submission!.attempt, 1);
    expect(row.submission!.late, isFalse);
    expect(row.submission!.review.status, ReviewStatus.waiting);
    expect(row.submission!.review.gradedScore, isNull);
    expect(row.canSubmit, isFalse);
    expect(row.isReturned, isFalse);
  });

  test('a graded hand-in carries the score, the feedback and the pass mark it is read against', () {
    final row = _detail('assignment-graded');

    expect(row.state, AssignmentState.graded);
    final review = row.submission!.review;
    expect(review.status, ReviewStatus.graded);
    expect(review.points, 82);
    expect(review.gradedScore, 82);
    expect(review.feedback, isNotEmpty);
    expect(row.assignment.totalPoints, 100, reason: 'no rubric, so the maximum score stands');
    expect(row.assignment.passMark, 60);
    expect(row.canSubmit, isFalse);
  });

  test('a returned hand-in arrives as a draft, and only the review says it was sent back', () {
    final row = _detail('assignment-returned');

    // The documented quirk: `state` alone would read as an untouched draft.
    expect(row.state, AssignmentState.draft);
    expect(row.isReturned, isTrue);
    expect(row.submission!.review.status, ReviewStatus.returned);
    expect(row.submission!.review.feedback, isNotEmpty);
    // The score a returned review carries is not a grade, and is not shown as one.
    expect(row.submission!.review.score, 0);
    expect(row.submission!.review.gradedScore, isNull);
    // It may be handed in again, starting from what was sent back.
    expect(row.canSubmit, isTrue);
    expect(row.startingWork.text, row.submission!.text);
  });

  test('the total is the rubric\'s points when there is one, and the maximum otherwise', () {
    const rubric = CourseAssignment(
      id: 'a',
      courseId: 'c',
      maxScore: 100,
      rubric: [
        RubricCriterion(id: 'r1', points: 20),
        RubricCriterion(id: 'r2', points: 30),
      ],
    );

    expect(rubric.totalPoints, 50);
    expect(const CourseAssignment(id: 'a', courseId: 'c', maxScore: 40).totalPoints, 40);
  });

  test('words are counted the way the server counts them', () {
    expect(const AssignmentWork().wordCount, 0);
    expect(const AssignmentWork(text: '   ').wordCount, 0);
    expect(const AssignmentWork(text: 'one  two\nthree\tfour ').wordCount, 4);
  });
}
