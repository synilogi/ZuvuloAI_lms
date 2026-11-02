import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/features/certificates/certificates.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

/// A pending certificate, as the route sends one before it is claimed.
Map<String, dynamic> _pending() {
  final raw =
      jsonDecode(jsonEncode(fixture('learning/certificate-issued.json'))) as Map<String, dynamic>;
  (raw['certificate']! as Map<String, dynamic>)
    ..['status'] = 'pending'
    ..remove('issuedAt');
  return raw;
}

void main() {
  late FakeAdapter adapter;
  late ProviderContainer container;

  setUp(() {
    adapter = FakeAdapter();
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: publicScope(
        adapter: adapter,
        signedInAs: learner(),
        child: const SizedBox(),
      ).overrides,
    );
    addTearDown(container.dispose);
    container.listen(claimControllerProvider, (_, _) {});
  });

  test('claiming asks the academy to issue it and reads the result back', () async {
    // Answered by path, because the wallet and the claim are read in whatever order the
    // providers settle in.
    adapter.handler = (options) async => FakeAdapter.jsonResponse(
      options.path.endsWith('/claim') || options.path.contains('/certificates/c1')
          ? fixture('learning/certificate-issued.json')
          : {
              'issued': [fixture('learning/certificate-issued.json')],
            },
    );
    container.listen(certificateWalletProvider, (_, _) {});

    final claimed = await container.read(claimControllerProvider.notifier).claim('c1');

    expect(claimed, isTrue);
    final claim = adapter.requests.firstWhere((r) => r.path.endsWith('/claim'));
    expect(claim.method, 'POST');
    expect(claim.path, '/learning/certificates/c1/claim');
    final state = container.read(claimControllerProvider);
    expect(state.claimed, 'c1');
    expect(state.busy, isFalse);
    // The wallet is read again, because what it holds has changed.
    final wallet = await container.read(certificateWalletProvider.future);
    expect(wallet.issued, hasLength(1));
  });

  test('a certificate the academy will not issue is refused in its own words', () async {
    adapter.enqueueJson({'message': 'Certificate not found.'}, status: 404);

    final claimed = await container.read(claimControllerProvider.notifier).claim('c1');

    expect(claimed, isFalse);
    final state = container.read(claimControllerProvider);
    expect(state.failure, isA<NotFoundFailure>());
    expect(state.failure!.message, 'Certificate not found.');
    expect(state.claimed, isNull);
    container.read(claimControllerProvider.notifier).clearFailure();
    expect(container.read(claimControllerProvider).failure, isNull);
  });

  test('a certificate cannot be claimed twice at once', () async {
    adapter
      ..enqueueJson(fixture('learning/certificate-issued.json'))
      ..enqueueJson(fixture('learning/certificate-issued.json'));

    final notifier = container.read(claimControllerProvider.notifier);
    final first = notifier.claim('c1');
    final second = await notifier.claim('c1');
    await first;

    expect(second, isFalse);
    expect(adapter.requests.where((r) => r.path.endsWith('/claim')), hasLength(1));
  });

  test('the wallet keeps the academy\'s three groups apart', () async {
    adapter.enqueueJson({
      'issued': [fixture('learning/certificate-issued.json')],
      'pending': [_pending()],
      'working': [
        {
          'id': 'working-c',
          'courseId': 'c',
          'title': 'Certificate in Something',
          'criteria': [
            {'id': 'progress', 'label': 'Course progress', 'current': 40, 'required': 100},
          ],
        },
      ],
    });

    final wallet = await container.read(certificateWalletProvider.future);

    expect(wallet.issued.single.certificate.status, CertificateStatus.issued);
    expect(wallet.pending.single.certificate.isPending, isTrue);
    expect(wallet.working.single.criteria.single.fraction, closeTo(0.4, 0.001));
    expect(wallet.isEmpty, isFalse);
  });
}
