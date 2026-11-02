import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/media/media_auth_headers.dart';
import 'package:syniastrolms_mobile/features/learner_home/learner_home.dart';
import 'package:syniastrolms_mobile/shared/widgets/learning/course_cover.dart';

import '../helpers/pump.dart';
import '../helpers/test_config.dart';

/// Contract tests for the sample education catalogue (`npm run seed:education`): what the real API returned for the
/// seeded demo learner — four enrolments, each with its own uploaded cover, Hindi and English titles — parses into
/// the app's models, and every cover is fetched from the API's own `/catalog/covers/:id` path with the session token.
/// See the `.cmd.txt` note beside each fixture.
Map<String, dynamic> _json(String name) =>
    jsonDecode(File('test/fixtures/learning/education_demo/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  late LearnerHome home;
  late LearnerCourses mine;

  setUp(() {
    home = LearnerHome.fromJson(_json('home'));
    mine = LearnerCourses.fromJson(_json('courses'));
  });

  test('My Learning holds the four enrolled courses, one finished, each with its own cover', () {
    expect(mine.courses, hasLength(4));
    expect(
      mine.courses.where((c) => c.enrollment.status == EnrollmentStatus.completed),
      hasLength(1),
    );
    final covers = mine.courses.map((c) => c.course.coverImageUrl).toList();
    expect(covers, everyElement(startsWith('/catalog/covers/edu-media-cover-')));
    expect(covers.toSet(), hasLength(4), reason: 'no two courses share an image');
  });

  test('Home: Continue Learning resumes the most recently studied course', () {
    final first = home.courses.firstWhere((c) => c.enrollment.status == EnrollmentStatus.active);
    expect(first.course.title, 'RAS Prelims Foundation Batch');
    expect(first.next?.title, contains('राजस्थान'), reason: 'Hindi titles survive the round trip');
    expect(first.progress.percent, inExclusiveRange(0, 100));
  });

  test('Home: a live class, an assignment and a test are coming up', () {
    final kinds = home.upcoming.map((u) => u.kind).toSet();
    expect(
      kinds,
      containsAll(<UpcomingKind>[UpcomingKind.live, UpcomingKind.assignment, UpcomingKind.quiz]),
    );
  });

  testWidgets('every course cover is fetched from the API, over its motif', (tester) async {
    for (final c in mine.courses) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(testConfig()),
            mediaAuthHeadersProvider.overrideWith(
              (ref) async => const {'Authorization': 'Bearer t'},
            ),
          ],
          child: themedHarness(
            SizedBox(
              width: 320,
              child: CourseCover(
                motif: CoverMotif.parse(c.course.coverMotif),
                imageUrl: c.course.coverImageUrl,
              ),
            ),
            scroll: false,
          ),
        ),
      );
      await tester.pump();
      final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(
        image.imageUrl,
        'https://api.test/api${c.course.coverImageUrl}',
        reason: c.course.title,
      );
      expect(image.httpHeaders, containsPair('Authorization', 'Bearer t'));
    }
  });
}
