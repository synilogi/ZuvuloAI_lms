import 'package:flutter/material.dart';

import '../../../../core/format/dates_ist.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_certificates_controller.dart';

/// How a credential's standing is drawn.
StatusKind certificateStatusKind(CertificateStatus status) => switch (status) {
  CertificateStatus.issued => StatusKind.issued,
  CertificateStatus.pending => StatusKind.readyToIssue,
  CertificateStatus.revoked => StatusKind.revoked,
  CertificateStatus.unknown => StatusKind.pending,
};

/// One row of the register, drawn as a learner's certificate cards are: a gold strip naming the
/// course and where the credential stands, then who it names and its facts.
class RegisterCard extends StatelessWidget {
  const RegisterCard({required this.row, required this.onOpen, super.key});

  final CertificateRegisterRow row;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final certificate = row.certificate;

    return StripCard(
      onTap: onOpen,
      strip: context.colors.hue(AppNavIcons.of(AppIcons.certificate).hue),
      stripIcon: AppIcons.certificate,
      stripLabel: row.courseTitle,
      badge: StatusBadge(certificateStatusKind(certificate.status)),
      title: row.studentName,
      facts: [
        MetaItem(
          icon: AppIcons.certificate,
          label: l10n.certificateCredentialId(certificate.credentialId),
        ),
        MetaItem(
          icon: AppIcons.date,
          label: certificate.issuedAt == null
              ? l10n.certificateCompletedOn(DatesIst.date(certificate.completedAt))
              : l10n.certificateIssuedOn(DatesIst.date(certificate.issuedAt!)),
        ),
        if (certificate.revokedAt case final revokedAt?)
          MetaItem(
            icon: AppIcons.warning,
            label: l10n.registerRevokedOn(DatesIst.date(revokedAt)),
            color: context.colors.dangerInk,
          ),
        MetaItem(
          icon: AppIcons.eye,
          label: l10n.certificateVerificationCount(certificate.verifications),
        ),
      ],
    );
  }
}
