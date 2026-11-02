import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/course_learning/course_learning.dart';
import 'package:syniastrolms_mobile/shared/domain/learning.dart';
import 'package:syniastrolms_mobile/shared/domain/progress.dart';

/// Contract tests (§23) for one course as the learner sees it, against what the real API
/// returned for the seeded student.
Map<String, dynamic> _json(String name) =>
    jsonDecode(File('test/fixtures/learning/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('an enrolled course carries the enrolment, the progress and the next lesson', () {
    final detail = LearnerCourseDetail.fromJson(_json('course-detail-enrolled'));

    expect(detail.enrolled, isTrue);
    expect(detail.saved, isFalse);
    expect(detail.learner.enrollment.status, EnrollmentStatus.active);
    expect(detail.learner.enrollment.isPlaceholder, isFalse);
    expect(detail.learner.progress.percent, 32);
    expect(detail.learner.next, isNotNull);
    expect(detail.learner.levelTitle, 'Intermediate');
  });

  test('a course the learner is not enrolled in comes with a placeholder enrolment', () {
    final raw = _json('course-detail-not-enrolled');
    final detail = LearnerCourseDetail.fromJson(raw);

    // The route always sends an `enrollment` object; for a stranger it has no id and no date.
    expect((raw['enrollment']! as Map<String, dynamic>)['id'], '');
    expect((raw['enrollment']! as Map<String, dynamic>)['enrolledAt'], '');
    expect(detail.enrolled, isFalse);
    expect(detail.learner.enrollment.isPlaceholder, isTrue);
    expect(detail.learner.enrollment.enrolledAt, isNull, reason: 'an empty date is no date');
    expect(detail.learner.progress.percent, 0);
  });

  test('the outline is public but the bodies are not, until the learner enrols', () {
    final stranger = LearnerCourseDetail.fromJson(_json('course-detail-not-enrolled'));
    final member = LearnerCourseDetail.fromJson(_json('course-detail-enrolled'));

    expect(stranger.learner.course.lessons, isNotEmpty);
    final locked = stranger.learner.course.lessons.where((l) => !l.isPlayablePreview);
    expect(locked.every((l) => l.content == null || l.content!.isEmpty), isTrue);
    // An enrolled learner gets the bodies.
    expect(
      member.learner.course.lessons.any((l) => l.content != null && !l.content!.isEmpty),
      isTrue,
    );
  });

  test('enrolling answers with the course, and the server chose the source', () {
    final course = LearnerCourse.fromJson(_json('enroll'));

    expect(course.enrollment.id, isNotEmpty);
    expect(course.enrollment.status, EnrollmentStatus.active);
    expect(course.enrollment.source, 'self', reason: 'the app sends no body at all');
    expect(course.enrollment.enrolledAt, isNotNull);
    expect(course.progress.percent, 0);
    expect(course.next, isNotNull, reason: 'a fresh enrolment starts at the first lesson');
  });

  test('the academy refuses in its own words when it enrols on request', () {
    final refusal =
        jsonDecode(File('test/fixtures/errors/enroll-approval.json').readAsStringSync())
            as Map<String, dynamic>;

    expect(
      refusal['message'],
      'Enrolment in this academy needs approval — ask an instructor or the academy to add you '
      'to the course.',
    );
  });
}
