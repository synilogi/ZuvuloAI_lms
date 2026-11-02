import 'dart:math';

import 'package:dio/dio.dart';

/// Retries idempotent reads on network failures and 502/503/504, twice, with jittered backoff
/// (§10.2, §17). POST, PATCH and DELETE are never retried; a PUT only when marked idempotent.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    this.maxRetries = 2,
    Future<void> Function(Duration)? delay,
    Random? random,
  }) : _delay = delay ?? Future<void>.delayed,
       _random = random ?? Random();

  final Dio _dio;
  final int maxRetries;
  final Future<void> Function(Duration) _delay;
  final Random _random;

  static const idempotentKey = 'retry.idempotent';
  static const _attemptKey = 'retry.attempt';

  static bool isIdempotent(RequestOptions o) {
    final method = o.method.toUpperCase();
    return method == 'GET' ||
        method == 'HEAD' ||
        (method == 'PUT' && o.extra[idempotentKey] == true);
  }

  static bool isRetryable(DioException e) {
    if (e.type == DioExceptionType.cancel) return false;
    final status = e.response?.statusCode;
    if (status != null) return status == 502 || status == 503 || status == 504;
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout;
  }

  /// 300 ms, 600 ms, … plus up to 150 ms of jitter.
  Duration backoff(int attempt) =>
      Duration(milliseconds: 300 * (1 << attempt) + _random.nextInt(150));

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;
    if (!isIdempotent(options) || !isRetryable(err) || attempt >= maxRetries) {
      return handler.next(err);
    }
    await _delay(backoff(attempt));
    if (options.cancelToken?.isCancelled ?? false) return handler.next(err);
    options.extra[_attemptKey] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<Object?>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
