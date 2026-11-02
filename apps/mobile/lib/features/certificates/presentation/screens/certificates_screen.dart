import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/certificate_controller.dart';
import '../widgets/certificate_parts.dart';

/// `/certificates` — the wallet in the academy's own three groups: issued, waiting to be claimed,
/// and the courses still being worked through (§26). A shell body.
class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(certificateWalletProvider.future),
      child: AsyncView<CertificateWallet>(
        value: ref.watch(certificateWalletProvider),
        onRetry: () => ref.invalidate(certificateWalletProvider),
        data: (wallet) => wallet.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 360,
                    child: EmptyState(
                      title: l10n.certificatesEmptyTitle,
                      message: l10n.certificatesEmptyBody,
                    ),
                  ),
                ],
              )
            : _Wallet(wallet: wallet),
      ),
    );
  }
}

class _Wallet extends ConsumerWidget {
  const _Wallet({required this.wallet});

  final CertificateWallet wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final claim = ref.watch(claimControllerProvider);

    ref.listen(claimControllerProvider, (previous, next) {
      final failure = next.failure;
      if (failure == null || failure == previous?.failure) return;
      showAppSnackbar(context, failure.message ?? l10n.stateErrorBody, tone: SnackTone.error);
      ref.read(claimControllerProvider.notifier).clearFailure();
    });

    void open(String certificateId) => goWithin(context, AppRoutes.certificate(certificateId));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s6),
      children: [
        if (wallet.pending.isNotEmpty) ...[
          SectionHeader(
            title: l10n.certificatesTabPending,
            icon: AppIcons.certificate,
            iconColor: context.colors.hue(Hue.gold).solid,
          ),
          for (final detail in wallet.pending) ...[
            CertificateWalletCard(detail: detail, onOpen: () => open(detail.certificate.id)),
            const SizedBox(height: Space.s2),
            AppButton(
              label: l10n.certificateClaimAction,
              busy: claim.claiming == detail.certificate.id,
              onPressed: claim.busy
                  ? null
                  : () => ref.read(claimControllerProvider.notifier).claim(detail.certificate.id),
            ),
            const SizedBox(height: Space.s3),
          ],
          const SizedBox(height: Space.s2),
        ],
        if (wallet.issued.isNotEmpty) ...[
          SectionHeader(
            title: l10n.certificatesTabIssued,
            icon: AppIcons.success,
            iconColor: context.colors.hue(Hue.green).solid,
          ),
          for (final detail in wallet.issued) ...[
            CertificateWalletCard(detail: detail, onOpen: () => open(detail.certificate.id)),
            const SizedBox(height: Space.s3),
          ],
          const SizedBox(height: Space.s2),
        ],
        if (wallet.working.isNotEmpty) ...[
          SectionHeader(
            title: l10n.certificatesTabWorking,
            icon: AppIcons.trendUp,
            iconColor: context.colors.hue(Hue.blue).solid,
          ),
          for (final record in wallet.working) ...[
            WorkingTowardsCard(
              record: record,
              onOpenCourse: record.courseId.isEmpty
                  ? null
                  : () => GoRouter.of(context).go(AppRoutes.learnCourse(record.courseId)),
            ),
            const SizedBox(height: Space.s3),
          ],
        ],
      ],
    );
  }
}
