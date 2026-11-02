import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import 'dto/verified_certificate.dart';

/// `GET /certificates/verify/:credentialId` (`apps/api/src/routes/certificates.ts`) — public and
/// unauthenticated: a credential ID is unique across the platform and finds its academy on its
/// own. Unknown, pending, and academies that switched verification off all answer 404, and the
/// app shows the same "no certificate found" either way.
class VerifyApi {
  VerifyApi(this._client);

  final ApiClient _client;

  Future<VerifiedCertificate> verify(String credentialId) async {
    const endpoint = 'GET /certificates/verify/:credentialId';
    final body = await _client.get(
      ApiPath.of(['certificates', 'verify', ApiPath.id(credentialId)]),
    );
    return parseResponse(
      endpoint,
      body,
      (b) => VerifiedCertificate.fromJson(asJsonObject(endpoint, b)),
    );
  }
}

final verifyApiProvider = Provider<VerifyApi>((ref) => VerifyApi(ref.watch(apiClientProvider)));
