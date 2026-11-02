import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/features/public_catalog/public_catalog.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

const _course = Course(
  id: 'c1',
  slug: 'foundations-vedic',
  title: 'Foundations of Vedic Astrology',
  subtitle: 'Planets, signs and houses',
  levelId: 'beginner',
  categoryId: 'foundations',
  tags: ['Beginner', 'Foundations'],
);

void main() {
  group('client-side search', () {
    test('matches the title, the subtitle and the tags, ignoring case', () {
      expect(courseMatches(_course, ''), isTrue);
      expect(courseMatches(_course, '  '), isTrue);
      expect(courseMatches(_course, 'vedic'), isTrue);
      expect(courseMatches(_course, 'HOUSES'), isTrue);
      expect(courseMatches(_course, 'foundations'), isTrue);
      expect(courseMatches(_course, 'jaimini'), isFalse);
    });

    test('never matches on a field a person cannot see', () {
      expect(courseMatches(_course, 'c1'), isFalse);
      expect(courseMatches(_course, 'beginner-level-id'), isFalse);
    });
  });

  test('a course lists its instructors in its own order, skipping unknown ids', () {
    const course = Course(
      id: 'c1',
      slug: 's',
      title: 't',
      levelId: 'l',
      categoryId: 'k',
      instructorIds: ['i2', 'missing', 'i1'],
    );
    const all = [Instructor(id: 'i1', name: 'Vinod'), Instructor(id: 'i2', name: 'Meenakshi')];

    expect(instructorsOf(course, all).map((i) => i.name), ['Meenakshi', 'Vinod']);
  });

  group('the filter', () {
    late ProviderContainer container;
    late FakeAdapter adapter;

    setUp(() {
      adapter = FakeAdapter()
        ..handler = (options) async => switch (options.path) {
          '/catalog/categories' => FakeAdapter.jsonResponse(fixture('catalog/categories.json')),
          _ => FakeAdapter.jsonResponse(fixture('catalog/courses.json')),
        };
      container = ProviderContainer(
        retry: noProviderRetry,
        overrides: publicScope(adapter: adapter, child: const SizedBox()).overrides,
      );
      addTearDown(container.dispose);
    });

    test('narrowing the level drops a topic that level does not cover', () async {
      final categories = await container.read(catalogCategoriesProvider.future);
      final predictive = categories.firstWhere((c) => c.name == 'Predictive Techniques');
      final otherLevel = categories.firstWhere((c) => c.name == 'Vedic Foundations').levelIds.first;
      final notifier = container.read(catalogFilterProvider.notifier);

      notifier.setCategory(predictive.id);
      expect(container.read(catalogFilterProvider).categoryId, predictive.id);

      notifier.setLevel(otherLevel);
      expect(container.read(catalogFilterProvider).levelId, otherLevel);
      expect(
        container.read(catalogFilterProvider).categoryId,
        isNull,
        reason: 'that topic is not offered at this level',
      );
    });

    test('a topic that does cover the level is kept', () async {
      final categories = await container.read(catalogCategoriesProvider.future);
      final foundations = categories.firstWhere((c) => c.name == 'Vedic Foundations');
      final notifier = container.read(catalogFilterProvider.notifier);

      notifier.setCategory(foundations.id);
      notifier.setLevel(foundations.levelIds.first);

      expect(container.read(catalogFilterProvider).categoryId, foundations.id);
    });

    test('clearing the level keeps the topic, and clear() empties both', () async {
      await container.read(catalogCategoriesProvider.future);
      final notifier = container.read(catalogFilterProvider.notifier)
        ..setCategory('any')
        ..setLevel(null);

      expect(container.read(catalogFilterProvider).categoryId, 'any');

      notifier.clear();
      expect(container.read(catalogFilterProvider).isEmpty, isTrue);
    });

    test('a hidden category is never offered — the route does not filter it', () async {
      adapter.handler = (options) async => FakeAdapter.jsonResponse([
        {
          'id': 'hidden',
          'name': 'Retired course',
          'description': '',
          'levelIds': <String>[],
          'order': 9,
          'status': 'hidden',
          'glyph': 'moon',
          'updatedAt': '2026-09-01T00:00:00.000Z',
        },
        {
          'id': 'shown',
          'name': 'Vedic Foundations',
          'description': '',
          'levelIds': <String>[],
          'order': 1,
          'status': 'active',
          'glyph': 'sun',
          'updatedAt': '2026-09-01T00:00:00.000Z',
        },
      ]);

      final categories = await container.read(catalogCategoriesProvider.future);

      expect(categories.map((c) => c.id), ['shown']);
    });
  });
}
