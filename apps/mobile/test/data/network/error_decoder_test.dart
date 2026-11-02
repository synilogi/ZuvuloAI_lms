import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/network/error_decoder.dart';

Object? _fixture(String name) => jsonDecode(File('test/fixtures/$name').readAsStringSync());

DioException _noResponse(DioExceptionType type, {Object? error}) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: type,
  error: error,
);

void main() {
  group('no response', () {
    test('timeouts', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(
          ErrorDecoder.fromDioException(_noResponse(type)),
          isA<NetworkFailure>().having((f) => f.problem, 'problem', NetworkProblem.timeout),
        );
      }
    });

    test('offline, DNS, TLS, cancellation', () {
      NetworkProblem problemOf(DioException e) =>
          (ErrorDecoder.fromDioException(e) as NetworkFailure).problem;
      expect(
        problemOf(
          _noResponse(
            DioExceptionType.connectionError,
            error: const SocketException('Connection failed'),
          ),
        ),
        NetworkProblem.offline,
      );
      expect(
        problemOf(
          _noResponse(
            DioExceptionType.connectionError,
            error: const SocketException('Failed host lookup: api.test'),
          ),
        ),
        NetworkProblem.dns,
      );
      expect(
        problemOf(_noResponse(DioExceptionType.connectionError, error: const HandshakeException())),
        NetworkProblem.tls,
      );
      expect(problemOf(_noResponse(DioExceptionType.badCertificate)), NetworkProblem.tls);
      expect(problemOf(_noResponse(DioExceptionType.cancel)), NetworkProblem.cancelled);
    });
  });

  group('the §10.3 status/code table', () {
    test('400 validation with issues', () {
      final failure = ErrorDecoder.fromResponse(400, {
        'message': 'Check the request and try again.',
        'issues': [
          {'path': 'password', 'message': 'Required'},
        ],
      });
      expect(
        failure,
        isA<ValidationFailure>()
            .having((f) => f.message, 'message', 'Check the request and try again.')
            .having((f) => f.issues.single.key, 'issue key', 'password'),
      );
    });

    test('401 with and without a code', () {
      expect(
        ErrorDecoder.fromResponse(401, {'message': 'Sign in required'}),
        isA<UnauthenticatedFailure>(),
      );
      expect(
        ErrorDecoder.fromResponse(401, {'message': 'x', 'code': 'UNAUTHENTICATED'}),
        isA<UnauthenticatedFailure>(),
      );
    });

    test('402 subscription codes', () {
      EntitlementProblem problemOf(int status, String? code) =>
          (ErrorDecoder.fromResponse(status, {'message': 'm', 'code': ?code}) as EntitlementFailure)
              .problem;
      expect(problemOf(402, 'SUBSCRIPTION_REQUIRED'), EntitlementProblem.subscriptionRequired);
      expect(problemOf(402, 'SUBSCRIPTION_EXPIRED'), EntitlementProblem.subscriptionExpired);
      expect(problemOf(402, 'SUBSCRIPTION_PAST_DUE'), EntitlementProblem.subscriptionPastDue);
      expect(problemOf(402, null), EntitlementProblem.subscriptionRequired);
    });

    test('403 splits permission from entitlement, and plain refusals', () {
      expect(
        ErrorDecoder.fromResponse(403, {'message': 'Not allowed', 'code': 'PERMISSION_DENIED'}),
        isA<PermissionFailure>(),
      );
      expect(
        ErrorDecoder.fromResponse(403, {'message': 'm', 'code': 'FEATURE_NOT_INCLUDED'}),
        isA<EntitlementFailure>().having(
          (f) => f.problem,
          'problem',
          EntitlementProblem.featureNotIncluded,
        ),
      );
      expect(
        ErrorDecoder.fromResponse(403, {'message': 'm', 'code': 'LIMIT_REACHED'}),
        isA<EntitlementFailure>().having(
          (f) => f.problem,
          'problem',
          EntitlementProblem.limitReached,
        ),
      );
      expect(
        ErrorDecoder.fromResponse(403, {'message': 'This account has been deactivated.'}),
        isA<ForbiddenFailure>().having(
          (f) => f.message,
          'message',
          'This account has been deactivated.',
        ),
      );
    });

    test('404, 413, 429', () {
      expect(ErrorDecoder.fromResponse(404, {'message': 'Not found.'}), isA<NotFoundFailure>());
      expect(
        ErrorDecoder.fromResponse(413, {'message': 'The file is too large.'}),
        isA<PayloadTooLargeFailure>(),
      );
      expect(
        ErrorDecoder.fromResponse(429, {'message': 'Too many attempts.'}),
        isA<RateLimitedFailure>(),
      );
    });

    test('409 keeps its code and domain issues (field form)', () {
      final failure =
          ErrorDecoder.fromResponse(409, {
                'message': 'This course is not ready to publish.',
                'code': 'CONFLICT',
                'issues': [
                  {'field': 'lesson-media', 'message': 'Add the video before publishing.'},
                ],
              })
              as ConflictFailure;
      expect(failure.code, 'CONFLICT');
      expect(failure.issues.single.key, 'lesson-media');
      expect(failure.issues.single.message, 'Add the video before publishing.');
    });

    test('502 PAYMENT_FAILED, other 5xx, and the generic server message is dropped', () {
      expect(
        ErrorDecoder.fromResponse(502, {
          'message': 'The payment could not be taken.',
          'code': 'PAYMENT_FAILED',
        }),
        isA<PaymentFailure>(),
      );
      expect(
        ErrorDecoder.fromResponse(503, {'message': 'Maintenance'}),
        isA<ServerFailure>()
            .having((f) => f.status, 'status', 503)
            .having((f) => f.message, 'message', 'Maintenance'),
      );
      expect(
        (ErrorDecoder.fromResponse(500, {'message': 'Something went wrong.'}) as ServerFailure)
            .message,
        isNull,
      );
    });

    test('an unknown code falls back to the status, and a non-object body is tolerated', () {
      expect(
        ErrorDecoder.fromResponse(403, {'message': 'm', 'code': 'SOMETHING_NEW'}),
        isA<ForbiddenFailure>(),
      );
      expect(ErrorDecoder.fromResponse(404, 'plain text'), isA<NotFoundFailure>());
      expect(
        ErrorDecoder.fromResponse(415, {'message': 'Unsupported request encoding.'}),
        isA<ValidationFailure>(),
      );
    });

    test('malformed issues are ignored rather than guessed at', () {
      final failure =
          ErrorDecoder.fromResponse(400, {
                'message': 'm',
                'issues': [
                  'just a string',
                  42,
                  {'message': 'kept'},
                ],
              })
              as ValidationFailure;
      expect(failure.issues.single.message, 'kept');
    });
  });

  group('real responses captured from the local contract server', () {
    test('401 GET /auth/me', () {
      expect(
        ErrorDecoder.fromResponse(401, _fixture('errors/unauthenticated.json')),
        isA<UnauthenticatedFailure>().having((f) => f.message, 'message', 'Sign in required'),
      );
    });

    test('400 POST /auth/login maps zod issues by path', () {
      final failure =
          ErrorDecoder.fromResponse(400, _fixture('errors/validation.json')) as ValidationFailure;
      expect(failure.issues.single.path, 'password');
      expect(failure.issues.single.key, 'password');
      expect(failure.message, 'Check the request and try again.');
    });

    test('404 unknown course', () {
      expect(
        ErrorDecoder.fromResponse(404, _fixture('errors/not-found.json')),
        isA<NotFoundFailure>().having((f) => f.message, 'message', 'Course not found.'),
      );
    });

    test('401 wrong credentials is not distinguished from an unknown e-mail', () {
      expect(
        ErrorDecoder.fromResponse(401, _fixture('errors/bad-credentials.json')),
        isA<UnauthenticatedFailure>().having(
          (f) => f.message,
          'message',
          'Incorrect email or password.',
        ),
      );
    });
  });
}
