import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/certificate_controller.dart';
import '../widgets/certificate_parts.dart';

/// `/certificates/:certificateId` — the certificate on the canvas, everything it is printed from,
/// and what can be done with it: claim it while it is pending, share the academy's public
/// verification link, or open that page (§26).
class CertificateDetailScreen extends ConsumerWidget {
  const CertificateDetailScreen({required this.certificateId, super.key});

  final String certificateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView<CertificateDetail>(
      value: ref.watch(certificateProvider(certificateId)),
      onRetry: () => ref.invalidate(certificateProvider(certificateId)),
      skeleton: const DelayedLoading(skeleton: SkeletonDetail()),
      notFound: NotFoundView(onBack: () => goWithin(context, AppRoutes.certificates)),
      data: (detail) => _Certificate(certificateId: certificateId, detail: detail),
    );
  }
}

class _Certificate extends ConsumerWidget {
  const _Certificate({required this.certificateId, required this.detail});

  final String certificateId;
  final CertificateDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final certificate = detail.certificate;
    final claim = ref.watch(claimControllerProvider);
    final offline = ref.watch(isOnlineProvider).value == false;

    ref.listen(claimControllerProvider, (previous, next) {
      final failure = next.failure;
      if (failure != null && failure != previous?.failure) {
        showAppSnackbar(context, failure.message ?? l10n.stateErrorBody, tone: SnackTone.error);
        ref.read(claimControllerProvider.notifier).clearFailure();
        return;
      }
      if (next.claimed == certificateId && previous?.claimed != certificateId) {
        // The academy has issued it: a short celebration, and the page is already showing the
        // issued certificate because the provider was invalidated.
        _celebrate();
        showAppSnackbar(context, l10n.certificateClaimedTitle);
        ref.read(claimControllerProvider.notifier).clearClaimed();
      }
    });

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.s4, Space.s4, Space.s4, Space.s6),
            children: [
              DetailHeader(
                icon: AppIcons.certificate,
                tone: certificate.isRevoked ? Tone.danger : Tone.warn,
                eyebrow: detail.courseTitle,
                badge: StatusBadge(certificateStatusBadge(certificate.status)),
                title: certificate.title,
                footer: [
                  if (certificate.isRevoked)
                    Text(
                      l10n.certificateRevokedTitle,
                      style: context.type.bodyM.copyWith(color: c.dangerInk),
                    )
                  else if (certificate.isPending)
                    Text(
                      l10n.certificatePendingNote,
                      style: context.type.bodyM.copyWith(color: c.muted),
                    ),
                ],
              ),
              const SizedBox(height: Space.s4),
              if (detail.template case final template?)
                CertificateCanvas(
                  data: canvasDataOf(context, detail, template),
                  semanticLabel: l10n.certificateCanvasLabel(
                    template.heading,
                    detail.courseTitle,
                    detail.student.name,
                    certificate.credentialId,
                  ),
                )
              else
                Text(
                  l10n.certificateCanvasUnavailable,
                  style: context.type.bodyS.copyWith(color: c.muted),
                ),
              const SizedBox(height: Space.sectionGap),
              SectionHeader(title: l10n.certificateDetailsTitle),
              CertificateFacts(detail: detail),
              if (certificate.credentialId.isNotEmpty) ...[
                const SizedBox(height: Space.s2),
                Text(
                  l10n.certificateVerificationCount(certificate.verifications),
                  style: context.type.caption.copyWith(color: c.muted),
                ),
              ],
            ],
          ),
        ),
        if (certificate.isPending)
          StickyActionBar(
            primary: AppButton(
              label: l10n.certificateClaimAction,
              size: AppButtonSize.lg,
              busy: claim.claiming == certificateId,
              onPressed: offline || claim.busy
                  ? null
                  : () => ref.read(claimControllerProvider.notifier).claim(certificateId),
            ),
          )
        else if (certificate.credentialId.isNotEmpty && !certificate.isRevoked)
          StickyActionBar(
            secondary: AppButton(
              label: l10n.certificateOpenVerification,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.lg,
              onPressed: () =>
                  GoRouter.of(context).go(AppRoutes.verifyCredential(certificate.credentialId)),
            ),
            primary: AppButton(
              label: l10n.certificateShareAction,
              icon: AppIcons.share,
              size: AppButtonSize.lg,
              onPressed: () => _share(context, ref),
            ),
          ),
      ],
    );
  }

  /// Shares the public verification link and nothing else — not the learner's e-mail, which is not
  /// even modelled, and no id but the credential's (§18).
  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final link = verificationLink(
      ref.read(appConfigProvider),
      detail.certificate.credentialId,
    ).toString();
    await ref.read(shareTextProvider)(
      text: link,
      subject: l10n.certificateShareSubject(detail.certificate.title),
    );
  }
}

/// The paper's own fields, from the academy's template. The accent is a token family, never a
/// colour from the server (§2).
CertificateCanvasData canvasDataOf(
  BuildContext context,
  CertificateDetail detail,
  CertificateTemplateInfo template,
) {
  final l10n = context.l10n;
  final certificate = detail.certificate;
  final issuedAt = certificate.issuedAt;
  final score = certificate.finalScore;
  return CertificateCanvasData(
    // No learner-reachable endpoint carries the academy's own name (finding 14), and a certificate
    // will not print a name this app invented. The header shows the seal alone until it does.
    academyName: '',
    heading: template.heading,
    statement: template.statement,
    learnerName: detail.student.name,
    courseTitle: detail.courseTitle,
    credentialId: certificate.credentialId,
    accent: CertificateAccent.parse(template.accent),
    details: [
      if (template.showScore && score != null) l10n.verifyScoreValue(score),
      if (template.showHours && certificate.hours > 0) l10n.verifyHoursValue(certificate.hours),
    ],
    issuedOnLabel: issuedAt == null ? null : DatesIst.date(issuedAt),
    signatories: [
      for (final signatory in template.signatories)
        CertificateSignatory(name: signatory.name, title: signatory.title),
    ],
  );
}

/// A short tap when the academy issues the certificate (§22.4). Nothing waits on it.
void _celebrate() => unawaited(HapticFeedback.mediumImpact());
