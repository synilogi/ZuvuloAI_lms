import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/profile/profile.dart';

/// Contract tests (§23) for the learner's activity feed, against what the real API returned.
Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

void main() {
  late LearningActivity activity;

  setUp(
    () => activity = LearningActivity.fromJson(
      _fixture('learning/activity.json')! as Map<String, dynamic>,
    ),
  );

  test('the week is seven IST days, read as dates and never as instants', () {
    expect(activity.week, hasLength(7));
    for (final day in activity.week) {
      expect(day.date, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(day.day, isNotNull);
      expect(day.minutes, greaterThanOrEqualTo(0));
    }
    expect(activity.weekMinutes, activity.week.fold<int>(0, (sum, d) => sum + d.minutes));
  });

  test('every event says what happened, when, and in the academy\'s own words', () {
    expect(activity.events, isNotEmpty);
    expect(activity.isEmpty, isFalse);
    for (final event in activity.events) {
      expect(event.id, isNotEmpty);
      expect(event.title, isNotEmpty);
      expect(event.at.isUtc, isTrue);
      expect(event.kind, isNot(ActivityKind.unknown));
    }
    // Newest first, as the route sorts them.
    final dates = activity.events.map((e) => e.at).toList();
    final newestFirst = [...dates]..sort((DateTime a, DateTime b) => b.compareTo(a));
    expect(dates, orderedEquals(newestFirst));
  });

  test('the kinds the academy sends are the kinds the app names', () {
    expect(activity.events.map((e) => e.kind), contains(ActivityKind.lessonCompleted));
    expect(activity.events.map((e) => e.kind), contains(ActivityKind.assignmentSubmitted));
    expect(
      ActivityKind.values.where((k) => k != ActivityKind.unknown),
      hasLength(8),
      reason: 'the eight `ActivityKind`s the domain defines',
    );
  });

  test('a kind this build has never heard of does not break the feed', () {
    final row = LearningEvent.fromJson(const {
      'id': 'x',
      'kind': 'moon-phase-noticed',
      'title': 'Something new',
      'at': '2026-09-29T10:00:00.000Z',
    });

    expect(row.kind, ActivityKind.unknown);
    expect(row.title, 'Something new');
  });
}
