import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// What the fake adapter should do with one request.
typedef FakeHandler = Future<ResponseBody> Function(RequestOptions options);

/// A Dio adapter that answers from a script instead of the network, and records what was sent —
/// the way modules.md §23 tests an API service.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter([this.handler]);

  /// Answers every request when set; otherwise [queue] is used, in order.
  FakeHandler? handler;
  final List<FakeHandler> queue = [];
  final List<RequestOptions> requests = [];

  /// Bodies sent as multipart, read back as text (uploads).
  final List<int> uploadedByteCounts = [];

  void enqueue(FakeHandler handler) => queue.add(handler);

  void enqueueJson(Object? body, {int status = 200, Map<String, List<String>>? headers}) =>
      enqueue((_) async => jsonResponse(body, status: status, headers: headers));

  void enqueueStatus(int status, {Object? body}) =>
      enqueue((_) async => jsonResponse(body ?? const <String, Object?>{}, status: status));

  void enqueueError(DioExceptionType type, {Object? error}) => enqueue(
    (options) async => throw DioException(requestOptions: options, type: type, error: error),
  );

  static ResponseBody jsonResponse(
    Object? body, {
    int status = 200,
    Map<String, List<String>>? headers,
  }) => ResponseBody.fromString(
    body == null ? '' : jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...?headers,
    },
  );

  /// An empty 204, as `/notifications/clear` and friends answer.
  static ResponseBody noContent() => ResponseBody.fromString('', 204);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) {
      var bytes = 0;
      await for (final chunk in requestStream) {
        bytes += chunk.length;
      }
      uploadedByteCounts.add(bytes);
    }
    final next = handler ?? (queue.isNotEmpty ? queue.removeAt(0) : null);
    if (next == null) {
      throw StateError('No fake response queued for ${options.method} ${options.path}');
    }
    return next(options);
  }

  @override
  void close({bool force = false}) {}

  RequestOptions get lastRequest => requests.last;

  String? authorizationOf(RequestOptions options) => options.headers['Authorization'] as String?;

  static Map<String, dynamic> decode(String body) => jsonDecode(body) as Map<String, dynamic>;
}
