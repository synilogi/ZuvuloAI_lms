import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import 'dto/staff_instructor.dart';

/// `apps/api/src/routes/instructors.ts` — the academy's teaching staff. Reading the directory needs
/// `instructors.view`, which an instructor has too; every write is an admin's with
/// `instructors.manage`, and a status change needs `instructors.status`. The route decides, and the
/// app only stops offering what it knows will be refused (§7).
class StaffInstructorsApi {
  StaffInstructorsApi(this._client);

  /// The sorts the route understands. Anything else falls back to its own name order.
  static const sorts = ['name', 'students', 'rating', 'joined'];

  final ApiClient _client;

  Future<InstructorDirectory> directory({
    String? search,
    String? status,
    String? expertise,
    String? sort,
  }) async {
    const endpoint = 'GET /instructors';
    final body = await _client.get(
      '/instructors',
      query: {'search': ?search, 'status': ?status, 'expertise': ?expertise, 'sort': ?sort},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => InstructorDirectory.fromJson(asJsonObject(endpoint, b)),
    );
  }

  Future<InstructorDetail> instructor(String instructorId) async {
    const endpoint = 'GET /instructors/:id';
    final body = await _client.get(ApiPath.of(['instructors', ApiPath.id(instructorId)]));
    return parseResponse(
      endpoint,
      body,
      (b) => InstructorDetail.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Adds an instructor. The route sends the invitation itself when the status is `invited`, and
  /// counts the seat against the academy's plan — a refusal is `LIMIT_REACHED`, not the app's to
  /// pre-empt (§6).
  Future<AcademyInstructor> create(InstructorForm form) async {
    const endpoint = 'POST /instructors';
    final body = await _client.post('/instructors', body: form.toInput());
    return parseResponse(
      endpoint,
      body,
      (b) => AcademyInstructor.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Saves the **whole** record: `PATCH /instructors/:id` takes a full `InstructorInput`, so a field
  /// left out would read as cleared. It also rewrites the course list from `courseIds`.
  Future<AcademyInstructor> save(String instructorId, InstructorForm form) async {
    const endpoint = 'PATCH /instructors/:id';
    final body = await _client.patch(
      ApiPath.of(['instructors', ApiPath.id(instructorId)]),
      body: form.toInput(),
    );
    return parseResponse(
      endpoint,
      body,
      (b) => AcademyInstructor.fromJson(asJsonObject(endpoint, b)),
    );
  }

  Future<AcademyInstructor> setStatus(String instructorId, InstructorStatus status) async {
    const endpoint = 'POST /instructors/:id/status';
    final body = await _client.post(
      ApiPath.of(['instructors', ApiPath.id(instructorId), 'status']),
      body: {'status': status.name},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => AcademyInstructor.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Sends the invitation again, and answers with the address it went to — which is what the screen
  /// reports, rather than the address it was asked to use.
  Future<String> resendInvite(String instructorId) async {
    const endpoint = 'POST /instructors/:id/resend-invite';
    final body = await _client.post(
      ApiPath.of(['instructors', ApiPath.id(instructorId), 'resend-invite']),
    );
    return parseResponse(
      endpoint,
      body,
      (b) => asText(endpoint, asJsonObject(endpoint, b)['sentTo']),
    );
  }

  /// Instructor self-registrations waiting for this academy's approval (D34). Admin with
  /// `instructors.manage` only; the server scopes them to the signed-in admin's academy.
  Future<List<InstructorRequest>> requests() async {
    const endpoint = 'GET /instructors/requests';
    final body = await _client.get('/instructors/requests');
    return parseResponse(
      endpoint,
      body,
      (b) => [
        for (final row in asJsonList(endpoint, b))
          InstructorRequest.fromJson(asJsonObject(endpoint, row)),
      ],
    );
  }

  /// Approves a request: the instructor becomes active and may sign in. Takes a seat on the plan.
  Future<void> approveRequest(String requestId) async {
    await _client.post(ApiPath.of(['instructors', 'requests', ApiPath.id(requestId), 'approve']));
  }

  /// Rejects a pending request: the account can never sign in unless approved later.
  Future<void> rejectRequest(String requestId) async {
    await _client.post(ApiPath.of(['instructors', 'requests', ApiPath.id(requestId), 'reject']));
  }
}

final staffInstructorsApiProvider = Provider<StaffInstructorsApi>(
  (ref) => StaffInstructorsApi(ref.watch(apiClientProvider)),
);
