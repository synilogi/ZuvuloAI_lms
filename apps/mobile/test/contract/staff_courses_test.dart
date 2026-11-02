import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/network/error_decoder.dart';
import 'package:syniastrolms_mobile/features/staff_courses/staff_courses.dart';
import 'package:syniastrolms_mobile/shared/domain/course.dart';

/// Contract tests (§23) for the staff catalogue, against what the real API returned.
Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

Map<String, dynamic> _map(String path) => _fixture(path)! as Map<String, dynamic>;

void main() {
  group('the academy\'s course list', () {
    late StaffCoursePage page;

    setUp(() => page = StaffCoursePage.fromJson(_map('staff/courses.json')));

    test('the counts are the academy\'s, over every status', () {
      expect(page.countOf('all'), 6);
      expect(page.countOf('published'), 6);
      expect(page.countOf('draft'), 0);
      expect(page.countOf('archived'), 0);
      expect(page.total, 6);
      expect(page.rows, hasLength(6));
      expect(page.isEmpty, isFalse);
    });

    test('a status the academy did not send counts as none', () {
      expect(page.countOf('retired'), 0);
    });

    test('every row is a whole course, with its curriculum', () {
      for (final course in page.rows) {
        expect(course.id, isNotEmpty);
        expect(course.slug, isNotEmpty);
        expect(course.title, isNotEmpty);
        expect(course.status, isNot(CourseStatus.unknown));
        expect(course.visibility, isNot(CourseVisibility.unknown));
        expect(course.format, isNot(CourseFormat.unknown));
        expect(course.chapters, isNotEmpty);
        expect(course.lessons, isNotEmpty);
        expect(course.durationMin, greaterThan(0));
      }
    });
  });

  group('how one course is doing', () {
    late CourseStats stats;

    setUp(() => stats = CourseStats.fromJson(_map('staff/course-stats.json')));

    test('the headline figures are the server\'s own counts', () {
      expect(stats.courseId, isNotEmpty);
      expect(stats.enrolled, 17);
      expect(stats.active, 7);
      expect(stats.completionRate, 41);
      expect(stats.avgProgress, 61);
      expect(stats.certificatesIssued, 0);
      expect(stats.reviewsWaiting, 2);
      expect(stats.totalMinutes, 142);
    });

    test('the live classes still to come are a count, not a list', () {
      expect(stats.upcomingLive, 1);
    });

    test('the enrolment trend is twelve weeks of dated points, oldest first', () {
      expect(stats.weekly, hasLength(12));
      expect(stats.weekly.first.day!.isBefore(stats.weekly.last.day!), isTrue);
      for (final point in stats.weekly) {
        expect(point.date, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      }
    });

    test('the progress spread is five bands the server names itself', () {
      expect(stats.progressBuckets, hasLength(5));
      expect(stats.progressBuckets.first.label, '0-20%');
      expect(stats.progressBuckets.last.label, '80-100%');
      expect(
        stats.progressBuckets.fold<num>(0, (n, b) => n + b.value),
        stats.enrolled,
        reason: 'every enrolled learner sits in exactly one band',
      );
    });

    test('the recent learners are the eight who enrolled last', () {
      expect(stats.recent, hasLength(8));
      for (final learner in stats.recent) {
        expect(learner.studentId, isNotEmpty);
        expect(learner.name, isNotEmpty);
        expect(learner.enrolledAt, isNotNull);
        expect(learner.enrolledAt!.isUtc, isTrue);
        expect(learner.status, isNotNull);
      }
    });
  });

  group('how far learners have got, chapter by chapter', () {
    late CurriculumStats stats;

    setUp(() => stats = CurriculumStats.fromJson(_map('staff/chapter-stats.json')));

    test('every chapter carries both rates', () {
      expect(stats.enrolled, 17);
      expect(stats.chapters, isNotEmpty);
      for (final chapter in stats.chapters.values) {
        expect(chapter.startedRate, greaterThanOrEqualTo(chapter.completionRate));
        expect(chapter.startedRate, lessThanOrEqualTo(100));
      }
    });

    test('a lesson nobody has reached reads as none, not as missing', () {
      expect(stats.lessons, isNotEmpty);
      expect(stats.lessonPercent('not-a-lesson'), 0);
      expect(stats.lessonPercent(stats.lessons.keys.first), greaterThan(0));
    });
  });

  group('a course\'s lessons', () {
    late StaffLessonPage page;

    setUp(() => page = StaffLessonPage.fromJson(_map('staff/course-lessons.json')));

    test('each row says where the lesson sits', () {
      expect(page.rows, hasLength(7));
      expect(page.rows.first.chapterIndex, 0);
      expect(page.rows.first.lessonIndex, 0);
      for (final row in page.rows) {
        expect(row.chapterId, isNotEmpty);
        expect(row.chapterTitle, isNotEmpty);
        expect(row.lesson.id, isNotEmpty);
        expect(row.lesson.status, isNot(ContentStatus.unknown));
      }
    });

    test('the counts include a breakdown by type', () {
      expect(page.counts['all'], 7);
      expect(page.counts['published'], 7);
      expect((page.counts['byType']! as Map)['video'], 2);
    });
  });

  group('the categories the filter offers', () {
    test('each row carries the category and how much sits in it', () {
      final page = StaffCategoryPage.fromJson(_map('staff/categories.json'));

      expect(page.rows, hasLength(3));
      for (final row in page.rows) {
        expect(row.category.id, isNotEmpty);
        expect(row.category.name, isNotEmpty);
        expect(row.category.status, isNot(CategoryStatus.unknown));
        expect(row.courseCount, greaterThanOrEqualTo(row.publishedCount));
      }
    });
  });

  group('a refused publish', () {
    test('carries the academy\'s whole checklist, met and unmet', () {
      final failure = ErrorDecoder.fromResponse(409, _fixture('errors/publish-checklist.json'));

      expect(failure, isA<ConflictFailure>());
      final checklist = publishChecklistOf((failure as ConflictFailure).rawIssues);
      expect(checklist, hasLength(6));
      expect(checklist.map((c) => c.id), containsAll(['identity', 'curriculum', 'lessons']));
      expect(checklist.every((c) => !c.met), isTrue);
      expect(checklist.first.label, 'Title and subtitle');
      expect(failure.message, 'This course is not ready to publish.');
    });

    test('a checklist line the app cannot read is left out rather than guessed at', () {
      expect(
        publishChecklistOf([
          {'id': 'ok', 'label': 'Fine', 'met': true},
          {'message': 'A plain issue'},
          'nonsense',
        ]),
        [const PublishCheck(id: 'ok', label: 'Fine', met: true)],
      );
    });
  });
}
