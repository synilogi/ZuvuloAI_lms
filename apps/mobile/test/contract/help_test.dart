import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/help/help.dart';

/// Contract tests (§23) for the help centre, against what the real API returned.
Object? _fixture(String name) =>
    jsonDecode(File('test/fixtures/help/$name.json').readAsStringSync());

List<HelpArticleListItem> _articles(String name) => [
  for (final row in _fixture(name)! as List<dynamic>)
    HelpArticleListItem.fromJson(row as Map<String, dynamic>),
];

void main() {
  test('GET /help/categories?audience=all — tiles carry the count for that audience', () {
    final tiles = [
      for (final row in _fixture('categories-visitor')! as List<dynamic>)
        HelpCategorySummary.fromJson(row as Map<String, dynamic>),
    ];

    expect(tiles, isNotEmpty);
    expect(tiles.first.category.name, 'Getting started');
    expect(tiles.first.category.icon, HelpCategoryIcon.rocket);
    expect(tiles.first.articleCount, 1);
    // "Courses & lessons" holds one article, written for learners — a visitor is offered none.
    expect(tiles.last.articleCount, 0);
  });

  test('the audience decides what comes back — a visitor never sees a learner article', () {
    final visitor = _articles('articles-visitor');
    final student = _articles('articles-student');

    expect(visitor.every((i) => i.article.audience == HelpAudience.all), isTrue);
    expect(student.length, greaterThan(visitor.length));
    expect(student.map((i) => i.article.audience), contains(HelpAudience.student));
    expect(visitor.map((i) => i.article.slug), isNot(contains('how-enrolment-works')));
  });

  test('GET /help/articles/:slug — the article, its category and any related ones', () {
    final detail = HelpArticleDetail.fromJson(_fixture('article')! as Map<String, dynamic>);

    expect(detail.article.slug, 'welcome-to-syniastrolms');
    expect(detail.categoryName, 'Getting started');
    expect(detail.article.readMinutes, 2);
    expect(detail.article.popular, isTrue);
    expect(detail.article.tags, contains('orientation'));
    expect(detail.article.body, startsWith('## Welcome'));
  });

  test('an audience this build does not know reads as "all"', () {
    final item = HelpArticleListItem.fromJson({
      'article': {
        ...((_fixture('articles-visitor')! as List<dynamic>).first
                as Map<String, dynamic>)['article']!
            as Map<String, dynamic>,
        'audience': 'partner',
      },
      'categoryName': 'Getting started',
    });

    expect(item.article.audience, HelpAudience.all);
  });
}
