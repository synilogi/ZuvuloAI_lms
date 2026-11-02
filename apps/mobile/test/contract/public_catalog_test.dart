import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/public_catalog/public_catalog.dart';

/// Contract tests (§23) against responses the **real** API returned — see the `.cmd.txt` note
/// beside each fixture for the command that captured it.
Object? _fixture(String name) =>
    jsonDecode(File('test/fixtures/catalog/$name.json').readAsStringSync());

List<Course> _courses(String name) => [
  for (final row in _fixture(name)! as List<dynamic>) Course.fromJson(row as Map<String, dynamic>),
];

void main() {
  group('GET /catalog/courses', () {
    test('every seeded course parses, and all of them are published and public', () {
      final courses = _courses('courses');

      expect(courses, isNotEmpty);
      expect(courses.every((c) => c.status == CourseStatus.published), isTrue);
      expect(courses.every((c) => c.visibility == CourseVisibility.public), isTrue);
      expect(courses.every((c) => c.slug.isNotEmpty && c.id.isNotEmpty), isTrue);
      expect(courses.map((c) => c.title), contains('Foundations of Vedic Astrology'));
    });

    test('price amounts are whole rupees, not paise (clarification A2)', () {
      final course = _courses('courses').firstWhere((c) => c.slug == 'foundations-vedic');

      // The seed writes 2999 and the academy setting behind it is validated "₹0 to ₹5,00,000".
      expect(course.price?.amount, 2999);
      expect(course.price?.currency, 'INR');
    });

    test('the server narrows by level — the app only passes the id back', () {
      final all = _courses('courses');
      final beginner = _courses('courses-beginner');

      expect(beginner.length, lessThan(all.length));
      expect(beginner.map((c) => c.levelId).toSet(), hasLength(1));
      expect(all.map((c) => c.slug), containsAll(beginner.map((c) => c.slug)));
    });
  });

  group('GET /catalog/courses/:slug', () {
    test('a lesson that is not a free preview comes back with no content at all', () {
      final course = Course.fromJson(_fixture('course-detail')! as Map<String, dynamic>);

      final locked = course.lessons.where((l) => !l.isPreview);
      expect(locked, isNotEmpty);
      expect(locked.every((l) => l.content == null || l.content!.isEmpty), isTrue);
      // The outline itself is public: titles, types and durations are all there.
      expect(locked.every((l) => l.title.isNotEmpty && l.durationMin > 0), isTrue);
    });

    test('a published free preview keeps its body — this is what a visitor may read', () {
      final course = Course.fromJson(
        _fixture('course-detail-with-preview')! as Map<String, dynamic>,
      );

      final preview = course.lessons.firstWhere((l) => l.type == 'reading' && l.isPreview);
      expect(preview.isPlayablePreview, isTrue);
      expect(preview.content?.article?.body, contains('benefics or malefics'));
    });

    test('the academy publishes a rating only when it chooses to', () {
      final course = Course.fromJson(_fixture('course-detail')! as Map<String, dynamic>);

      // This academy's settings publish ratings; the app renders one only when both fields came.
      expect(course.rating, isNotNull);
      expect(course.ratingCount, isNotNull);
      const withheld = Course(id: 'c', slug: 's', title: 't', levelId: 'l', categoryId: 'k');
      expect(withheld.rating, isNull);
    });

    test('duration is summed from the lessons the server sent', () {
      final course = Course.fromJson(_fixture('course-detail')! as Map<String, dynamic>);

      expect(course.durationMin, course.lessons.fold<int>(0, (sum, l) => sum + l.durationMin));
      expect(course.durationMin, greaterThan(0));
    });
  });

  test('GET /catalog/categories — every seeded category parses with its levels', () {
    final categories = [
      for (final row in _fixture('categories')! as List<dynamic>)
        CourseCategory.fromJson(row as Map<String, dynamic>),
    ];

    expect(categories, isNotEmpty);
    expect(categories.every((c) => c.levelIds.isNotEmpty), isTrue);
    expect(categories.map((c) => c.name), contains('Vedic Foundations'));
  });

  test('GET /catalog/instructors — the contact details are not even modelled', () {
    final row = (_fixture('instructors')! as List<dynamic>).first as Map<String, dynamic>;
    final instructor = Instructor.fromJson(row);

    // The route sends them; nothing public may show them (§18).
    expect(row.containsKey('email'), isTrue);
    expect(instructor.toJson().containsKey('email'), isFalse);
    expect(instructor.toJson().containsKey('phone'), isFalse);
    expect(instructor.name, isNotEmpty);
    expect(instructor.expertise, isNotEmpty);
  });

  test('an unknown format or status decodes to unknown instead of throwing', () {
    final course = Course.fromJson(const {
      'id': 'c',
      'slug': 's',
      'title': 't',
      'levelId': 'l',
      'categoryId': 'k',
      'format': 'seminar',
      'status': 'retired',
      'visibility': 'members',
    });

    expect(course.format, CourseFormat.unknown);
    expect(course.status, CourseStatus.unknown);
    expect(course.visibility, CourseVisibility.unknown);
  });
}
