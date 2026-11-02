import 'package:flutter/material.dart';

import '../../../../core/format/dates_ist.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/certificate_controller.dart';

/// A number as a person reads it: no trailing `.0` on a whole figure.
String certificateNumber(num value) =>
    value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);

/// The badge a certificate carries, from the academy's own status.
StatusKind certificateStatusBadge(CertificateStatus status) => switch (status) {
  CertificateStatus.issued => StatusKind.issued,
  CertificateStatus.pending => StatusKind.readyToIssue,
  CertificateStatus.revoked => StatusKind.revoked,
  CertificateStatus.unknown => StatusKind.issued,
};

/// One certificate in the wallet: the course it is for, its credential id and where it stands.
class CertificateWalletCard extends StatelessWidget {
  const CertificateWalletCard({required this.detail, required this.onOpen, super.key});

  final CertificateDetail detail;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final certificate = detail.certificate;
    final issuedAt = certificate.issuedAt;
    return ItemCard(
      icon: AppIcons.certificate,
      tone: certificate.isRevoked ? Tone.danger : Tone.warn,
      onTap: onOpen,
      eyebrow: detail.courseTitle,
      badge: StatusBadge(certificateStatusBadge(certificate.status)),
      title: certificate.title,
      facts: [
        MetaItem(
          icon: AppIcons.file,
          label: certificate.credentialId.isEmpty
              ? l10n.certificatePendingNote
              : l10n.certificateCredentialId(certificate.credentialId),
        ),
        MetaItem(
          icon: AppIcons.date,
          label: issuedAt == null
              ? l10n.certificateCompletedOn(DatesIst.date(certificate.completedAt))
              : l10n.certificateIssuedOn(DatesIst.date(issuedAt)),
        ),
      ],
    );
  }
}

/// A course whose certificate is still being worked towards, with the academy's own criteria.
class WorkingTowardsCard extends StatelessWidget {
  const WorkingTowardsCard({required this.record, super.key, this.onOpenCourse});

  final CertificateRecord record;
  final VoidCallback? onOpenCourse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return AppCard(
      onTap: onOpenCourse,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HueTile(icon: AppIcons.certificate, hue: Hue.gold),
              const SizedBox(width: Space.s3),
              Expanded(child: Text(record.title, style: context.type.titleS)),
            ],
          ),
          const SizedBox(height: Space.s3),
          CriteriaMeters(criteria: record.criteria),
          if (record.eligible && record.criteria.isNotEmpty) ...[
            const SizedBox(height: Space.s2),
            Text(
              l10n.certificatePendingNote,
              style: context.type.bodyS.copyWith(color: c.accentInk),
            ),
          ],
        ],
      ),
    );
  }
}

/// The academy's criteria, each with the figures it counted.
class CriteriaMeters extends StatelessWidget {
  const CriteriaMeters({required this.criteria, super.key});

  final List<CertificateCriterion> criteria;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final criterion in criteria) ...[
          Row(
            children: [
              AppIcon(
                criterion.met ? AppIcons.check : AppIcons.time,
                size: IconSizes.sm,
                color: criterion.met ? c.hue(Hue.green).solid : c.muted,
              ),
              const SizedBox(width: Space.s2),
              Expanded(child: Text(criterion.label, style: context.type.bodyS)),
              Text(
                l10n.certificateCriterionProgress(
                  certificateNumber(criterion.current),
                  certificateNumber(criterion.needed),
                  criterion.unit ?? '',
                ),
                style: context.type.caption.copyWith(color: c.muted),
              ),
            ],
          ),
          const SizedBox(height: Space.s2),
          ProgressBar(value: criterion.fraction, height: 4),
          const SizedBox(height: Space.s3),
        ],
      ],
    );
  }
}

/// Everything printed on the certificate, as a list — the record behind the paper, and the
/// fallback when the canvas cannot be drawn.
class CertificateFacts extends StatelessWidget {
  const CertificateFacts({required this.detail, super.key});

  final CertificateDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final certificate = detail.certificate;
    final issuedAt = certificate.issuedAt;
    final score = certificate.finalScore;
    return AppCard(
      child: KeyValueTable(
        rows: [
          (l10n.verifyAwardedToLabel, detail.student.name),
          if (detail.courseTitle.isNotEmpty) (l10n.verifyCourseLabel, detail.courseTitle),
          if (detail.levelTitle.isNotEmpty) (l10n.verifyLevelLabel, detail.levelTitle),
          if (detail.student.city.isNotEmpty) (l10n.verifyCityLabel, detail.student.city),
          (l10n.verifyCompletedOnLabel, DatesIst.date(certificate.completedAt)),
          if (issuedAt != null) (l10n.verifyIssuedOnLabel, DatesIst.date(issuedAt)),
          if (certificate.credentialId.isNotEmpty)
            (l10n.verifyFieldLabel, certificate.credentialId),
          if (score != null) (l10n.verifyScoreLabel, l10n.verifyScoreValue(score)),
          if (certificate.hours > 0)
            (l10n.verifyHoursLabel, l10n.verifyHoursValue(certificate.hours)),
          if (certificate.revokedReason case final reason?) (l10n.verifyRevokedReasonLabel, reason),
        ],
      ),
    );
  }
}

/// The academy's ladder: where the learner stands, and what each rank asks for. The route sends no
/// progress figures (finding 13), so a rank's requirements are shown as requirements.
class RankLadderList extends StatelessWidget {
  const RankLadderList({required this.steps, super.key});

  final List<RankStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final step in steps) ...[RankStepCard(step: step), const SizedBox(height: Space.s3)],
      ],
    );
  }
}

/// One rank on the ladder.
class RankStepCard extends StatelessWidget {
  const RankStepCard({required this.step, super.key});

  final RankStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final label = switch (step.state) {
      RankStepState.achieved => l10n.ranksAchievedLabel,
      RankStepState.current => l10n.ranksCurrentLabel,
      RankStepState.next => l10n.ranksNextLabel,
      RankStepState.future => l10n.ranksFutureLabel,
    };
    final achievedAt = step.achievedAt;
    final current = step.state == RankStepState.current;
    return AppCard(
      // The rank the learner holds now, in the gold the app keeps for what is earned.
      color: current ? c.hue(Hue.gold).soft : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.type.caption.copyWith(
                    color: current ? c.hue(Hue.gold).ink : c.muted,
                    fontWeight: current ? FontWeight.w700 : null,
                  ),
                ),
              ),
              if (step.state == RankStepState.achieved)
                AppIcon(AppIcons.check, size: IconSizes.sm, color: c.hue(Hue.green).solid),
              if (current) AppIcon(AppIcons.rank, size: IconSizes.md, color: c.hue(Hue.gold).solid),
            ],
          ),
          const SizedBox(height: Space.s1),
          Text(step.rank.title, style: context.type.titleS),
          if (step.rank.descriptor.isNotEmpty) ...[
            const SizedBox(height: Space.s1),
            Text(step.rank.descriptor, style: context.type.bodyS.copyWith(color: c.muted)),
          ],
          if (achievedAt != null) ...[
            const SizedBox(height: Space.s1),
            Text(
              l10n.certificateIssuedOn(DatesIst.date(achievedAt)),
              style: context.type.caption.copyWith(color: c.muted),
            ),
          ],
          if (step.rank.criteria.isNotEmpty) ...[
            const SizedBox(height: Space.s3),
            Text(l10n.ranksRequirementsTitle, style: context.type.label.copyWith(color: c.muted)),
            const SizedBox(height: Space.s2),
            for (final criterion in step.rank.criteria)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s1),
                child: Text(
                  l10n.ranksRequirement(
                    criterion.label,
                    certificateNumber(criterion.needed),
                    criterion.unit ?? '',
                  ),
                  style: context.type.bodyS,
                ),
              ),
          ] else if (step.state == RankStepState.current) ...[
            const SizedBox(height: Space.s2),
            Text(l10n.ranksNoRequirements, style: context.type.bodyS.copyWith(color: c.muted)),
          ],
        ],
      ),
    );
  }
}
