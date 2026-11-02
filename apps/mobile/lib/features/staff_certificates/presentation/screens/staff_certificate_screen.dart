import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/auth/capabilities.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../certificates/certificates.dart';
import '../../application/staff_certificates_controller.dart';
import '../widgets/register_parts.dart';

/// `/staff/certificates/:certificateId` — one credential, drawn on the same canvas the learner sees,
/// with the academy's actions beside it. Issuing tells the learner and opens public verification;
/// revoking tells them too, and the reason given is what they read (§22.5). A shell body.
class StaffCertificateScreen extends ConsumerWidget {
  const StaffCertificateScreen({required this.certificateId, super.key});

  final String certificateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    // Only a refusal is reported from here; each action says for itself what the academy did, since
    // the state alone cannot tell issuing from revoking.
    ref.listen(certificateActionProvider, (previous, next) {
      final failure = next.failure;
      if (failure == null || failure == previous?.failure) return;
      final kind = refusalKindOf(failure);
      showAppSnackbar(
        context,
        kind == null
            ? failure.message ?? l10n.stateErrorBody
            : refusalMessage(l10n, kind, serverMessage: failure.message),
        tone: SnackTone.error,
      );
      ref.read(certificateActionProvider.notifier).clearAnswer();
    });

    return RefreshIndicator(
      onRefresh: () => ref.refresh(staffCertificateProvider(certificateId).future),
      child: AsyncView<StaffCertificateDetail>(
        value: ref.watch(staffCertificateProvider(certificateId)),
        onRetry: () => ref.invalidate(staffCertificateProvider(certificateId)),
        data: (detail) => _Certificate(certificateId: certificateId, detail: detail),
      ),
    );
  }
}

class _Certificate extends ConsumerWidget {
  const _Certificate({required this.certificateId, required this.detail});

  final String certificateId;
  final StaffCertificateDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final gutter = WindowSize.of(context).isCompact ? Space.s4 : Space.gutterMedium;
    final certificate = detail.certificate;
    final template = detail.template;
    final printed = detail.asPrinted;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
      children: [
        DetailHeader(
          icon: AppIcons.certificate,
          tone: Tone.warn,
          eyebrow: '${detail.student.name} · ${detail.courseTitle}',
          badge: StatusBadge(certificateStatusKind(certificate.status)),
          title: certificate.title,
        ),
        const SizedBox(height: Space.s3),
        if (template == null)
          AppCard(child: Text(l10n.certificateCanvasUnavailable, style: context.type.bodyM))
        else
          CertificateCanvas(
            data: canvasDataOf(context, printed, template),
            semanticLabel: l10n.certificateCanvasLabel(
              template.heading,
              detail.courseTitle,
              detail.student.name,
              certificate.credentialId,
            ),
          ),
        if (certificate.isPending) ...[
          const SizedBox(height: Space.s3),
          Text(l10n.registerPendingNote, style: context.type.caption.copyWith(color: c.muted)),
        ],
        if (certificate.revokedReason case final reason? when reason.isNotEmpty) ...[
          const SizedBox(height: Space.sectionGap),
          SectionHeader(
            title: l10n.registerRevokedReasonTitle,
            icon: AppIcons.warning,
            iconColor: c.danger,
          ),
          AppCard(child: Text(reason, style: context.type.bodyM)),
        ],
        const SizedBox(height: Space.sectionGap),
        SectionHeader(
          title: l10n.registerLearnerTitle,
          icon: AppIcons.profile,
          iconColor: c.hue(AppNavIcons.of(AppIcons.profile).hue).solid,
        ),
        _Facts(
          rows: [
            (l10n.registerLearnerNameLabel, detail.student.name),
            (l10n.registerLearnerEmailLabel, detail.student.email),
            if (detail.student.city.isNotEmpty)
              (l10n.registerLearnerCityLabel, detail.student.city),
          ],
        ),
        const SizedBox(height: Space.sectionGap),
        SectionHeader(
          title: l10n.certificateDetailsTitle,
          icon: AppIcons.certificate,
          iconColor: c.hue(AppNavIcons.of(AppIcons.certificate).hue).solid,
        ),
        _Facts(
          rows: [
            (l10n.registerCredentialLabel, certificate.credentialId),
            (l10n.registerCompletedLabel, DatesIst.date(certificate.completedAt)),
            if (certificate.issuedAt case final issuedAt?)
              (l10n.registerIssuedLabel, DatesIst.date(issuedAt)),
            if (certificate.revokedAt case final revokedAt?)
              (l10n.registerRevokedLabel, DatesIst.date(revokedAt)),
          ],
        ),
        const SizedBox(height: Space.sectionGap),
        SectionHeader(
          title: l10n.registerVerifyTitle,
          icon: AppIcons.eye,
          iconColor: c.hue(Hue.blue).solid,
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // The path is the academy's own; the app never builds a verification link of its
                // own (§13).
                l10n.registerVerifyPath(detail.verifyUrl),
                style: context.type.bodyS,
              ),
              const SizedBox(height: Space.s2),
              MetaItem(
                icon: AppIcons.eye,
                label: l10n.certificateVerificationCount(certificate.verifications),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.sectionGap),
        _Actions(certificateId: certificateId, detail: detail),
      ],
    );
  }
}

/// Issue, revoke, restore — each offered only where the academy allows it, and each asking first.
class _Actions extends ConsumerWidget {
  const _Actions({required this.certificateId, required this.detail});

  final String certificateId;
  final StaffCertificateDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final certificate = detail.certificate;
    final mayIssue = watchCan(ref, Capability.issueCertificates);
    final mayRevoke = watchCan(ref, Capability.revokeCertificates);
    final action = ref.watch(certificateActionProvider);
    final controller = ref.read(certificateActionProvider.notifier);

    Future<void> issue() async {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.registerIssueTitle,
        message: l10n.registerIssueBody,
        confirmLabel: l10n.registerIssueAction,
      );
      if (!confirmed) return;
      if (await controller.issue(certificateId) && context.mounted) {
        showAppSnackbar(context, l10n.registerIssued, tone: SnackTone.success);
      }
    }

    Future<void> revoke() async {
      final reason = await showRevokeSheet(context);
      if (reason == null || !context.mounted) return;
      if (await controller.revoke(certificateId, reason: reason) && context.mounted) {
        showAppSnackbar(context, l10n.registerRevoked, tone: SnackTone.success);
      }
    }

    Future<void> restore() async {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.registerRestoreTitle,
        message: l10n.registerRestoreBody,
        confirmLabel: l10n.registerRestoreAction,
      );
      if (!confirmed) return;
      if (await controller.restore(certificateId) && context.mounted) {
        showAppSnackbar(context, l10n.registerRestored, tone: SnackTone.success);
      }
    }

    // One action to a line, full width: the one this credential's state calls for first.
    final buttons = [
      if (mayIssue && certificate.isPending)
        AppButton(
          label: l10n.registerIssueAction,
          busy: action.busy,
          expand: true,
          onPressed: issue,
        ),
      if (mayRevoke && certificate.status == CertificateStatus.issued)
        AppButton(
          label: l10n.registerRevokeAction,
          variant: AppButtonVariant.destructiveOutline,
          busy: action.busy,
          expand: true,
          onPressed: revoke,
        ),
      if (mayRevoke && certificate.isRevoked)
        AppButton(
          label: l10n.registerRestoreAction,
          variant: AppButtonVariant.secondary,
          busy: action.busy,
          expand: true,
          onPressed: restore,
        ),
      AppButton(
        label: l10n.registerOpenLearner,
        variant: AppButtonVariant.tertiary,
        expand: true,
        onPressed: () => GoRouter.of(context).go(AppRoutes.staffStudent(detail.student.id)),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(height: Space.s2),
          buttons[i],
        ],
      ],
    );
  }
}

/// Label/value facts on one plain card.
class _Facts extends StatelessWidget {
  const _Facts({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: Space.cardPadding, vertical: Space.s1),
    child: KeyValueTable(rows: rows),
  );
}

/// Asks for the reason the learner will read. Below three characters the route answers 400 with no
/// field at all (finding 31), so the sheet will not let one through.
Future<String?> showRevokeSheet(BuildContext context) =>
    showAppBottomSheet<String>(context, builder: (_) => const _RevokeSheet());

class _RevokeSheet extends StatefulWidget {
  const _RevokeSheet();

  @override
  State<_RevokeSheet> createState() => _RevokeSheetState();
}

class _RevokeSheetState extends State<_RevokeSheet> {
  String _reason = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.registerRevokeTitle, style: context.type.titleM),
          const SizedBox(height: Space.s2),
          Text(l10n.registerRevokeBody, style: context.type.bodyM),
          const SizedBox(height: Space.s4),
          AppTextField(
            label: l10n.registerRevokeReasonLabel,
            required: true,
            minLines: 3,
            maxLines: 6,
            maxLength: maxRevokeReason,
            helperText: l10n.registerRevokeReasonHelp,
            onChanged: (text) => setState(() => _reason = text),
          ),
          const SizedBox(height: Space.s4),
          AppButton(
            label: l10n.registerRevokeAction,
            variant: AppButtonVariant.destructive,
            onPressed: revokeReasonIsEnough(_reason)
                ? () => Navigator.of(context).pop(_reason.trim())
                : null,
          ),
        ],
      ),
    );
  }
}
