import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/features/certificates/certificates.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/public_harness.dart';
import '../helpers/test_config.dart';

void main() {
  late FakeAdapter adapter;
  late CertificatesApi api;

  setUp(() {
    adapter = FakeAdapter();
    api = CertificatesApi(
      ApiClient(
        config: testConfig(),
        tokenStore: FakeTokenStore('jwt'),
        logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
        adapter: adapter,
        logRequests: false,
      ),
    );
  });

  test('the wallet is read for whoever is signed in — no student is ever named', () async {
    adapter.enqueueJson(fixture('learning/certificates.json'));

    final wallet = await api.wallet();

    expect(adapter.lastRequest.method, 'GET');
    expect(adapter.lastRequest.path, '/learning/certificates');
    expect(adapter.lastRequest.queryParameters, isEmpty);
    expect(wallet.issued, hasLength(1));
    expect(wallet.working, hasLength(2));
  });

  test('one certificate is read by its id, escaped into the path', () async {
    adapter.enqueueJson(fixture('learning/certificate-issued.json'));

    await api.certificate('cert/1 2');

    expect(adapter.lastRequest.path, '/learning/certificates/cert%2F1%202');
  });

  test('claiming sends nothing at all — the academy issues it', () async {
    adapter.enqueueJson(fixture('learning/certificate-issued.json'));

    final issued = await api.claim('c1');

    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.path, '/learning/certificates/c1/claim');
    expect(adapter.lastRequest.data, isNull, reason: 'no status and no date are sent');
    expect(issued.certificate.status, CertificateStatus.issued);
  });

  test('the rank ladder is read whole', () async {
    adapter.enqueueJson(fixture('learning/rank-ladder.json'));

    final ladder = await api.rankLadder();

    expect(adapter.lastRequest.path, '/learning/rank-ladder');
    expect(ladder.ranks, hasLength(3));
    expect(ladder.standing.rankId, isNotEmpty);
  });
}
