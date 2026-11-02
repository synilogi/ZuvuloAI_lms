import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/core/network/token_store.dart';
import 'package:syniastrolms_mobile/features/help/data/dto/help_models.dart';
import 'package:syniastrolms_mobile/features/help/data/help_api.dart';
import 'package:syniastrolms_mobile/features/public_catalog/data/catalog_api.dart';
import 'package:syniastrolms_mobile/features/verify/data/verify_api.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/test_config.dart';

Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

/// A signed-out visitor: there is no token to send.
class _NoToken implements TokenStore {
  @override
  Future<String?> read() async => null;
}

void main() {
  late FakeAdapter adapter;

  ApiClient clientFor(TokenStore store) => ApiClient(
    config: testConfig(),
    tokenStore: store,
    logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
    adapter: adapter,
    logRequests: false,
  );

  setUp(() => adapter = FakeAdapter());

  group('CatalogApi', () {
    test('a signed-out visitor sends no Authorization header on a public call', () async {
      adapter.enqueueJson(_fixture('catalog/courses.json'));

      await CatalogApi(clientFor(_NoToken())).courses();

      expect(adapter.lastRequest.path, '/catalog/courses');
      expect(adapter.authorizationOf(adapter.lastRequest), isNull);
    });

    test('filters travel as query parameters, and only when set', () async {
      adapter
        ..enqueueJson(_fixture('catalog/courses-beginner.json'))
        ..enqueueJson(_fixture('catalog/courses.json'));
      final api = CatalogApi(clientFor(_NoToken()));

      await api.courses(levelId: 'level_1', categoryId: 'cat_2');
      expect(adapter.lastRequest.queryParameters, {'levelId': 'level_1', 'categoryId': 'cat_2'});

      await api.courses();
      expect(adapter.lastRequest.queryParameters, isEmpty);
    });

    test('a slug is encoded into the path, never concatenated', () async {
      adapter.enqueueJson(_fixture('catalog/course-detail.json'));

      await CatalogApi(clientFor(_NoToken())).course('foundations-vedic');

      expect(adapter.lastRequest.path, '/catalog/courses/foundations-vedic');
    });

    test('a slug that could climb a path segment is refused before any request', () async {
      await expectLater(
        CatalogApi(clientFor(_NoToken())).course('..'),
        throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<ValidationFailure>())),
      );
      expect(adapter.requests, isEmpty);
    });

    test('a course that does not exist comes back as a 404 failure', () async {
      adapter.enqueueJson(_fixture('errors/not-found.json'), status: 404);

      await expectLater(
        CatalogApi(clientFor(_NoToken())).course('no-such-course'),
        throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
      );
    });

    test('a response of the wrong shape becomes a contract failure naming the endpoint', () async {
      adapter.enqueueJson({'courses': <Object>[]});

      await expectLater(
        CatalogApi(clientFor(_NoToken())).courses(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            isA<ContractFailure>().having((f) => f.endpoint, 'endpoint', 'GET /catalog/courses'),
          ),
        ),
      );
    });
  });

  group('HelpApi', () {
    test('the audience is always sent — omitting it would show staff articles', () async {
      adapter
        ..enqueueJson(_fixture('help/categories-visitor.json'))
        ..enqueueJson(_fixture('help/articles-visitor.json'))
        ..enqueueJson(_fixture('help/article.json'));
      final api = HelpApi(clientFor(_NoToken()));

      await api.categories(HelpAudience.all);
      expect(adapter.lastRequest.queryParameters, {'audience': 'all'});

      await api.articles(audience: HelpAudience.student, search: 'enrol');
      expect(adapter.lastRequest.queryParameters, {'audience': 'student', 'search': 'enrol'});

      await api.article(slug: 'welcome-to-syniastrolms', audience: HelpAudience.all);
      expect(adapter.lastRequest.path, '/help/articles/welcome-to-syniastrolms');
      expect(adapter.lastRequest.queryParameters, {'audience': 'all'});
    });

    test('an empty search is not sent as a filter', () async {
      adapter.enqueueJson(_fixture('help/articles-visitor.json'));

      await HelpApi(clientFor(_NoToken())).articles(audience: HelpAudience.all, search: '');

      expect(adapter.lastRequest.queryParameters, {'audience': 'all'});
    });

    test('an article this audience may not read is a 404, like a missing slug', () async {
      adapter.enqueueJson({'message': 'not-found'}, status: 404);

      await expectLater(
        HelpApi(clientFor(_NoToken())).article(slug: 'staff-only', audience: HelpAudience.all),
        throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
      );
    });
  });

  group('VerifyApi', () {
    test('the credential ID is a path segment, sent exactly as given', () async {
      adapter.enqueueJson(_fixture('certificates/verify-valid.json'));

      final result = await VerifyApi(clientFor(_NoToken())).verify('SA-JY-2026-00142');

      expect(adapter.lastRequest.path, '/certificates/verify/SA-JY-2026-00142');
      expect(adapter.authorizationOf(adapter.lastRequest), isNull);
      expect(result.certificate.credentialId, 'SA-JY-2026-00142');
    });

    test('an unknown credential answers 404 with the server\'s own wording', () async {
      adapter.enqueueJson(_fixture('errors/verify-not-found.json'), status: 404);

      await expectLater(
        VerifyApi(clientFor(_NoToken())).verify('NOPE-1'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            isA<NotFoundFailure>().having(
              (f) => f.message,
              'message',
              'No certificate matches this credential ID.',
            ),
          ),
        ),
      );
    });
  });
}
