import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/core/network/api_path.dart';
import 'package:syniastrolms_mobile/core/network/interceptors/request_id_interceptor.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/test_config.dart';

void main() {
  late FakeAdapter adapter;
  late FakeTokenStore tokens;
  late List<Duration> delays;
  late int sessionExpiredCalls;

  ApiClient build({String api = 'https://api.test/api'}) => ApiClient(
    config: testConfig(api: api),
    tokenStore: tokens,
    logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
    onSessionExpired: () => sessionExpiredCalls++,
    adapter: adapter,
    retryDelay: (d) async => delays.add(d),
    logRequests: false,
  );

  setUp(() {
    adapter = FakeAdapter();
    tokens = FakeTokenStore();
    delays = [];
    sessionExpiredCalls = 0;
  });

  AppFailure failureOf(Object? error) => (error! as ApiException).failure;

  group('requests', () {
    test('joins the base URL, keeping the /api mount, and decodes the body', () async {
      adapter.enqueueJson({'ok': true});
      final client = build();

      final body = await client.get('/health');

      expect(body, {'ok': true});
      expect(adapter.lastRequest.uri.toString(), 'https://api.test/api/health');
      expect(adapter.lastRequest.headers['Accept'], 'application/json');
      expect(adapter.lastRequest.headers[RequestIdInterceptor.header], isA<String>());
    });

    test('drops null query values and sends the rest', () async {
      adapter.enqueueJson(const []);
      await build().get('/catalog/courses', query: {'levelId': 'lvl_1', 'search': null, 'page': 2});

      expect(adapter.lastRequest.queryParameters, {'levelId': 'lvl_1', 'page': 2});
    });

    test('handles 204, an empty body, a bare number and a literal null', () async {
      final client = build();
      adapter
        ..enqueue((_) async => FakeAdapter.noContent())
        ..enqueueJson(3)
        ..enqueue(
          (_) async => ResponseBody.fromString(
            'null',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );

      expect(await client.post('/notifications/clear'), isNull);
      expect(await client.post('/notifications/read-all'), 3);
      expect(await client.get('/learning/attempt'), isNull);
    });

    test('sends the body as JSON', () async {
      adapter.enqueueJson({'token': 't'});
      await build().post('/auth/login', body: {'email': 'a@b.test', 'password': 'x'});

      expect(adapter.lastRequest.data, {'email': 'a@b.test', 'password': 'x'});
    });
  });

  group('bearer token', () {
    test('is attached to the API origin only', () async {
      tokens.token = 'jwt-value';
      adapter
        ..enqueueJson({'user': <String, Object?>{}})
        ..enqueueJson({'ok': true});
      final client = build();

      await client.get('/auth/me');
      expect(adapter.lastRequest.headers['Authorization'], 'Bearer jwt-value');

      await client.get('https://meeting.example/room/1');
      expect(adapter.lastRequest.headers.containsKey('Authorization'), isFalse);
    });

    test('is absent when signed out', () async {
      adapter.enqueueJson(const []);
      await build().get('/catalog/levels');

      expect(adapter.lastRequest.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('session expiry', () {
    test('the first 401 signals expiry once and cancels the other requests in flight', () async {
      tokens.token = 'expired-token';
      adapter.handler = (options) async =>
          FakeAdapter.jsonResponse({'message': 'Sign in required'}, status: 401);
      final client = build();

      final results = await Future.wait([
        client.get('/learning/home').then<Object?>((v) => v, onError: (Object e) => e),
        client.get('/notifications').then<Object?>((v) => v, onError: (Object e) => e),
        client.get('/auth/me').then<Object?>((v) => v, onError: (Object e) => e),
      ]);

      // The first 401 ends the session, which cancels whatever else is in flight (§6).
      final failures = results.map<AppFailure>(failureOf).toList();
      expect(failures.whereType<UnauthenticatedFailure>(), hasLength(1));
      expect(
        failures.whereType<NetworkFailure>().every((f) => f.problem == NetworkProblem.cancelled),
        isTrue,
      );
      expect(sessionExpiredCalls, 1);
    });

    test('a 401 without a token does not end the session', () async {
      adapter.enqueueStatus(401, body: {'message': 'Sign in required'});

      await expectLater(build().get('/auth/me'), throwsA(isA<ApiException>()));
      expect(sessionExpiredCalls, 0);
    });

    test('a later, different token can expire again', () async {
      final client = build();
      adapter.handler = (_) async => FakeAdapter.jsonResponse({'message': 'x'}, status: 401);

      tokens.token = 'first';
      await client.get('/auth/me').catchError((Object e) => e);
      await client.get('/auth/me').catchError((Object e) => e);
      tokens.token = 'second';
      await client.get('/auth/me').catchError((Object e) => e);

      expect(sessionExpiredCalls, 2);
    });

    test('endSession cancels the requests in flight', () async {
      final client = build();
      final gate = Completer<void>();
      adapter.handler = (options) async {
        await gate.future;
        return FakeAdapter.jsonResponse({'ok': true});
      };

      final pending = client
          .get('/learning/home')
          .then<Object?>((v) => v, onError: (Object e) => e);
      await Future<void>.delayed(Duration.zero);
      expect(client.inFlightCount, 1);
      client.endSession();
      gate.complete();

      expect(
        failureOf(await pending),
        isA<NetworkFailure>().having((f) => f.problem, 'problem', NetworkProblem.cancelled),
      );
      expect(client.inFlightCount, 0);
    });

    test('a caller\'s cancel token stops its own request', () async {
      final client = build();
      final token = CancelToken();
      adapter.handler = (options) async {
        token.cancel();
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return FakeAdapter.jsonResponse({'ok': true});
      };

      final result = await client
          .get('/learning/home', cancelToken: token)
          .then<Object?>((v) => v, onError: (Object e) => e);

      expect(
        failureOf(result),
        isA<NetworkFailure>().having((f) => f.problem, 'problem', NetworkProblem.cancelled),
      );
    });
  });

  group('retry', () {
    test('retries a GET twice on 503, then fails, with growing backoff', () async {
      adapter.handler = (_) async => FakeAdapter.jsonResponse({'message': 'busy'}, status: 503);

      await expectLater(build().get('/catalog/levels'), throwsA(isA<ApiException>()));

      expect(adapter.requests, hasLength(3));
      expect(delays, hasLength(2));
      expect(delays[1], greaterThan(delays[0]));
    });

    test('recovers when a retry succeeds', () async {
      adapter
        ..enqueueError(DioExceptionType.connectionError)
        ..enqueueJson({'ok': true});

      expect(await build().get('/health'), {'ok': true});
      expect(adapter.requests, hasLength(2));
    });

    test('never retries POST, PATCH or DELETE', () async {
      final client = build();
      for (final send in [
        () => client.post('/auth/login', body: const {}),
        () => client.patch('/live/1', body: const {}),
        () => client.delete('/notifications/1'),
      ]) {
        adapter
          ..requests.clear()
          ..handler = (_) async => FakeAdapter.jsonResponse({'message': 'busy'}, status: 503);
        await expectLater(send(), throwsA(isA<ApiException>()));
        expect(adapter.requests, hasLength(1));
      }
      expect(delays, isEmpty);
    });

    test('retries a PUT only when it is marked idempotent', () async {
      final client = build();
      adapter.handler = (_) async => FakeAdapter.jsonResponse({'message': 'busy'}, status: 503);

      await expectLater(client.put('/x', body: const {}), throwsA(isA<ApiException>()));
      expect(adapter.requests, hasLength(1));

      adapter.requests.clear();
      await expectLater(
        client.put('/learning/position', body: const {}, idempotent: true),
        throwsA(isA<ApiException>()),
      );
      expect(adapter.requests, hasLength(3));
    });

    test('does not retry a 500 or a 404', () async {
      final client = build();
      for (final status in [500, 404]) {
        adapter
          ..requests.clear()
          ..handler = (_) async => FakeAdapter.jsonResponse({'message': 'x'}, status: status);
        await expectLater(client.get('/x'), throwsA(isA<ApiException>()));
        expect(adapter.requests, hasLength(1), reason: 'status $status');
      }
    });
  });

  group('upload', () {
    test('sends one multipart file field with progress', () async {
      adapter.enqueueJson({'id': 'media_1', 'url': '/media/media_1'});
      final progress = <double>[];

      final body = await build().upload(
        '/media/upload',
        file: MultipartFile.fromBytes(List.filled(2048, 7), filename: 'chart.pdf'),
        onProgress: progress.add,
      );

      expect(body, {'id': 'media_1', 'url': '/media/media_1'});
      expect(adapter.lastRequest.data, isA<FormData>());
      expect((adapter.lastRequest.data! as FormData).files.single.key, 'file');
      expect(adapter.lastRequest.sendTimeout, Duration.zero);
      expect(progress, isNotEmpty);
      expect(progress.last, 1.0);
    });

    test('honours cancellation', () async {
      final token = CancelToken();
      adapter.handler = (_) async {
        token.cancel();
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return FakeAdapter.jsonResponse({'id': 'x'});
      };

      final result = await build()
          .upload(
            '/media/upload',
            file: MultipartFile.fromBytes(const [1, 2, 3], filename: 'a.pdf'),
            cancelToken: token,
          )
          .then<Object?>((v) => v, onError: (Object e) => e);

      expect(
        failureOf(result),
        isA<NetworkFailure>().having((f) => f.problem, 'problem', NetworkProblem.cancelled),
      );
    });
  });

  group('debug logging', () {
    test('notes a device clock that differs from the server by more than 5 minutes', () async {
      final lines = <String>[];
      final client = ApiClient(
        config: testConfig(),
        tokenStore: tokens,
        logger: AppLogger(
          reporter: const NoopCrashReporter(),
          minLevel: LogLevel.debug,
          sink: (line, _) => lines.add(line),
        ),
        adapter: adapter,
        logRequests: true,
      );
      adapter.enqueueJson(
        {'ok': true},
        headers: {
          'date': ['Tue, 22 Sep 2026 10:15:00 GMT'],
        },
      );

      await client.get('/health');

      expect(lines.any((l) => l.contains('GET /api/health → 200')), isTrue);
      expect(lines.any((l) => l.contains('device clock differs from server')), isTrue);
    });

    test('a malformed or missing Date header is ignored', () async {
      final lines = <String>[];
      final client = ApiClient(
        config: testConfig(),
        tokenStore: tokens,
        logger: AppLogger(
          reporter: const NoopCrashReporter(),
          minLevel: LogLevel.debug,
          sink: (line, _) => lines.add(line),
        ),
        adapter: adapter,
        logRequests: true,
      );
      adapter.enqueueJson(
        {'ok': true},
        headers: {
          'date': ['not a date'],
        },
      );

      await client.get('/health');

      expect(lines.any((l) => l.contains('device clock differs')), isFalse);
    });
  });

  group('ApiPath', () {
    test('encodes ids and keeps literal segments', () {
      expect(
        ApiPath.of(['learning', 'courses', ApiPath.id('course 1/../x')]),
        '/learning/courses/course%201%2F..%2Fx',
      );
    });

    test('refuses empty, over-long and dot-only ids', () {
      expect(() => ApiPath.id(''), throwsA(isA<ApiException>()));
      expect(() => ApiPath.id('  '), throwsA(isA<ApiException>()));
      expect(() => ApiPath.id('x' * 65), throwsA(isA<ApiException>()));
      expect(() => ApiPath.id('..'), throwsA(isA<ApiException>()));
    });
  });
}
