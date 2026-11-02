import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import '../../../shared/domain/certificate.dart';
import 'dto/certificate_register.dart';

/// `apps/api/src/routes/certificates.ts` — the academy's credential register. An instructor is
/// served only the certificates of courses they teach and may issue one; revoking and restoring are
/// an admin's with `certificates.revoke`. Issuing also needs the `certificates.manage` feature, and
/// the route refuses it in restricted mode — the app reports what it says (§6, §7).
class StaffCertificatesApi {
  StaffCertificatesApi(this._client);

  static const pageSize = 20;

  final ApiClient _client;

  Future<CertificateRegister> register({
    String? search,
    String? courseId,
    String? status,
    int page = 1,
  }) async {
    const endpoint = 'GET /certificates';
    final body = await _client.get(
      '/certificates',
      query: {
        'search': ?search,
        'courseId': ?courseId,
        'status': ?status,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return parseResponse(
      endpoint,
      body,
      (b) => CertificateRegister.fromJson(asJsonObject(endpoint, b)),
    );
  }

  Future<StaffCertificateDetail> certificate(String certificateId) async {
    const endpoint = 'GET /certificates/:id';
    final body = await _client.get(ApiPath.of(['certificates', ApiPath.id(certificateId)]));
    return parseResponse(
      endpoint,
      body,
      (b) => StaffCertificateDetail.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Issues a pending certificate. The academy stamps the date and tells the learner; a certificate
  /// that is not pending is refused with its own words.
  Future<IssuedCertificate> issue(String certificateId) =>
      _write('POST /certificates/:id/issue', certificateId, 'issue');

  /// Revokes an issued certificate. The reason reaches the learner, so the screen asks for it and
  /// checks its length first: below three characters the route answers 400 with no field (finding 31).
  Future<IssuedCertificate> revoke(String certificateId, {required String reason}) =>
      _write('POST /certificates/:id/revoke', certificateId, 'revoke', {'reason': reason.trim()});

  /// Puts a revoked certificate back to issued, reason and date cleared.
  Future<IssuedCertificate> restore(String certificateId) =>
      _write('POST /certificates/:id/restore', certificateId, 'restore');

  Future<IssuedCertificate> _write(
    String endpoint,
    String certificateId,
    String action, [
    Map<String, Object?>? body,
  ]) async {
    final response = await _client.post(
      ApiPath.of(['certificates', ApiPath.id(certificateId), action]),
      body: body,
    );
    return parseResponse(
      endpoint,
      response,
      (b) => IssuedCertificate.fromJson(asJsonObject(endpoint, b)),
    );
  }
}

final staffCertificatesApiProvider = Provider<StaffCertificatesApi>(
  (ref) => StaffCertificatesApi(ref.watch(apiClientProvider)),
);
