import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/network/error_decoder.dart';
import 'package:syniastrolms_mobile/features/staff_review/staff_review.dart';

/// Contract tests (§23) for the staff side of coursework, against what the real API returned.
Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

Map<String, dynamic> _map(String path) => _fixture(path)! as Map<String, dynamic>;

void main() {
  group('how much is waiting', () {
    test('the academy counts what is to review and what is late', () {
      final queue = ReviewQueue.fromJson(_map('staff/review-queue.json'));

      expect(queue.toReview, 3);
      expect(queue.overdue, 1);
      expect(queue.overdue, lessThanOrEqualTo(queue.toReview));
      expect(queue.isClear, isFalse);
      expect(queue.byCourse, hasLength(1));
      expect(queue.byCourse.single.courseId, isNotEmpty);
      expect(
        queue.byCourse.fold<int>(0, (n, c) => n + c.toReview),
        queue.toReview,
        reason: 'every waiting hand-in belongs to one of the courses listed',
      );
    });

    test('an instructor is counted only on their own courses', () {
      final academy = ReviewQueue.fromJson(_map('staff/review-queue.json'));
      final mine = ReviewQueue.fromJson(_map('staff/review-queue-instructor.json'));

      expect(mine.toReview, lessThan(academy.toReview));
      expect(mine.toReview, 2);
    });

    test('a queue with nothing in it reads as clear', () {
      expect(const ReviewQueue().isClear, isTrue);
    });
  });

  group('the hand-ins', () {
    late SubmissionPage page;

    setUp(() => page = SubmissionPage.fromJson(_map('staff/submissions.json')));

    test('the counts cover every tab the queue offers', () {
      expect(page.countOf('all'), 15);
      expect(page.countOf('to-review'), 3);
      expect(page.countOf('graded'), 10);
      expect(page.countOf('returned'), 2);
      expect(page.countOf('missing'), 33);
      expect(page.countOf('nonsense'), 0);
      expect(
        page.countOf('to-review') + page.countOf('graded') + page.countOf('returned'),
        page.countOf('all'),
      );
    });

    test('every row names the learner, the assignment and the course', () {
      for (final row in page.rows) {
        expect(row.id, isNotEmpty);
        expect(row.student.name, isNotEmpty);
        expect(row.student.email, isNotEmpty);
        expect(row.assignmentId, isNotEmpty);
        expect(row.assignmentTitle, isNotEmpty);
        expect(row.courseTitle, isNotEmpty);
        expect(row.maxScore, greaterThan(0));
        expect(row.isMissing, isFalse);
        expect(row.submission!.review.status, isNot(ReviewStatus.unknown));
      }
    });

    test('a learner who has not handed in is a row with no submission', () {
      final missing = SubmissionPage.fromJson(_map('staff/submissions-missing.json'));

      expect(missing.rows, isNotEmpty);
      for (final row in missing.rows) {
        expect(row.isMissing, isTrue);
        expect(row.submission, isNull);
        expect(row.student.name, isNotEmpty);
        // The route makes an id up for them; no detail route will answer it.
        expect(row.id, startsWith('missing-'));
      }
    });
  });

  group('one hand-in in full', () {
    late SubmissionDetail detail;

    setUp(() => detail = SubmissionDetail.fromJson(_map('staff/submission.json')));

    test('it carries the assignment it answers and the learner who sent it', () {
      expect(detail.submission.id, isNotEmpty);
      expect(detail.submission.submittedAt.isUtc, isTrue);
      expect(detail.submission.review.status, ReviewStatus.waiting);
      expect(detail.assignment.title, isNotEmpty);
      expect(detail.assignment.passMark, 60);
      expect(detail.assignment.totalPoints, 100);
      expect(detail.courseTitle, isNotEmpty);
      expect(detail.student.email, isNotEmpty);
      expect(detail.student.enrolledAt!.isUtc, isTrue);
    });

    test('the queue says where to go next', () {
      expect(detail.queue.isInQueue, isTrue);
      expect(detail.queue.position, 1);
      expect(detail.queue.total, 2);
      expect(detail.queue.previousId, isNull);
      expect(detail.queue.nextId, isNotNull);
    });

    test('a rubric hand-in carries the criteria it is marked against', () {
      final rubric = SubmissionDetail.fromJson(_map('staff/submission-rubric.json'));

      expect(rubric.assignment.rubric, hasLength(3));
      expect(rubric.assignment.totalPoints, 50, reason: '20 + 20 + 10, summed from the rubric');
      expect(rubric.assignment.maxScore, 50);
      for (final criterion in rubric.assignment.rubric) {
        expect(criterion.id, isNotEmpty);
        expect(criterion.title, isNotEmpty);
        expect(criterion.points, greaterThan(0));
      }
      expect(rubric.submission.text, isNotNull);
      expect(rubric.queue.nextId, isNull, reason: 'it is the only one waiting');
    });
  });

  group('the assignments themselves', () {
    test('each row says how its hand-ins are going', () {
      final page = StaffAssignmentPage.fromJson(_map('staff/assignments.json'));

      expect(page.counts['all'], 3);
      expect(page.counts['published'], 3);
      for (final row in page.rows) {
        expect(row.assignment.id, isNotEmpty);
        expect(row.courseTitle, isNotEmpty);
        expect(row.submitted, greaterThanOrEqualTo(row.toReview));
        expect(row.overdue, lessThanOrEqualTo(row.toReview));
      }
      // Nothing scored yet is null, not zero — a zero would read as everyone failing.
      expect(page.rows.singleWhere((r) => r.graded == 0).avgScore, isNull);
    });
  });

  group('a refused decision', () {
    test('names the fields the academy refused, in its own words', () {
      final failure = ErrorDecoder.fromResponse(409, _fixture('errors/review-refused.json'));

      expect(failure, isA<ConflictFailure>());
      final issues = (failure as ConflictFailure).issues;
      expect(issues.map((i) => i.key), ['points', 'feedback']);
      expect(issues.first.message, contains('0 to 100'));
      expect(failure.message, 'Check the review before submitting it.');
    });

    test('a return with too little to go on is refused on the feedback alone', () {
      final failure =
          ErrorDecoder.fromResponse(409, _fixture('errors/review-returned-refused.json'))
              as ConflictFailure;

      expect(failure.issues.single.key, 'feedback');
      expect(failure.issues.single.message, contains('resubmit'));
    });
  });

  group('the rules the app mirrors', () {
    late CourseAssignment rubricAssignment;
    late CourseAssignment plainAssignment;

    setUp(() {
      rubricAssignment = SubmissionDetail.fromJson(_map('staff/submission-rubric.json')).assignment;
      plainAssignment = SubmissionDetail.fromJson(_map('staff/submission.json')).assignment;
    });

    test('words are counted the way the server counts them', () {
      expect(countWords(null), 0);
      expect(countWords('   '), 0);
      expect(countWords('one'), 1);
      expect(countWords('  two   words \n here '), 3);
    });

    test('a rubric score is the sum of its criteria, out of their total', () {
      final score = reviewScore(
        rubricAssignment,
        scores: const {'lagna': 18, 'moon': 15, 'nakshatra': 8},
        late: false,
      );

      expect(score.raw, 41);
      expect(score.penalty, 0);
      expect(score.score, 41);
      expect(score.max, 50);
    });

    test('without a rubric the points given stand on their own', () {
      final score = reviewScore(plainAssignment, scores: const {}, points: 72, late: false);

      expect(score.raw, 72);
      expect(score.score, 72);
      expect(score.max, 100);
    });

    test('a late hand-in loses the academy\'s percentage, rounded to the half point', () {
      // 10% of 41 is 4.1, which the rule rounds to 4.0 in half points.
      final penalised = reviewScore(
        rubricAssignment,
        scores: const {'lagna': 18, 'moon': 15, 'nakshatra': 8},
        late: true,
      );
      expect(penalised.penalty, 4);
      expect(penalised.score, 37);

      // The academy may accept late work without penalty; only the server knows which.
      final forgiven = reviewScore(
        rubricAssignment,
        scores: const {'lagna': 18, 'moon': 15, 'nakshatra': 8},
        late: true,
        applyLatePenalty: false,
      );
      expect(forgiven.penalty, 0);
      expect(forgiven.score, 41);
    });

    test('a penalty never takes a score below zero', () {
      final score = reviewScore(plainAssignment, scores: const {}, points: 0, late: true);
      expect(score.score, 0);
    });

    test('grading needs every criterion scored, and a line of feedback', () {
      final missing = validateReview(
        rubricAssignment,
        scores: const {'lagna': 18},
        feedback: 'Good work here, well argued.',
        decision: ReviewStatus.graded,
      );

      expect(missing.map((i) => i.criterionId), ['moon', 'nakshatra']);
      expect(missing.every((i) => i.field == 'scores'), isTrue);

      final complete = validateReview(
        rubricAssignment,
        scores: const {'lagna': 18, 'moon': 15, 'nakshatra': 8},
        feedback: 'Good work here, well argued.',
        decision: ReviewStatus.graded,
      );
      expect(complete, isEmpty);
    });

    test('a criterion scored above its points is refused', () {
      final issues = validateReview(
        rubricAssignment,
        scores: const {'lagna': 21, 'moon': 15, 'nakshatra': 8},
        feedback: 'Good work here, well argued.',
        decision: ReviewStatus.graded,
      );

      expect(issues.single.criterionId, 'lagna');
    });

    test('without a rubric the points must be inside the maximum', () {
      expect(
        validateReview(
          plainAssignment,
          scores: const {},
          points: 101,
          feedback: 'Good work here.',
          decision: ReviewStatus.graded,
        ).single.field,
        'points',
      );
      expect(
        validateReview(
          plainAssignment,
          scores: const {},
          feedback: 'Good work here.',
          decision: ReviewStatus.graded,
        ).single.field,
        'points',
        reason: 'no score at all is not a grade',
      );
    });

    test('a grade needs three words of feedback and a return needs eight', () {
      expect(
        validateReview(
          plainAssignment,
          scores: const {},
          points: 70,
          feedback: 'Fine',
          decision: ReviewStatus.graded,
        ).single.field,
        'feedback',
      );
      expect(
        validateReview(
          plainAssignment,
          scores: const {},
          points: 70,
          feedback: 'Fine work indeed',
          decision: ReviewStatus.graded,
        ),
        isEmpty,
      );
      expect(
        validateReview(
          plainAssignment,
          scores: const {},
          feedback: 'Please have another go at this',
          decision: ReviewStatus.returned,
        ).single.field,
        'feedback',
        reason: 'six words is not yet a sentence the learner can act on',
      );
      expect(
        validateReview(
          plainAssignment,
          scores: const {},
          feedback: 'Please have another go at the moon sign section.',
          decision: ReviewStatus.returned,
        ),
        isEmpty,
        reason: 'a return needs no score at all',
      );
    });
  });
}
