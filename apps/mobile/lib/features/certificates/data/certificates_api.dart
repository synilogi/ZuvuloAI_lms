import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import '../../../shared/domain/certificate.dart';
import '../../../shared/domain/rank.dart';

/// `apps/api/src/routes/learning.ts` — the learner's own certificates and the academy's rank
/// ladder. Nothing here names a student: the routes act for whoever is signed in (§7, §18).
class CertificatesApi {
  CertificatesApi(this._client);

  final ApiClient _client;

  Future<CertificateWallet> wallet() async {
    const endpoint = 'GET /learning/certificates';
    final body = await _client.get('/learning/certificates');
    return parseResponse(
      endpoint,
      body,
      (b) => CertificateWallet.fromJson(asJsonObject(endpoint, b)),
    );
  }

  Future<CertificateDetail> certificate(String certificateId) async {
    const endpoint = 'GET /learning/certificates/:id';
    final body = await _client.get(
      ApiPath.of(['learning', 'certificates', ApiPath.id(certificateId)]),
    );
    return parseResponse(
      endpoint,
      body,
      (b) => CertificateDetail.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Claims a certificate the academy has already marked pending for this learner. The academy
  /// issues it — the app sends no status and no date.
  Future<CertificateDetail> claim(String certificateId) async {
    const endpoint = 'POST /learning/certificates/:id/claim';
    final body = await _client.post(
      ApiPath.of(['learning', 'certificates', ApiPath.id(certificateId), 'claim']),
    );
    return parseResponse(
      endpoint,
      body,
      (b) => CertificateDetail.fromJson(asJsonObject(endpoint, b)),
    );
  }

  Future<RankLadder> rankLadder() async {
    const endpoint = 'GET /learning/rank-ladder';
    final body = await _client.get('/learning/rank-ladder');
    return parseResponse(endpoint, body, (b) => RankLadder.fromJson(asJsonObject(endpoint, b)));
  }
}

final certificatesApiProvider = Provider<CertificatesApi>(
  (ref) => CertificatesApi(ref.watch(apiClientProvider)),
);
