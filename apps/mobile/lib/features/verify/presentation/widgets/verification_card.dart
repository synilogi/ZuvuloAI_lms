import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/verify_providers.dart';

/// What the academy says about a credential: valid, withdrawn, or past its validity — always the
/// server's verdict, never a date this app compares (§18). The learner's email is not shown
/// because it is not even modelled.
class VerificationCard extends StatelessWidget {
  const VerificationCard({required this.result, super.key});

  final VerifiedCertificate result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final certificate = result.certificate;
    final validUntil = result.validUntil;

    final (StatusKind kind, String title, String? message) = result.isRevoked
        ? (StatusKind.revoked, l10n.verifyRevokedTitle, l10n.verifyRevokedBody)
        : result.expired
        ? (
            StatusKind.expired,
            l10n.verifyExpiredTitle,
            validUntil == null ? null : l10n.verifyExpiredBody(DatesIst.date(validUntil)),
          )
        : (StatusKind.issued, l10n.verifyValidTitle, null);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.s4, Space.s4, Space.s4, Space.s6),
      children: [
        Row(children: [StatusBadge(kind, size: StatusBadgeSize.md)]),
        const SizedBox(height: Space.s3),
        Semantics(header: true, child: Text(title, style: type.titleL)),
        if (message != null) ...[
          const SizedBox(height: Space.s2),
          Text(message, style: type.bodyM.copyWith(color: c.muted)),
        ],
        const SizedBox(height: Space.s5),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.verifyAwardedToLabel, style: type.caption.copyWith(color: c.muted)),
              const SizedBox(height: Space.s1),
              Text(result.student.name, style: type.titleM),
              const SizedBox(height: Space.s4),
              KeyValueTable(
                rows: [
                  if (result.courseTitle.isNotEmpty) (l10n.verifyCourseLabel, result.courseTitle),
                  if (result.levelTitle.isNotEmpty) (l10n.verifyLevelLabel, result.levelTitle),
                  if (result.student.city.isNotEmpty) (l10n.verifyCityLabel, result.student.city),
                  (l10n.verifyCompletedOnLabel, DatesIst.date(certificate.completedAt)),
                  if (certificate.issuedAt != null)
                    (l10n.verifyIssuedOnLabel, DatesIst.date(certificate.issuedAt!)),
                  if (validUntil != null) (l10n.verifyValidUntilLabel, DatesIst.date(validUntil)),
                  if (certificate.finalScore != null)
                    (l10n.verifyScoreLabel, l10n.verifyScoreValue(certificate.finalScore!)),
                  if (certificate.hours > 0)
                    (l10n.verifyHoursLabel, l10n.verifyHoursValue(certificate.hours)),
                  if (certificate.revokedReason != null && certificate.revokedReason!.isNotEmpty)
                    (l10n.verifyRevokedReasonLabel, certificate.revokedReason!),
                ],
              ),
              const SizedBox(height: Space.s4),
              Text(
                l10n.certificateCredentialId(certificate.credentialId.toUpperCase()),
                style: type.caption.copyWith(color: c.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.s5),
        AppButton(
          label: l10n.actionVerifyAnother,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: () => GoRouter.of(context).go(AppRoutes.verify),
        ),
      ],
    );
  }
}
