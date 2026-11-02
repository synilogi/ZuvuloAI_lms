import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/core/network/token_store.dart';
import 'package:syniastrolms_mobile/features/help/data/dto/help_models.dart';
import 'package:syniastrolms_mobile/features/help/data/help_api.dart';
import 'package:syniastrolms_mobile/features/media/data/media_api.dart';
import 'package:syniastrolms_mobile/features/public_catalog/data/catalog_api.dart';
import 'package:syniastrolms_mobile/features/verify/data/verify_api.dart';

/// The public experience against the **real** API on the scratch database
/// (`tool/contract_server.sh start`). Nothing here is mocked.
const _password = 'syniastrolms123';

class _Token implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppConfig config;
  late ApiClient visitor;

  ApiClient clientFor(TokenStore store) => ApiClient(
    config: config,
    tokenStore: store,
    logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
    logRequests: false,
  );

  setUpAll(() {
    config = AppConfig.fromEnvironment(Flavor.dev);
    // Signed out: this client has no token to send on any public call.
    visitor = clientFor(_Token());
  });

  Future<_Token> signIn(String email) async {
    final store = _Token();
    final body = await clientFor(
      _Token(),
    ).post('/auth/login', body: {'email': email, 'password': _password});
    store.token = (body! as Map)['token'] as String;
    return store;
  }

  group('the catalogue', () {
    testWidgets('a visitor sees exactly the published public courses', (tester) async {
      final courses = await CatalogApi(visitor).courses();

      expect(courses, isNotEmpty);
      expect(courses.every((c) => c.status.name == 'published'), isTrue);
      expect(courses.every((c) => c.visibility.name == 'public'), isTrue);
      expect(courses.map((c) => c.slug), contains('maths-foundations'));
    });

    testWidgets('a level narrows the list on the server, not here', (tester) async {
      final api = CatalogApi(visitor);
      final levels = await api.levels();
      final beginner = levels.firstWhere((l) => l.order == 1);

      final all = await api.courses();
      final narrowed = await api.courses(levelId: beginner.id);

      expect(narrowed, isNotEmpty);
      expect(narrowed.length, lessThan(all.length));
      expect(narrowed.every((c) => c.levelId == beginner.id), isTrue);
    });

    testWidgets('a lesson that is not a free preview arrives with no body', (tester) async {
      final course = await CatalogApi(visitor).course('maths-foundations');

      final locked = course.lessons.where((l) => !l.isPreview).toList();
      expect(locked, isNotEmpty);
      expect(locked.every((l) => l.content == null || l.content!.isEmpty), isTrue);
      expect(locked.every((l) => l.title.isNotEmpty), isTrue, reason: 'the outline is public');
    });

    testWidgets('a course that is not published is not found', (tester) async {
      await expectLater(
        CatalogApi(visitor).course('no-such-course'),
        throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
      );
    });

    testWidgets('an instructor opens a reading lesson, and a visitor can then read it', (
      tester,
    ) async {
      final api = CatalogApi(visitor);
      final before = await api.course('maths-foundations');
      final reading = before.chapters
          .expand((c) => c.lessons)
          .firstWhere((l) => l.type == 'reading' && !l.isPreview);
      expect(reading.content?.article, isNull, reason: 'not a preview yet');

      // Real staff write: the academy decides what is free to preview.
      final instructor = await signIn('meenakshi@syniastrolms.test');
      await clientFor(
        instructor,
      ).patch('/courses/${before.id}/lessons/${reading.id}', body: {'isPreview': true});
      addTearDown(() async {
        await clientFor(
          instructor,
        ).patch('/courses/${before.id}/lessons/${reading.id}', body: {'isPreview': false});
      });

      final after = await api.course('maths-foundations');
      final preview = after.lessons.firstWhere((l) => l.id == reading.id);

      expect(preview.isPlayablePreview, isTrue);
      expect(preview.content?.article?.body, isNotEmpty);
    });

    testWidgets('course media needs a session, so a visitor is never offered a player', (
      tester,
    ) async {
      // Backend finding B14 (progress.md): `GET /media/:id` is behind `requireAuth`, so a free
      // preview that is a video or a document cannot be played signed out.
      await expectLater(
        MediaApi(visitor).bytes('any-media-id'),
        throwsA(
          isA<ApiException>().having((e) => e.failure, 'failure', isA<UnauthenticatedFailure>()),
        ),
      );
    });
  });

  group('the help centre', () {
    testWidgets('a visitor is served the articles written for everyone', (tester) async {
      final api = HelpApi(visitor);

      final categories = await api.categories(HelpAudience.all);
      final articles = await api.articles(audience: HelpAudience.all);

      expect(categories, isNotEmpty);
      expect(articles, isNotEmpty);
      expect(articles.every((i) => i.article.audience == HelpAudience.all), isTrue);
    });

    testWidgets('a learner is served more than a visitor', (tester) async {
      final api = HelpApi(visitor);

      final forVisitor = await api.articles(audience: HelpAudience.all);
      final forLearner = await api.articles(audience: HelpAudience.student);

      expect(forLearner.length, greaterThan(forVisitor.length));
    });

    testWidgets('one article comes back with its category and body', (tester) async {
      final detail = await HelpApi(
        visitor,
      ).article(slug: 'welcome-to-syniastrolms', audience: HelpAudience.all);

      expect(detail.article.title, 'Welcome to ZuviloAI');
      expect(detail.categoryName, isNotEmpty);
      expect(detail.article.body, contains('##'));
    });
  });

  group('certificate verification', () {
    testWidgets('a seeded issued certificate verifies', (tester) async {
      final result = await VerifyApi(visitor).verify('SA-JY-2026-00142');

      expect(result.isValid, isTrue);
      expect(result.student.name, isNotEmpty);
      expect(result.courseTitle, isNotEmpty);
      expect(result.certificate.issuedAt, isNotNull);
    });

    testWidgets('an unknown ID and a certificate still pending answer the same', (tester) async {
      Matcher notFound(String message) => isA<ApiException>().having(
        (e) => e.failure,
        'failure',
        isA<NotFoundFailure>().having((f) => f.message, 'message', message),
      );
      const message = 'No certificate matches this credential ID.';

      await expectLater(VerifyApi(visitor).verify('NOPE-1'), throwsA(notFound(message)));
      // SA-JY-2026-00231 is seeded as `pending` — earned, not yet issued.
      await expectLater(VerifyApi(visitor).verify('SA-JY-2026-00231'), throwsA(notFound(message)));
    });

    testWidgets('a certificate the academy revokes verifies as revoked', (tester) async {
      final admin = await signIn('admin@syniastrolms.test');
      final listed = await clientFor(
        admin,
      ).get('/certificates', query: {'search': 'SA-JY-2026-00198'});
      final row = ((listed! as Map)['rows']! as List).single as Map;
      final id = (row['certificate']! as Map)['id']! as String;

      await clientFor(admin).post('/certificates/$id/revoke', body: {'reason': 'Issued in error.'});

      final result = await VerifyApi(visitor).verify('SA-JY-2026-00198');

      expect(result.isRevoked, isTrue);
      expect(result.isValid, isFalse);
      expect(result.certificate.revokedReason, 'Issued in error.');
    });
  });
}
