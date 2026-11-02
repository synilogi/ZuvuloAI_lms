import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/learner_home/learner_home.dart';

/// Contract tests (§23) for the learner's workspace, against what the real API returned for the
/// seeded student — see the `.cmd.txt` note beside each fixture.
Map<String, dynamic> _json(String name) =>
    jsonDecode(File('test/fixtures/learning/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('GET /learning/home', () {
    late LearnerHome home;

    setUp(() => home = LearnerHome.fromJson(_json('home')));

    test('the whole response parses: courses, recent, upcoming and the week', () {
      expect(home.firstName, 'Ananya');
      expect(home.courses, hasLength(3));
      expect(home.recent, isNotEmpty);
      expect(home.recent.length, lessThanOrEqualTo(5));
      expect(home.upcoming.length, lessThanOrEqualTo(6));
      expect(home.week, hasLength(7));
      expect(home.isEmpty, isFalse);
    });

    test('progress is the server\'s, weighted by minutes — never recomputed here', () {
      final course = home.courses.firstWhere((c) => c.course.slug == 'dasha-system');

      expect(course.progress.completed, 1);
      expect(course.progress.total, 4);
      expect(course.progress.percent, 32, reason: 'weighted by lesson minutes, not 1/4 = 25%');
      expect(course.progress.remainingMin, 63);
      expect(course.progress.state, ProgressState.inProgress);
      expect(course.progress.fraction, closeTo(0.32, 0.001));
    });

    test('the next lesson is the one the server picked, with where to resume it', () {
      final course = home.courses.firstWhere((c) => c.course.slug == 'dasha-system');

      expect(course.next?.title, 'Calculating the balance at birth');
      expect(course.next?.lessonNumber, '1.2');
      expect(course.next?.state, ProgressState.inProgress);
      expect(course.next?.fraction, 0.4);
      expect(course.next?.positionSec, 300);
    });

    test('a finished course has no next lesson and a completed enrolment', () {
      final done = home.courses.firstWhere(
        (c) => c.enrollment.status == EnrollmentStatus.completed,
      );

      expect(done.next, isNull);
      expect(done.progress.percent, 100);
      expect(done.progress.remainingMin, 0);
      expect(done.enrollment.completedAt, isNotNull);
      expect(done.enrollment.isOpen, isFalse);
    });

    test('the snapshot carries every lesson state, including locked ones', () {
      final course = home.courses.firstWhere((c) => c.course.slug == 'dasha-system');
      final states = course.snapshot.lessons.values.map((l) => l.state).toSet();

      expect(states, containsAll([ProgressState.completed, ProgressState.inProgress]));
      expect(states, contains(ProgressState.locked));
      expect(course.snapshot.lastLessonId, isNotNull);
      expect(course.snapshot.stateOf('no-such-lesson'), ProgressState.notStarted);
    });

    test('an upcoming item carries the server\'s flag and a web path to map', () {
      final overdue = home.upcoming.firstWhere((i) => i.flag == UpcomingFlag.overdue);

      expect(overdue.kind, UpcomingKind.assignment);
      expect(overdue.to, startsWith('/assignments/'));
      expect(overdue.context, contains('overdue'));
      expect(upcomingStatus(overdue.flag), isNotNull);
      expect(upcomingStatus(null), isNull);
    });

    test('the week is seven IST calendar days of minutes', () {
      expect(home.week, hasLength(7));
      expect(home.week.every((d) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(d.date)), isTrue);
      expect(home.week.map((d) => d.minutes).reduce((a, b) => a + b), greaterThan(0));
      expect(home.week.first.day, isNotNull);
    });
  });

  group('GET /learning/courses', () {
    test('the enrolled courses and the saved ones are separate lists', () {
      final plain = LearnerCourses.fromJson(_json('courses'));
      final withSaved = LearnerCourses.fromJson(_json('courses-with-saved'));

      expect(plain.saved, isEmpty);
      expect(withSaved.courses, hasLength(plain.courses.length));
      expect(withSaved.saved, hasLength(1));
      expect(withSaved.saved.single.course.slug, 'jaimini-chara-karakas');
      expect(withSaved.saved.single.levelTitle, isNotEmpty);
      // A saved course is not enrolled, so it never appears among the enrolled ones.
      expect(withSaved.courses.map((c) => c.course.slug), isNot(contains('jaimini-chara-karakas')));
    });

    test('a saved course carries the outline and its free previews, nothing more', () {
      final saved = LearnerCourses.fromJson(_json('courses-with-saved')).saved.single;

      expect(saved.course.lessons, isNotEmpty);
      // Saving is not enrolling, so the route strips the bodies it would strip for a visitor.
      final locked = saved.course.lessons.where((l) => !l.isPlayablePreview);
      expect(locked, isNotEmpty);
      expect(locked.every((l) => l.content == null || l.content!.isEmpty), isTrue);
    });
  });

  test('a status or flag this build does not know never crashes a screen', () {
    final course = LearnerCourse.fromJson({
      ...(_json('home')['courses']! as List<dynamic>).first as Map<String, dynamic>,
      'enrollment': {
        ...((_json('home')['courses']! as List<dynamic>).first
                as Map<String, dynamic>)['enrollment']!
            as Map<String, dynamic>,
        'status': 'refunded',
      },
    });
    final item = UpcomingItem.fromJson({
      'id': 'x',
      'kind': 'webinar',
      'title': 't',
      'context': 'c',
      'at': '2026-09-25T06:00:00.000Z',
      'to': '/live/x',
      'flag': 'burning',
    });

    expect(course.enrollment.status, EnrollmentStatus.unknown);
    expect(course.enrollment.isOpen, isFalse);
    expect(item.kind, UpcomingKind.unknown);
    expect(item.flag, UpcomingFlag.unknown);
    expect(upcomingStatus(item.flag), isNull);
  });
}
