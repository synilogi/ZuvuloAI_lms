import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../media/media.dart';
import '../../application/assignment_controller.dart';
import '../widgets/assignment_parts.dart';

/// `/assignments/:assignmentId` — the brief, what the academy attached, how it is marked, the work
/// area for this assignment's own format, and the review once there is one (§26).
class AssignmentDetailScreen extends ConsumerWidget {
  const AssignmentDetailScreen({required this.assignmentId, super.key});

  final String assignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView<LearnerAssignment>(
      value: ref.watch(assignmentProvider(assignmentId)),
      onRetry: () => ref.invalidate(assignmentProvider(assignmentId)),
      skeleton: const DelayedLoading(skeleton: SkeletonDetail()),
      notFound: NotFoundView(onBack: () => goWithin(context, AppRoutes.assignments)),
      data: (row) => _Assignment(assignmentId: assignmentId, row: row),
    );
  }
}

class _Assignment extends ConsumerWidget {
  const _Assignment({required this.assignmentId, required this.row});

  final String assignmentId;
  final LearnerAssignment row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final a = row.assignment;
    final work = ref.watch(assignmentWorkProvider(assignmentId));
    final controller = ref.read(assignmentWorkProvider(assignmentId).notifier);

    // A refusal from the academy is shown once, as the server worded it.
    ref.listen(assignmentWorkProvider(assignmentId), (previous, next) {
      final message = next.refusal ?? next.failure?.message;
      if (message == null || message == (previous?.refusal ?? previous?.failure?.message)) return;
      showAppSnackbar(context, message, tone: SnackTone.error);
      controller.clearRefusal();
    });

    final issues = row.canSubmit ? submissionIssues(a, work.work) : const <SubmissionIssue>[];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s6),
            children: [
              // The assignment's own band — orange, as assignments are across the app.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.colors.hue(Hue.orange).soft,
                      context.colors.hue(Hue.orange).soft.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: Space.s4),
                  child: AssignmentHeader(row: row),
                ),
              ),
              const SizedBox(height: Space.sectionGap),
              AssignmentBrief(instructions: a.instructions),
              if (a.attachments.isNotEmpty) ...[
                const SizedBox(height: Space.sectionGap),
                AssignmentAttachments(
                  attachments: a.attachments,
                  onOpen: (file) => _openFile(context, file),
                ),
              ],
              if (a.rubric.isNotEmpty || a.totalPoints > 0) ...[
                const SizedBox(height: Space.sectionGap),
                AssignmentRubric(assignment: a, review: row.submission?.review),
              ],
              if (row.submission case final submission?) ...[
                const SizedBox(height: Space.sectionGap),
                SubmissionSummary(
                  submission: submission,
                  onOpenFile: (file) => _openFile(context, file),
                ),
                if (submission.review.status != ReviewStatus.waiting || !row.canSubmit) ...[
                  const SizedBox(height: Space.sectionGap),
                  ReviewPanel(review: submission.review, assignment: a),
                ],
              ],
              if (row.canSubmit) ...[
                const SizedBox(height: Space.sectionGap),
                // A resubmission starts from the returned work, so the area is built again when
                // the attempt changes.
                _WorkArea(
                  key: ValueKey('${row.assignment.id}:${row.submission?.attempt ?? 0}'),
                  assignmentId: assignmentId,
                  row: row,
                  work: work,
                  issues: issues,
                ),
              ] else if (!row.canSubmit && row.submission == null) ...[
                const SizedBox(height: Space.sectionGap),
                Text(
                  l10n.assignmentClosedNote,
                  style: context.type.bodyM.copyWith(color: context.colors.muted),
                ),
              ],
            ],
          ),
        ),
        if (row.canSubmit)
          _SubmitBar(assignmentId: assignmentId, row: row, work: work, issues: issues),
      ],
    );
  }

  /// Media is authenticated, so a file opens in the app: a document in the PDF viewer, an image in
  /// a sheet over the page.
  void _openFile(BuildContext context, Attachment file) {
    final id = file.id;
    if (id == null) return;
    if (MediaRules.classify(fileName: file.name, mimeType: file.mime)?.kind == MediaKind.image) {
      showAppBottomSheet<void>(
        context,
        builder: (_) => AppBottomSheet(
          title: file.name,
          child: AuthImage(url: '/media/$id', fit: BoxFit.contain, semanticLabel: file.name),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfViewerScreen(mediaId: id, title: file.name),
      ),
    );
  }
}

/// The work area for this assignment's format, and where the draft stands.
class _WorkArea extends ConsumerWidget {
  const _WorkArea({
    required this.assignmentId,
    required this.row,
    required this.work,
    required this.issues,
    super.key,
  });

  final String assignmentId;
  final LearnerAssignment row;
  final AssignmentWorkState work;
  final List<SubmissionIssue> issues;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final a = row.assignment;
    final controller = ref.read(assignmentWorkProvider(assignmentId).notifier);
    final start = row.startingWork;
    // What is missing is only said once the learner has begun — an untouched assignment is not
    // told off for being empty (§19).
    String? issueFor(String field) => work.work.isEmpty
        ? null
        : issues.where((issue) => issue.field == field).firstOrNull?.message;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (a.format == SubmissionFormat.file)
          AssignmentFilesArea(
            files: work.work.files,
            onAdd: controller.addFile,
            onRemove: controller.removeFile,
            errorText: issueFor('files'),
          )
        else ...[
          if (a.format == SubmissionFormat.chart) ...[
            AssignmentChartForm(
              initial: start.chart,
              onChanged: controller.writeChart,
              errorText: issueFor('chart'),
            ),
            const SizedBox(height: Space.s4),
          ],
          AssignmentTextArea(
            initialText: start.text,
            label: a.format == SubmissionFormat.chart
                ? l10n.assignmentInterpretationLabel
                : l10n.assignmentWorkTitle,
            wordLimit: a.wordLimit,
            errorText: work.work.text.length > AssignmentWork.maxTextLength
                ? l10n.assignmentTextTooLong
                : issueFor('text'),
            onChanged: controller.writeText,
          ),
        ],
        const SizedBox(height: Space.s2),
        DraftStatusLine(state: work),
      ],
    );
  }
}

/// Save and Submit. Submitting says what it does first, and names the late penalty when the
/// academy's own policy will apply it.
class _SubmitBar extends ConsumerWidget {
  const _SubmitBar({
    required this.assignmentId,
    required this.row,
    required this.work,
    required this.issues,
  });

  final String assignmentId;
  final LearnerAssignment row;
  final AssignmentWorkState work;
  final List<SubmissionIssue> issues;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final offline = ref.watch(isOnlineProvider).value == false;
    final controller = ref.read(assignmentWorkProvider(assignmentId).notifier);
    final ready = issues.isEmpty && !work.work.isEmpty;

    return StickyActionBar(
      secondary: AppButton(
        label: l10n.assignmentSaveDraft,
        variant: AppButtonVariant.secondary,
        size: AppButtonSize.lg,
        busy: work.status == DraftStatus.saving,
        onPressed: offline || work.busy ? null : controller.saveDraft,
      ),
      primary: AppButton(
        label: row.isReturned ? l10n.actionResubmitAssignment : l10n.actionSubmitAssignment,
        size: AppButtonSize.lg,
        busy: work.submitting,
        onPressed: offline || work.busy || !ready ? null : () => _submit(context, ref),
      ),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final a = row.assignment;
    final due = row.dueAt;
    final late = due != null && DateTime.now().toUtc().isAfter(due);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title: l10n.assignmentSubmitConfirmTitle,
        message: l10n.assignmentSubmitConfirmBody,
        consequences: [
          if (late && a.acceptsLate)
            a.latePenalty > 0
                ? l10n.assignmentLatePenaltyNote(a.latePenalty)
                : l10n.assignmentLateNoPenalty,
        ],
        confirmLabel: row.isReturned ? l10n.actionResubmitAssignment : l10n.actionSubmitAssignment,
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(assignmentWorkProvider(assignmentId).notifier).submit();
  }
}
