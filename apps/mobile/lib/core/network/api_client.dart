import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../errors/app_failure.dart';
import '../logging/app_logger.dart';
import 'api_exception.dart';
import 'error_decoder.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/log_interceptor.dart';
import 'interceptors/request_id_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'token_store.dart';

/// The one HTTP client (§10.2). Feature API services call it with paths from `ApiPath`; it returns
/// the decoded JSON body untouched (an object, a list, a bare number, or `null` for 204 and for a
/// literal `null`) and throws [ApiException] with a typed failure for everything else.
class ApiClient {
  ApiClient({
    required AppConfig config,
    required TokenStore tokenStore,
    required AppLogger logger,
    void Function()? onSessionExpired,
    void Function(AccountClosedFailure failure)? onAccountClosed,
    HttpClientAdapter? adapter,
    Future<void> Function(Duration)? retryDelay,
    bool logRequests = kDebugMode,
  }) : _onSessionExpired = onSessionExpired,
       _onAccountClosed = onAccountClosed {
    _dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl.toString(),
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
        headers: {'Accept': 'application/json'},
      ),
    );
    if (adapter != null) _dio.httpClientAdapter = adapter;
    _dio.interceptors.addAll([
      RequestIdInterceptor(),
      AuthInterceptor(
        apiBase: config.apiBaseUrl,
        tokenStore: tokenStore,
        onUnauthenticated: _sessionExpired,
      ),
      RetryInterceptor(_dio, delay: retryDelay),
      if (logRequests) ApiLogInterceptor(logger),
    ]);
  }

  late final Dio _dio;
  final void Function()? _onSessionExpired;
  final void Function(AccountClosedFailure failure)? _onAccountClosed;

  /// Decodes a failed exchange. A request that carried a token and was refused because the platform
  /// suspended or closed the account's LMS ends the session: every later request would be refused too.
  AppFailure _failureOf(DioException e) {
    final failure = ErrorDecoder.fromDioException(e);
    if (failure is AccountClosedFailure && e.requestOptions.headers['Authorization'] != null) {
      endSession(except: e.requestOptions.cancelToken);
      _onAccountClosed?.call(failure);
    }
    return failure;
  }

  /// Tokens of the requests in flight, so ending the session can cancel them all.
  final Set<CancelToken> _inFlight = {};

  void _sessionExpired(RequestOptions refused) {
    // The refused request keeps its own 401 failure; everything else in flight is abandoned.
    endSession(except: refused.cancelToken);
    _onSessionExpired?.call();
  }

  /// Cancels every in-flight request (sign-out, session expiry); later requests run normally.
  void endSession({CancelToken? except}) {
    for (final token in _inFlight.toList()) {
      if (identical(token, except)) continue;
      token.cancel('session ended');
      _inFlight.remove(token);
    }
  }

  /// Requests currently in flight (for tests and diagnostics).
  int get inFlightCount => _inFlight.length;

  Future<Object?> get(String path, {Map<String, Object?>? query, CancelToken? cancelToken}) =>
      _send('GET', path, query: query, cancelToken: cancelToken);

  Future<Object?> post(
    String path, {
    Object? body,
    Map<String, Object?>? query,
    CancelToken? cancelToken,
  }) => _send('POST', path, body: body, query: query, cancelToken: cancelToken);

  /// [idempotent] PUTs (e.g. reporting a lesson position) may be retried on network failure.
  Future<Object?> put(
    String path, {
    Object? body,
    bool idempotent = false,
    CancelToken? cancelToken,
  }) => _send(
    'PUT',
    path,
    body: body,
    cancelToken: cancelToken,
    extra: {if (idempotent) RetryInterceptor.idempotentKey: true},
  );

  Future<Object?> patch(String path, {Object? body, CancelToken? cancelToken}) =>
      _send('PATCH', path, body: body, cancelToken: cancelToken);

  Future<Object?> delete(String path, {Object? body, CancelToken? cancelToken}) =>
      _send('DELETE', path, body: body, cancelToken: cancelToken);

  /// Multipart upload of one file in the field `file` (the media route's contract), with progress
  /// (0–1) and cancel. No send timeout: large uploads legitimately take long.
  Future<Object?> upload(
    String path, {
    required MultipartFile file,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) => _send(
    'POST',
    path,
    body: FormData.fromMap({'file': file}),
    cancelToken: cancelToken,
    sendTimeout: Duration.zero,
    onSendProgress: onProgress == null
        ? null
        : (sent, total) {
            if (total > 0) onProgress(sent / total);
          },
  );

  /// Downloads a stored file's bytes (media, an invoice PDF). Progress is 0–1 when the server
  /// sends a length. The bearer goes only to the API host, as for every other request.
  Future<Uint8List> downloadBytes(
    String path, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();
    _inFlight.add(token);
    try {
      final response = await _dio.get<List<int>>(
        path,
        cancelToken: token,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) onProgress(received / total);
        },
      );
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (e) {
      throw ApiException(_failureOf(e));
    } finally {
      _inFlight.remove(token);
    }
  }

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    CancelToken? cancelToken,
    Map<String, Object?> extra = const {},
    Duration? sendTimeout,
    ProgressCallback? onSendProgress,
  }) async {
    final token = cancelToken ?? CancelToken();
    _inFlight.add(token);
    try {
      final response = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: query == null ? null : _withoutNulls(query),
        cancelToken: token,
        onSendProgress: onSendProgress,
        options: Options(method: method, extra: extra, sendTimeout: sendTimeout),
      );
      if (response.statusCode == 204) return null;
      final data = response.data;
      return data is String && data.isEmpty ? null : data;
    } on DioException catch (e) {
      throw ApiException(_failureOf(e));
    } finally {
      _inFlight.remove(token);
    }
  }

  static Map<String, Object?> _withoutNulls(Map<String, Object?> query) => {
    for (final e in query.entries)
      if (e.value != null) e.key: e.value,
  };
}

/// Set by FLUTTER-004 to the secure-storage token store.
final tokenStoreProvider = Provider<TokenStore>(
  (ref) => throw StateError('tokenStoreProvider must be overridden'),
);

/// Set by FLUTTER-004 to move the session to "expired" (§6).
final sessionExpiredHandlerProvider = Provider<void Function()>((ref) => () {});

/// Set at bootstrap to end the session when the platform has suspended or closed the account's LMS.
final accountClosedHandlerProvider = Provider<void Function(AccountClosedFailure)>((ref) => (_) {});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    config: ref.watch(appConfigProvider),
    tokenStore: ref.watch(tokenStoreProvider),
    logger: ref.watch(appLoggerProvider),
    onSessionExpired: () => ref.read(sessionExpiredHandlerProvider)(),
    onAccountClosed: (failure) => ref.read(accountClosedHandlerProvider)(failure),
  ),
);
