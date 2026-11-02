import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/help/help.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

void _serve(FakeAdapter adapter, {Object? articles, Object? categories}) {
  adapter.handler = (options) async => switch (options.path) {
    '/help/categories' => FakeAdapter.jsonResponse(
      categories ?? fixture('help/categories-visitor.json'),
    ),
    '/help/articles' => FakeAdapter.jsonResponse(articles ?? fixture('help/articles-visitor.json')),
    '/help/articles/welcome-to-syniastrolms' => FakeAdapter.jsonResponse(
      fixture('help/article.json'),
    ),
    '/help/articles/staff-only' => FakeAdapter.jsonResponse({'message': 'not-found'}, status: 404),
    _ => throw StateError('unexpected ${options.path}'),
  };
}

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  group('the hub', () {
    testWidgets('offers the popular articles and the topics, with their counts', (tester) async {
      _serve(adapter);

      await pumpPublic(tester, const HelpHubScreen(), adapter: adapter);
      await tester.pumpAndSettle();

      expect(find.text('Popular articles'), findsOneWidget);
      expect(find.text('Welcome to ZuviloAI'), findsOneWidget);
      expect(find.text('Browse by topic'), findsOneWidget);
      expect(find.text('Getting started'), findsOneWidget);
      expect(find.text('1 article'), findsOneWidget);
      expect(find.text('No articles'), findsOneWidget);
    });

    testWidgets('a visitor is read as the "all" audience; a learner as their role', (tester) async {
      _serve(adapter);

      await pumpPublic(tester, const HelpHubScreen(), adapter: adapter);
      await tester.pumpAndSettle();
      expect(adapter.requests.map((r) => r.queryParameters['audience']).toSet(), {'all'});

      adapter.requests.clear();
      await pumpPublic(tester, const HelpHubScreen(), adapter: adapter, signedInAs: learner());
      await tester.pumpAndSettle();
      expect(adapter.requests.map((r) => r.queryParameters['audience']).toSet(), {'student'});
    });

    testWidgets('searching asks the server, once the typing pauses', (tester) async {
      _serve(adapter);

      await pumpPublic(tester, const HelpHubScreen(), adapter: adapter);
      await tester.pumpAndSettle();
      adapter.requests.clear();

      await tester.enterText(find.byType(TextField), 'enrol');
      await tester.pump(const Duration(milliseconds: 100));
      expect(adapter.requests, isEmpty, reason: 'no request while still typing');

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(adapter.requests.last.queryParameters['search'], 'enrol');
    });

    testWidgets('a search with no results offers to clear it', (tester) async {
      _serve(adapter, articles: const <Object>[]);

      await pumpPublic(tester, const HelpHubScreen(), adapter: adapter);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('No matches'), findsOneWidget);
    });

    testWidgets('an academy with no published help says so', (tester) async {
      _serve(adapter, articles: const <Object>[], categories: const <Object>[]);

      await pumpPublic(tester, const HelpHubScreen(), adapter: adapter);
      await tester.pumpAndSettle();

      expect(find.text('No articles yet'), findsOneWidget);
    });
  });

  group('an article', () {
    testWidgets('renders the markup subset and its meta line', (tester) async {
      _serve(adapter);

      await pumpPublic(
        tester,
        const HelpArticleScreen(slug: 'welcome-to-syniastrolms'),
        adapter: adapter,
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to ZuviloAI'), findsOneWidget);
      expect(find.byType(ArticleBody), findsOneWidget);
      expect(find.textContaining('Getting started'), findsWidgets);
      expect(find.textContaining('2 min read'), findsWidgets);
      expect(find.textContaining('Browse courses from'), findsOneWidget);
    });

    testWidgets('an article this audience may not read is a not-found', (tester) async {
      _serve(adapter);

      await pumpPublic(tester, const HelpArticleScreen(slug: 'staff-only'), adapter: adapter);
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundView), findsOneWidget);
    });
  });

  testWidgets('a topic lists its articles', (tester) async {
    _serve(adapter);

    await pumpPublic(
      tester,
      const HelpCategoryScreen(categoryId: 'cmudqdau300kammgzk20ly7uc'),
      adapter: adapter,
    );
    await tester.pumpAndSettle();

    expect(adapter.requests.last.queryParameters['categoryId'], 'cmudqdau300kammgzk20ly7uc');
    expect(find.text('Welcome to ZuviloAI'), findsOneWidget);
  });
}
