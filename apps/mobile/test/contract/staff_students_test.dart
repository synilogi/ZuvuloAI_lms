import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/staff_students/staff_students.dart';
import 'package:syniastrolms_mobile/shared/domain/activity.dart';
import 'package:syniastrolms_mobile/shared/domain/assignment.dart';

/// Contract tests (§23) for the staff learner screens, against what the real API returned.
Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

Map<String, dynamic> _map(String path) => _fixture(path)! as Map<String, dynamic>;

void main() {
  group('the roster', () {
    late RosterPage page;

    setUp(() => page = RosterPage.fromJson(_map('staff/students.json')));

    test('the counts cover every status tab and add up to the whole academy', () {
      expect(page.countOf('all'), 52);
      expect(
        page.countOf('active') +
            page.countOf('at-risk') +
            page.countOf('inactive') +
            page.countOf('suspended'),
        page.countOf('all'),
      );
      expect(page.countOf('nonsense'), 0);
      expect(page.total, 52);
      expect(page.rows, hasLength(20), reason: 'one page of twenty');
    });

    test('every row carries the learner, the academy\'s status and their courses', () {
      for (final row in page.rows) {
        expect(row.student.id, isNotEmpty);
        expect(row.student.name, isNotEmpty);
        expect(row.student.email, isNotEmpty);
        expect(row.student.rankId, isNotEmpty);
        expect(row.student.joinedAt!.isUtc, isTrue);
        expect(row.student.lastActiveAt!.isUtc, isTrue);
        expect(row.status, isNot(StudentStatus.unknown));
        for (final course in row.courses) {
          expect(course.id, isNotEmpty);
          expect(course.title, isNotEmpty);
          expect(course.status, isNot(EnrollmentStatus.unknown));
        }
      }
    });

    test('a suspended learner says so, whatever else is true of them', () {
      final suspended = page.rows.where((r) => r.status == StudentStatus.suspended);
      expect(suspended, isNotEmpty);
      for (final row in suspended) {
        expect(row.student.isSuspended, isTrue);
      }
    });

    test('a learner the route never marked suspended reads as not suspended', () {
      expect(const Student().isSuspended, isFalse);
    });
  });

  group('one learner in full', () {
    late StudentProfile profile;

    setUp(() => profile = StudentProfile.fromJson(_map('staff/student.json')));

    test('it carries who they are, where they stand and how quiet they have been', () {
      expect(profile.student.name, 'Ananya Rao');
      expect(profile.student.city, isNotEmpty);
      expect(profile.status, StudentStatus.active);
      expect(profile.quietDays, 0);
      expect(profile.rank.title, isNotEmpty);
      expect(profile.rank.order, greaterThan(0));
    });

    test('the figures are the academy\'s own counts', () {
      final summary = profile.summary;
      expect(summary.enrolled, 3);
      expect(summary.active, 2);
      expect(summary.completed, 1);
      expect(summary.enrolled, greaterThanOrEqualTo(summary.active + summary.completed));
      expect(summary.avgProgress, 51);
      expect(summary.studyMinutes, 169);
      expect(summary.submissions, 11);
    });

    test('each enrolment says how much of the curriculum is done and where they left off', () {
      expect(profile.enrollments, hasLength(3));
      for (final row in profile.enrollments) {
        expect(row.enrollment.id, isNotEmpty);
        expect(row.enrollment.status, isNot(EnrollmentStatus.unknown));
        expect(row.enrollment.source, isNot(EnrollmentSource.unknown));
        expect(row.courseTitle, isNotEmpty);
        expect(row.levelTitle, isNotEmpty);
        expect(row.chapters.done, lessThanOrEqualTo(row.chapters.total));
        expect(row.lessons.done, lessThanOrEqualTo(row.lessons.total));
      }
      // A course still going says what is next; a finished one has nothing to point at.
      final open = profile.enrollments.where((e) => e.enrollment.status == EnrollmentStatus.active);
      expect(open.every((e) => e.lastLessonTitle != null), isTrue);
      final done = profile.enrollments.where(
        (e) => e.enrollment.status == EnrollmentStatus.completed,
      );
      expect(done.every((e) => e.lastLessonTitle == null), isTrue);
    });

    test('a certificate they hold carries the credential the academy issued', () {
      expect(profile.certificates, hasLength(1));
      final certificate = profile.certificates.single;
      expect(certificate.credentialId, startsWith('SA-'));
      expect(certificate.issuedAt!.isUtc, isTrue);
      expect(certificate.title, isNotEmpty);
    });

    test('an enrolment the academy has finished with is no longer open to pause', () {
      expect(const Enrollment(status: EnrollmentStatus.active).isOpen, isTrue);
      expect(const Enrollment(status: EnrollmentStatus.paused).isOpen, isTrue);
      expect(const Enrollment(status: EnrollmentStatus.completed).isOpen, isFalse);
      expect(const Enrollment(status: EnrollmentStatus.expired).isOpen, isFalse);
    });
  });

  group('how far they have got', () {
    late StudentProgress progress;

    setUp(() => progress = StudentProgress.fromJson(_map('staff/student-progress.json')));

    test('each course is broken down by chapter, counted by the academy', () {
      expect(progress.courses, isNotEmpty);
      for (final course in progress.courses) {
        expect(course.courseTitle, isNotEmpty);
        expect(course.chapters, isNotEmpty);
        for (final chapter in course.chapters) {
          expect(chapter.title, isNotEmpty);
          expect(chapter.completed, lessThanOrEqualTo(chapter.total));
          expect(chapter.percent, lessThanOrEqualTo(100));
        }
      }
    });

    test('a quiz carries their best attempt against the academy\'s pass mark', () {
      expect(progress.quizzes, isNotEmpty);
      final quiz = progress.quizzes.first;
      expect(quiz.attempts, greaterThan(0));
      expect(quiz.best, 83);
      expect(quiz.passMark, 70);
      expect(quiz.passed, isTrue);
      expect(quiz.lastAt!.isUtc, isTrue);
      // The reading is the app's, of the academy's two figures.
      expect(const StudentQuizResult(best: 60, passMark: 70).passed, isFalse);
    });

    test('a hand-in carries where its review stands, and its score only once marked', () {
      expect(progress.assignments, isNotEmpty);
      for (final assignment in progress.assignments) {
        expect(assignment.submissionId, isNotEmpty);
        expect(assignment.title, isNotEmpty);
        expect(assignment.status, isNot(ReviewStatus.unknown));
        expect(assignment.max, greaterThan(0));
        if (assignment.status == ReviewStatus.waiting) expect(assignment.score, isNull);
      }
    });

    test('the study weeks keep the labels the server wrote', () {
      expect(progress.studyWeeks, isNotEmpty);
      expect(progress.studyWeeks.first.label, isNotEmpty);
      expect(progress.studyWeeks.first.detail, startsWith('Week of'));
    });
  });

  group('what they have been doing', () {
    late StudentActivity activity;

    setUp(() => activity = StudentActivity.fromJson(_map('staff/student-activity.json')));

    test('the counts cover every kind that happened, and add up to the total', () {
      expect(activity.countOf('all'), 25);
      expect(activity.total, 25);
      expect(activity.events, hasLength(25));
      final kinds = activity.counts.entries.where((e) => e.key != 'all');
      expect(kinds.fold<int>(0, (n, e) => n + e.value), activity.countOf('all'));
      expect(activity.countOf('live-attended'), 0, reason: 'nothing this build was not sent');
    });

    test('every event is one the app can read, newest first, and names its course', () {
      for (final event in activity.events) {
        expect(event.kind, isNot(ActivityKind.unknown));
        expect(event.title, isNotEmpty);
        expect(event.at.isUtc, isTrue);
        expect(event.courseId, isNotNull);
      }
      expect(
        activity.events.first.at.isAfter(activity.events.last.at),
        isTrue,
        reason: 'the route sorts newest first',
      );
    });

    test('a kind reads back as the value the route filters by', () {
      expect(ActivityKind.lessonCompleted.wireName, 'lesson-completed');
      expect(ActivityKind.assignmentSubmitted.wireName, 'assignment-submitted');
      expect(ActivityKind.enrolled.wireName, 'enrolled');
      for (final event in activity.events) {
        expect(activity.countOf(event.kind.wireName), greaterThan(0), reason: event.title);
      }
    });
  });

  group('the status the academy derives', () {
    final now = DateTime.utc(2026, 9, 30, 12);

    Student learner({required int quietDays, bool? suspended}) => Student(
      id: 's',
      name: 'A learner',
      lastActiveAt: now.subtract(Duration(days: quietDays)),
      suspended: suspended,
    );

    const open = [Enrollment(status: EnrollmentStatus.active)];
    const finished = [Enrollment(status: EnrollmentStatus.completed)];

    test('a suspended learner is suspended, however busy they have been', () {
      expect(
        deriveStudentStatus(learner(quietDays: 0, suspended: true), open, now: now),
        StudentStatus.suspended,
      );
    });

    test('someone who was here today is active', () {
      expect(deriveStudentStatus(learner(quietDays: 0), open, now: now), StudentStatus.active);
    });

    test('at risk needs unfinished work as well as quiet days', () {
      expect(deriveStudentStatus(learner(quietDays: 12), open, now: now), StudentStatus.atRisk);
      expect(
        deriveStudentStatus(learner(quietDays: 12), finished, now: now),
        StudentStatus.inactive,
        reason: 'nothing in progress is not at risk, only quiet',
      );
    });

    test('the academy\'s own threshold decides when quiet becomes at risk', () {
      expect(
        deriveStudentStatus(learner(quietDays: 12), open, now: now, atRiskDays: 30),
        StudentStatus.active,
      );
    });

    test('long enough away and it is inactive, work or no work', () {
      expect(deriveStudentStatus(learner(quietDays: 50), open, now: now), StudentStatus.inactive);
      expect(
        deriveStudentStatus(learner(quietDays: 50), finished, now: now),
        StudentStatus.inactive,
      );
    });

    test('a learner the route sent no last-active for is not guessed at', () {
      expect(deriveStudentStatus(const Student(id: 's'), open, now: now), StudentStatus.unknown);
    });
  });

  group('the completion rate', () {
    test('counts only the enrolments that had their chance', () {
      expect(
        completionRate(const [
          Enrollment(status: EnrollmentStatus.completed),
          Enrollment(status: EnrollmentStatus.active),
          Enrollment(status: EnrollmentStatus.paused),
        ]),
        50,
        reason: 'one of the two settled enrolments finished; the paused one is not counted',
      );
    });

    test('is nothing when nothing has settled', () {
      expect(completionRate(const []), 0);
      expect(completionRate(const [Enrollment(status: EnrollmentStatus.paused)]), 0);
    });
  });
}
