import 'package:dio/dio.dart';

/// Cancels a request without the rest of the app knowing what HTTP client is underneath: only
/// `core/network` and the data layers may see Dio (§10.1).
class RequestCancellation {
  RequestCancellation();

  final CancelToken _token = CancelToken();

  bool get isCancelled => _token.isCancelled;

  void cancel() {
    if (!_token.isCancelled) _token.cancel();
  }

  /// For the data layer only.
  CancelToken get token => _token;
}
