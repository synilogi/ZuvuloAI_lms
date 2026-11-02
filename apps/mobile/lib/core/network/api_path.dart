import '../errors/app_failure.dart';
import 'api_exception.dart';

/// Builds request paths from literal segments and ids. An id must be 1–64 characters (the API's
/// `id` schema) and is URL-encoded, so a value can never add a path segment or a query.
abstract final class ApiPath {
  static const _maxId = 64;

  /// `ApiPath.of(['learning', 'courses', courseId])` → `/learning/courses/<encoded id>`.
  static String of(List<Object> segments) => '/${segments.map(_segment).join('/')}';

  static String _segment(Object segment) => switch (segment) {
    ApiId(:final value) => Uri.encodeComponent(value),
    String() => segment,
    _ => throw ArgumentError('Path segments are literal strings or ApiId values.'),
  };

  /// Validates an id for use in a path.
  static ApiId id(String value) {
    final trimmed = value.trim();
    // Dot-only ids are refused: Dio normalises the URL, so ".." would climb a path segment.
    if (trimmed.isEmpty || trimmed.length > _maxId || RegExp(r'^\.+$').hasMatch(trimmed)) {
      throw const ApiException(ValidationFailure(message: 'Invalid id.'));
    }
    return ApiId._(trimmed);
  }
}

/// An id that has passed [ApiPath.id].
final class ApiId {
  const ApiId._(this.value);

  final String value;
}
