import 'package:dio/dio.dart';

import '../token_store.dart';

/// Attaches the bearer token — only to the configured API origin, never to another host (§10.2,
/// §18) — and turns a 401 on a request that carried a token into one session-expired signal, however
/// many requests fail with it at once (§6, single-flight). The refused request itself is handed to
/// the callback so its own failure is not replaced by a cancellation.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Uri apiBase,
    required TokenStore tokenStore,
    required void Function(RequestOptions request) onUnauthenticated,
  }) : _apiBase = apiBase,
       _tokenStore = tokenStore,
       _onUnauthenticated = onUnauthenticated;

  final Uri _apiBase;
  final TokenStore _tokenStore;
  final void Function(RequestOptions request) _onUnauthenticated;

  static const _sentTokenKey = 'auth.sentToken';

  /// The token already reported as expired; a later, different token can expire again.
  String? _expiredToken;

  bool _sameOrigin(Uri uri) =>
      uri.scheme == _apiBase.scheme && uri.host == _apiBase.host && uri.port == _apiBase.port;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers.remove('Authorization');
    if (_sameOrigin(options.uri)) {
      final token = await _tokenStore.read();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        options.extra[_sentTokenKey] = token;
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sent = err.requestOptions.extra[_sentTokenKey];
    if (err.response?.statusCode == 401 && sent is String && sent != _expiredToken) {
      _expiredToken = sent;
      _onUnauthenticated(err.requestOptions);
    }
    handler.next(err);
  }
}
