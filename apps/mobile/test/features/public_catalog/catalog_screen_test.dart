import 'dart:async';

import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/public_catalog/public_catalog.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/pricing.dart';
import '../../helpers/public_harness.dart';

/// The catalogue answers the three public reads it needs; they may arrive in any order.
void _serveCatalog(FakeAdapter adapter, {Object? courses}) {
  adapter.handler = (options) async {
    return switch (options.path) {
      '/catalog/levels' => FakeAdapter.jsonResponse(fixture('catalog/levels.json')),
      '/catalog/categories' => FakeAdapter.jsonResponse(fixture('catalog/categories.json')),
      '/catalog/instructors' => FakeAdapter.jsonResponse(fixture('catalog/instructors.json')),
      '/catalog/courses' => FakeAdapter.jsonResponse(
        courses ?? withPricing(fixture('catalog/courses.json'), 'paid'),
      ),
      _ => throw StateError('unexpected ${options.path}'),
    };
  };
}

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  testWidgets('lists the published public courses the server returned', (tester) async {
    _serveCatalog(adapter);

    await pumpPublic(tester, const CatalogScreen(), adapter: adapter);
    await tester.pumpAndSettle();

    expect(find.text('Foundations of Vedic Astrology'), findsOneWidget);
    expect(find.text('6 courses'), findsOneWidget);
    // The price is the academy's rupees, not paise.
    expect(find.text('₹2,999'), findsOneWidget);
  });

  testWidgets('shows a skeleton first, never an empty list', (tester) async {
    final completer = Completer<void>();
    adapter.handler = (options) async {
      if (options.path == '/catalog/courses') {
        await completer.future;
      }
      return FakeAdapter.jsonResponse(switch (options.path) {
        '/catalog/levels' => fixture('catalog/levels.json'),
        '/catalog/categories' => fixture('catalog/categories.json'),
        '/catalog/instructors' => fixture('catalog/instructors.json'),
        _ => fixture('catalog/courses.json'),
      });
    };

    await pumpPublic(tester, const CatalogScreen(), adapter: adapter);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(SkeletonList), findsOneWidget);
    expect(find.text('No courses published yet'), findsNothing);

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonList), findsNothing);
  });

  testWidgets('an academy with nothing published says so', (tester) async {
    _serveCatalog(adapter, courses: const <Object>[]);

    await pumpPublic(tester, const CatalogScreen(), adapter: adapter);
    await tester.pumpAndSettle();

    expect(find.text('No courses published yet'), findsOneWidget);
  });

  testWidgets('a search that matches nothing offers to clear the filters', (tester) async {
    _serveCatalog(adapter);

    await pumpPublic(tester, const CatalogScreen(), adapter: adapter);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('Foundations of Vedic Astrology'), findsNothing);
    expect(find.text('No matches'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Foundations of Vedic Astrology'), findsOneWidget);
  });

  testWidgets('choosing a level asks the server for that level', (tester) async {
    _serveCatalog(adapter);

    await pumpPublic(tester, const CatalogScreen(), adapter: adapter);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(FilterChipBar<String?>).first,
        matching: find.text('Beginner'),
      ),
    );
    await tester.pumpAndSettle();

    final last = adapter.requests.lastWhere((r) => r.path == '/catalog/courses');
    expect(last.queryParameters['levelId'], isNotNull);
  });

  testWidgets('a failed read offers a retry that reads again', (tester) async {
    var attempt = 0;
    adapter.handler = (options) async {
      if (options.path == '/catalog/courses') {
        attempt++;
        if (attempt == 1) {
          return FakeAdapter.jsonResponse({'message': 'Server error.'}, status: 500);
        }
      }
      return FakeAdapter.jsonResponse(switch (options.path) {
        '/catalog/levels' => fixture('catalog/levels.json'),
        '/catalog/categories' => fixture('catalog/categories.json'),
        '/catalog/instructors' => fixture('catalog/instructors.json'),
        _ => fixture('catalog/courses.json'),
      });
    };

    await pumpPublic(tester, const CatalogScreen(), adapter: adapter);
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Foundations of Vedic Astrology'), findsOneWidget);
  });

  testWidgets('offline says so rather than showing an empty catalogue', (tester) async {
    adapter.handler = (options) async {
      if (options.path == '/catalog/courses') {
        throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
      }
      return FakeAdapter.jsonResponse(switch (options.path) {
        '/catalog/levels' => fixture('catalog/levels.json'),
        '/catalog/categories' => fixture('catalog/categories.json'),
        _ => fixture('catalog/instructors.json'),
      });
    };

    await pumpPublic(tester, const CatalogScreen(), adapter: adapter);
    // The client retries a connection failure twice with backoff, and nothing schedules a frame
    // while it waits, so the test has to let that time pass.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text("You're offline. Connect to continue."), findsOneWidget);
    expect(find.text('No courses published yet'), findsNothing);
  });
}
