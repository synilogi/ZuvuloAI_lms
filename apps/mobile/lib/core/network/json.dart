import 'package:json_annotation/json_annotation.dart';

import '../errors/app_failure.dart';
import 'api_exception.dart';

/// ISO-8601 strings ↔ UTC `DateTime` for `json_serializable` models (§10.4).
class UtcDateTimeConverter implements JsonConverter<DateTime, String> {
  const UtcDateTimeConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json).toUtc();

  @override
  String toJson(DateTime object) => object.toUtc().toIso8601String();
}

class NullableUtcDateTimeConverter implements JsonConverter<DateTime?, String?> {
  const NullableUtcDateTimeConverter();

  @override
  DateTime? fromJson(String? json) => json == null ? null : DateTime.parse(json).toUtc();

  @override
  String? toJson(DateTime? object) => object?.toUtc().toIso8601String();
}

/// Some responses carry a **placeholder** record rather than nothing: `GET /learning/courses/:id`
/// answers with an empty enrolment (`id: ""`, `enrolledAt: ""`) for a learner who is not enrolled
/// (`routes/learning.ts`). An empty string is read as "no date" instead of crashing the screen.
class EmptyAsNullUtcDateTimeConverter implements JsonConverter<DateTime?, String?> {
  const EmptyAsNullUtcDateTimeConverter();

  @override
  DateTime? fromJson(String? json) =>
      json == null || json.isEmpty ? null : DateTime.parse(json).toUtc();

  @override
  String? toJson(DateTime? object) => object?.toUtc().toIso8601String();
}

/// The enum value named [raw], or [unknown] — a new server value never crashes the app.
T enumOrUnknown<T extends Enum>(Iterable<T> values, Object? raw, T unknown) {
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return unknown;
}

/// Parses a response with [parse]; a shape the model does not expect becomes a
/// [ContractFailure] naming the endpoint and what failed — never the body.
T parseResponse<T>(String endpoint, Object? body, T Function(Object? body) parse) {
  try {
    return parse(body);
  } on CheckedFromJsonException catch (e) {
    throw ApiException(
      ContractFailure(endpoint: endpoint, detail: '${e.className}.${e.key}: ${e.message}'),
    );
  } on BadKeyException catch (e) {
    // A key the model marks `required` is missing (or one it disallows is present).
    throw ApiException(ContractFailure(endpoint: endpoint, detail: 'keys: ${e.message}'));
  } on TypeError catch (e) {
    throw ApiException(ContractFailure(endpoint: endpoint, detail: 'type: $e'));
  } on FormatException catch (e) {
    throw ApiException(ContractFailure(endpoint: endpoint, detail: 'format: ${e.message}'));
  }
}

/// A JSON object, or a [ContractFailure].
Map<String, dynamic> asJsonObject(String endpoint, Object? body) {
  if (body is Map<String, dynamic>) return body;
  throw ApiException(
    ContractFailure(endpoint: endpoint, detail: 'expected an object, got ${body.runtimeType}'),
  );
}

/// A bare number, as `/notifications/read-all` and `/notifications/clear` answer with — the count
/// of what they changed, sent as JSON with no object around it.
int asCount(String endpoint, Object? body) {
  if (body is int) return body;
  if (body is num) return body.round();
  throw ApiException(
    ContractFailure(endpoint: endpoint, detail: 'expected a number, got ${body.runtimeType}'),
  );
}

/// A string field the route answers with, such as the address `/instructors/:id/resend-invite` says
/// it sent the invitation to. Reported as the academy sent it, never as the app asked for it.
String asText(String endpoint, Object? body) {
  if (body is String && body.isNotEmpty) return body;
  throw ApiException(
    ContractFailure(endpoint: endpoint, detail: 'expected a string, got ${body.runtimeType}'),
  );
}

/// A JSON array, or a [ContractFailure].
List<dynamic> asJsonList(String endpoint, Object? body) {
  if (body is List<dynamic>) return body;
  throw ApiException(
    ContractFailure(endpoint: endpoint, detail: 'expected an array, got ${body.runtimeType}'),
  );
}
