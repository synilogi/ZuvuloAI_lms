import '../errors/app_failure.dart';

/// Thrown by `ApiClient` and the feature API services; repositories catch it and return
/// `Err(failure)`. It never carries a response body.
class ApiException implements Exception {
  const ApiException(this.failure);

  final AppFailure failure;

  @override
  String toString() => 'ApiException(${failure.runtimeType})';
}
