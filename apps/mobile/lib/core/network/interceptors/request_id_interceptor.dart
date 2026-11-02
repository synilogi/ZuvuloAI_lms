import 'dart:math';

import 'package:dio/dio.dart';

/// Adds a random `X-Request-Id` for log correlation (§10.2). Random, never user-derived; the server
/// ignores headers it does not know.
class RequestIdInterceptor extends Interceptor {
  RequestIdInterceptor([Random? random]) : _random = random ?? Random.secure();

  final Random _random;

  static const header = 'X-Request-Id';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[header] = List.generate(
      16,
      (_) => _random.nextInt(16).toRadixString(16),
    ).join();
    handler.next(options);
  }
}
