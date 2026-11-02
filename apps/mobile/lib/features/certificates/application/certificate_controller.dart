import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/domain/certificate.dart';
import '../../../shared/domain/rank.dart';
import '../../learner_home/learner_home.dart';
import '../data/certificates_api.dart';

/// The share sheet the certificate screen hands its verification link to.
export '../../../core/platform/share.dart';

/// The models the certificate screens read (§10.4, §26).
export '../../../shared/domain/certificate.dart';
export '../../../shared/domain/rank.dart';

/// The wallet: what the academy has issued, what is waiting to be claimed, and the courses still
/// being worked through. Auto-disposed so claiming is never read from a stale wallet.
final certificateWalletProvider = FutureProvider<CertificateWallet>(
  (ref) => ref.watch(certificatesApiProvider).wallet(),
  isAutoDispose: true,
);

/// One certificate, with everything it is printed from.
final certificateProvider = FutureProvider.family<CertificateDetail, String>(
  (ref, certificateId) => ref.watch(certificatesApiProvider).certificate(certificateId),
  isAutoDispose: true,
);

/// The academy's rank ladder and this learner's standing on it.
final rankLadderProvider = FutureProvider<RankLadder>(
  (ref) => ref.watch(certificatesApiProvider).rankLadder(),
);

/// The public verification link for a credential — the **web** app's page, which is the only thing
/// about a certificate that may be shared (§18).
Uri verificationLink(AppConfig config, String credentialId) =>
    config.webBaseUrl.replace(path: '/verify/$credentialId');

@immutable
class ClaimState {
  const ClaimState({this.claiming, this.claimed, this.failure});

  /// The certificate being claimed, if any.
  final String? claiming;

  /// The certificate the academy has just issued, for the celebration.
  final String? claimed;
  final AppFailure? failure;

  bool get busy => claiming != null;
}

/// Claiming a pending certificate. The academy issues it and answers with the issued certificate;
/// the app sends nothing but the request (§18).
class ClaimController extends Notifier<ClaimState> {
  @override
  ClaimState build() => const ClaimState();

  Future<bool> claim(String certificateId) async {
    if (state.busy) return false;
    state = ClaimState(claiming: certificateId);
    try {
      await ref.read(certificatesApiProvider).claim(certificateId);
      state = ClaimState(claimed: certificateId);
      ref.invalidate(certificateWalletProvider);
      ref.invalidate(certificateProvider(certificateId));
      // A claimed certificate shows on the course page and the home screen too.
      ref.invalidate(learnerHomeProvider);
      ref.invalidate(learnerCoursesProvider);
      return true;
    } on ApiException catch (e) {
      state = ClaimState(failure: e.failure);
      return false;
    }
  }

  void clearFailure() => state = ClaimState(claimed: state.claimed);

  void clearClaimed() => state = const ClaimState();
}

final claimControllerProvider = NotifierProvider<ClaimController, ClaimState>(
  ClaimController.new,
  isAutoDispose: true,
);
