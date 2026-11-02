import 'package:dio/dio.dart';

import '../../logging/app_logger.dart';

/// Debug-build request log: method, path (redacted by the logger), status and duration — never a
/// header or a body (§18). Also notes when the server clock differs from the device by > 5 min
/// (§17); nothing user-facing depends on the device clock.
class ApiLogInterceptor extends Interceptor {
  ApiLogInterceptor(this._logger);

  final AppLogger _logger;

  static const _startedKey = 'log.startedAt';
  static const _skewLimit = Duration(minutes: 5);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _log(response.requestOptions, response.statusCode);
    _checkClock(response.headers.value('date'));
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, err.response?.statusCode, failure: err.type.name);
    handler.next(err);
  }

  void _log(RequestOptions o, int? status, {String? failure}) {
    final started = o.extra[_startedKey];
    final ms = started is DateTime ? DateTime.now().difference(started).inMilliseconds : null;
    _logger.debug('${o.method} ${o.uri.path} → ${status ?? failure} ${ms ?? '?'} ms');
  }

  void _checkClock(String? dateHeader) {
    if (dateHeader == null) return;
    final server = _tryParseHttpDate(dateHeader);
    if (server == null) return;
    final skew = DateTime.now().toUtc().difference(server).abs();
    if (skew > _skewLimit) {
      _logger.debug('device clock differs from server by ${skew.inMinutes} min');
    }
  }

  static DateTime? _tryParseHttpDate(String value) {
    try {
      return HttpDateParser.parse(value);
    } on FormatException {
      return null;
    }
  }
}

/// RFC 7231 IMF-fixdate ("Tue, 22 Sep 2026 10:15:00 GMT").
abstract final class HttpDateParser {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static DateTime parse(String value) {
    final m = RegExp(
      r'^\w{3}, (\d{2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
    ).firstMatch(value);
    final month = m == null ? -1 : _months.indexOf(m[2]!);
    if (m == null || month < 0) throw FormatException('Not an HTTP date', value);
    return DateTime.utc(
      int.parse(m[3]!),
      month + 1,
      int.parse(m[1]!),
      int.parse(m[4]!),
      int.parse(m[5]!),
      int.parse(m[6]!),
    );
  }
}
