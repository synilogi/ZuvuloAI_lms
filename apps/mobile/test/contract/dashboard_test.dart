import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/staff_dashboard/staff_dashboard.dart';

/// Contract tests (§23) for the staff dashboard, against what the real API returned.
Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

DashboardSnapshot _snapshot(String name) =>
    DashboardSnapshot.fromJson(_fixture('dashboard/$name.json')! as Map<String, dynamic>);

void main() {
  group('the academy\'s own dashboard', () {
    late DashboardSnapshot snapshot;

    setUp(() => snapshot = _snapshot('academy'));

    test('the scope says whose figures these are', () {
      expect(snapshot.scope.isAcademy, isTrue);
      expect(snapshot.scope.instructorId, isNull);
      expect(snapshot.generatedAt.isUtc, isTrue);
      expect(snapshot.isEmpty, isFalse);
    });

    test('each headline figure carries its history and its unit', () {
      final kpis = snapshot.kpis;

      expect(kpis.courses.value, 6);
      expect(kpis.courses.unit, KpiUnit.count);
      expect(kpis.courses.series, hasLength(8));
      expect(kpis.students.value, 52);
      expect(kpis.students.previous, 43);
      expect(kpis.completionRate.unit, KpiUnit.percent);
      expect(kpis.completionRate.isRate, isTrue);
      // The third figure is the academy's active instructors here.
      expect(kpis.third.value, 3);
    });

    test('the change is read in the unit the measure uses', () {
      // 43 → 52 learners is a count: percent.
      final students = kpiChange(snapshot.kpis.students);
      expect(students.direction, TrendDirection.up);
      expect(students.isPoints, isFalse);
      // 59% → 58% completion is a rate: points.
      final completion = kpiChange(snapshot.kpis.completionRate);
      expect(completion.direction, TrendDirection.down);
      expect(completion.amount, 1);
      expect(completion.isPoints, isTrue);
    });

    test('the trends are twelve weeks and the activity twenty-eight days, oldest first', () {
      expect(snapshot.enrollments, hasLength(12));
      expect(snapshot.completions, hasLength(12));
      expect(snapshot.activity, hasLength(28));
      expect(snapshot.enrollments.first.day!.isBefore(snapshot.enrollments.last.day!), isTrue);
      expect(snapshot.activity.first.day!.isBefore(snapshot.activity.last.day!), isTrue);
      for (final point in snapshot.enrollments) {
        expect(point.date, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      }
    });

    test('what needs attention says how loudly, and where to go', () {
      expect(snapshot.attention, isNotEmpty);
      for (final item in snapshot.attention) {
        expect(item.kind, isNot(AttentionKind.unknown));
        expect(item.severity, isNot(AttentionSeverity.unknown));
        expect(item.title, isNotEmpty);
        expect(item.detail, isNotEmpty);
        expect(item.to, startsWith('/'));
      }
      expect(snapshot.attention.map((a) => a.kind), contains(AttentionKind.atRisk));
    });

    test('an academy admin\'s events point into the admin side of the web', () {
      expect(snapshot.events, isNotEmpty);
      for (final event in snapshot.events) {
        expect(event.kind, isNot(AdminEventKind.unknown));
        expect(event.actor, isNotEmpty);
        expect(event.summary, isNotEmpty);
        expect(event.at.isUtc, isTrue);
      }
      expect(
        snapshot.events.map((e) => e.to).nonNulls,
        everyElement(anyOf(startsWith('/admin/'), startsWith('/teach/'))),
      );
    });

    test('course performance is counted by the academy, and carries no title', () {
      expect(snapshot.courses, hasLength(6));
      final course = snapshot.courses.first;
      expect(course.courseId, isNotEmpty);
      expect(course.enrolled, greaterThanOrEqualTo(course.active));
      expect(course.weeklyEnrollments, isNotEmpty);
      // Finding 22: the row names no course, which is why the app reads the titles separately.
      expect(course.toJson().keys, isNot(contains('title')));
    });
  });

  group('one instructor\'s dashboard', () {
    late DashboardSnapshot snapshot;

    setUp(() => snapshot = _snapshot('instructor'));

    test('the scope names the instructor the server decided on', () {
      expect(snapshot.scope.isAcademy, isFalse);
      expect(snapshot.scope.instructorId, isNotEmpty);
    });

    test('the third figure is their review queue, not the academy\'s instructors', () {
      expect(snapshot.kpis.third.value, greaterThanOrEqualTo(0));
      expect(snapshot.kpis.third.unit, KpiUnit.count);
    });

    test('their events and attention point at the teaching side', () {
      final targets = [
        ...snapshot.attention.map((a) => a.to),
        ...snapshot.events.map((e) => e.to).nonNulls,
      ];

      expect(targets, isNotEmpty);
      expect(targets, everyElement(startsWith('/teach/')));
    });

    test('they see only the courses they teach', () {
      expect(snapshot.courses, hasLength(lessThan(6)));
      expect(snapshot.courses, isNotEmpty);
    });
  });
}
