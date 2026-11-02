import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/auth/capabilities.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/figures.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../assignments/assignments.dart';
import '../../../media/media.dart';
import '../../application/staff_review_controller.dart';
import '../widgets/review_parts.dart';

/// `/staff/submissions/:submissionId` — one hand-in, read and marked. The score the learner ends up
/// with is the **academy's**: it applies their late policy and answers with what it stored, and this
/// screen shows an estimate until then (§18).
class SubmissionReviewScreen extends ConsumerWidget {
  const SubmissionReviewScreen({required this.submissionId, super.key, this.onOpenOther});

  final String submissionId;

  /// In the two-pane layout the queue keeps the selection, so moving to the next hand-in changes
  /// the pane rather than the route.
  final void Function(String submissionId)? onOpenOther;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView<SubmissionDetail>(
      value: ref.watch(submissionProvider(submissionId)),
      onRetry: () => ref.invalidate(submissionProvider(submissionId)),
      skeleton: const DelayedLoading(skeleton: SkeletonDetail()),
      notFound: NotFoundView(onBack: () => GoRouter.of(context).go(AppRoutes.staffReview)),
      data: (detail) =>
          _Review(submissionId: submissionId, detail: detail, onOpenOther: onOpenOther),
    );
  }
}

class _Review extends ConsumerStatefulWidget {
  const _Review({required this.submissionId, required this.detail, this.onOpenOther});

  final String submissionId;
  final SubmissionDetail detail;
  final void Function(String submissionId)? onOpenOther;

  @override
  ConsumerState<_Review> createState() => _ReviewState();
}

class _ReviewState extends ConsumerState<_Review> {
  bool _briefOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final detail = widget.detail;
    final assignment = detail.assignment;
    final draft = ref.watch(reviewProvider(widget.submissionId));
    final controller = ref.read(reviewProvider(widget.submissionId).notifier);
    final mayGrade = watchCan(ref, Capability.gradeSubmissions);
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;

    // Whatever the academy said about this review is shown once, in its own words.
    ref.listen(reviewProvider(widget.submissionId), (previous, next) {
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
      controller.clearAnswer();
    });

    void open(String id) {
      final inPane = widget.onOpenOther;
      if (inPane != null) {
        inPane(id);
      } else {
        GoRouter.of(context).go(AppRoutes.staffSubmission(id));
      }
    }

    Future<void> decide(Future<bool> Function() action, String doneMessage) async {
      final ok = await action();
      if (!ok || !context.mounted) return;
      showAppSnackbar(context, doneMessage, tone: SnackTone.success);
      // Grading or returning takes this hand-in out of the queue, so the next one is offered.
      final next = detail.queue.nextId;
      if (next != null) open(next);
    }

    final estimate = controller.estimate(detail);

    return PopScope(
      canPop: !draft.dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !context.mounted) return;
        final leave = await showConfirmDialog(
          context,
          title: l10n.reviewLeaveConfirmTitle,
          message: l10n.reviewLeaveConfirmBody,
          confirmLabel: l10n.reviewLeaveConfirmAction,
          destructive: true,
        );
        if (leave && context.mounted) leavePage(context);
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(gutter, Space.s3, gutter, Space.s6),
        children: [
          // What this is, and who handed it in.
          _ReviewHead(detail: detail),
          const SizedBox(height: Space.s3),
          // The brief is long and the reviewer has usually read it; it opens when wanted.
          if (assignment.instructions.trim().isNotEmpty)
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppListTile(
                    title: l10n.reviewBriefTitle,
                    leading: AppIcon(AppIcons.file, color: c.hue(Hue.blue).solid),
                    trailing: AppIcon(
                      _briefOpen ? AppIcons.chevronUp : AppIcons.chevronDown,
                      size: IconSizes.sm,
                      color: c.muted,
                    ),
                    onTap: () => setState(() => _briefOpen = !_briefOpen),
                  ),
                  if (_briefOpen)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s4),
                      child: AssignmentBrief(instructions: assignment.instructions),
                    ),
                ],
              ),
            ),
          if (assignment.attachments.isNotEmpty) ...[
            const SizedBox(height: Space.s3),
            AssignmentAttachments(
              attachments: assignment.attachments,
              onOpen: (attachment) => _openFile(context, attachment),
            ),
          ],
          const SizedBox(height: Space.s4),
          SubmissionSummary(
            submission: detail.submission,
            title: l10n.reviewLearnerWorkTitle,
            onOpenFile: (file) => _openFile(context, file),
          ),
          const SizedBox(height: Space.sectionGap),
          SectionHeader(
            title: l10n.reviewScoreTitle,
            icon: AppIcons.rating,
            iconColor: c.hue(Hue.gold).solid,
          ),
          if (assignment.rubric.isNotEmpty)
            RubricScorer(
              criteria: [
                for (final criterion in assignment.rubric)
                  ScoringCriterion(
                    id: criterion.id,
                    title: criterion.title,
                    maxPoints: criterion.points,
                    description: criterion.description.isEmpty ? null : criterion.description,
                  ),
              ],
              scores: draft.scores,
              onChanged: mayGrade ? controller.score : null,
            )
          else
            AppTextField(
              label: l10n.reviewPointsLabel(formatFigure(assignment.totalPoints)),
              initialValue: draft.points == null ? null : formatFigure(draft.points!),
              keyboardType: TextInputType.number,
              enabled: mayGrade,
              errorText: draft.messageFor('points'),
              onChanged: (text) => controller.scorePoints(num.tryParse(text.trim())),
            ),
          // Each criterion the academy refused says so under the scorer, in its own words.
          for (final criterion in assignment.rubric)
            if (draft.messageFor('scores', criterionId: criterion.id) case final message?)
              Padding(
                padding: const EdgeInsets.only(top: Space.s2),
                child: Text(message, style: context.type.caption.copyWith(color: c.dangerInk)),
              ),
          const SizedBox(height: Space.s3),
          // What it would come to. The academy's late policy is not in the app, so this is an
          // estimate and says so.
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reviewGradeEstimate(
                    formatFigure(estimate.score),
                    formatFigure(estimate.max),
                  ),
                  style: context.type.bodyM,
                ),
                const SizedBox(height: Space.s1),
                Text(
                  estimate.score >= assignment.passMark
                      ? l10n.reviewGradeEstimatePass(formatFigure(assignment.passMark))
                      : l10n.reviewGradeEstimateFail(formatFigure(assignment.passMark)),
                  style: context.type.caption.copyWith(color: c.muted),
                ),
                if (detail.submission.late && assignment.latePenalty > 0) ...[
                  const SizedBox(height: Space.s2),
                  Text(
                    l10n.reviewLatePenaltyNote(formatFigure(assignment.latePenalty)),
                    style: context.type.caption.copyWith(color: c.warnInk),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Space.sectionGap),
          SectionHeader(
            title: l10n.reviewFeedbackTitle,
            icon: AppIcons.email,
            iconColor: c.hue(Hue.green).solid,
          ),
          AppTextField(
            label: l10n.reviewFeedbackTitle,
            hintText: l10n.reviewFeedbackHint,
            initialValue: draft.feedback,
            minLines: 4,
            maxLines: 10,
            maxLength: 10000,
            enabled: mayGrade,
            errorText: draft.messageFor('feedback'),
            onChanged: controller.writeFeedback,
          ),
          const SizedBox(height: Space.sectionGap),
          SectionHeader(
            title: l10n.reviewPrivateNoteTitle,
            icon: AppIcons.lock,
            iconColor: c.hue(Hue.violet).solid,
          ),
          AppTextField(
            label: l10n.reviewPrivateNoteTitle,
            hintText: l10n.reviewPrivateNoteHint,
            helperText: l10n.reviewPrivateNoteOnlyStaff,
            initialValue: draft.privateNote,
            minLines: 2,
            maxLines: 6,
            maxLength: 5000,
            enabled: mayGrade,
            onChanged: controller.writePrivateNote,
          ),
          if (mayGrade) ...[
            const SizedBox(height: Space.s5),
            // The decision first and full width; the softer outcomes side by side beneath it.
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: l10n.reviewActionGrade,
                  busy: draft.busy,
                  onPressed: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: l10n.reviewGradeConfirmTitle,
                      message: l10n.reviewGradeConfirmBody,
                      confirmLabel: l10n.reviewActionGrade,
                      consequences: [
                        l10n.reviewGradeEstimate(
                          formatFigure(estimate.score),
                          formatFigure(estimate.max),
                        ),
                      ],
                    );
                    if (!confirmed || !context.mounted) return;
                    await decide(controller.grade, l10n.reviewGradedMessage);
                  },
                  expand: true,
                ),
                const SizedBox(height: Space.s2),
                ActionPair(
                  primary: AppButton(
                    label: l10n.reviewActionReturn,
                    variant: AppButtonVariant.secondary,
                    busy: draft.busy,
                    onPressed: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: l10n.reviewReturnConfirmTitle,
                        message: l10n.reviewReturnConfirmBody,
                        confirmLabel: l10n.reviewActionReturn,
                      );
                      if (!confirmed || !context.mounted) return;
                      await decide(controller.returnForChanges, l10n.reviewReturnedMessage);
                    },
                    expand: true,
                  ),
                  secondary: AppButton(
                    label: l10n.reviewActionSaveDraft,
                    variant: AppButtonVariant.tertiary,
                    busy: draft.busy,
                    onPressed: () => decide(controller.saveDraft, l10n.reviewDraftSaved),
                    expand: true,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Space.s5),
          const AppDivider(),
          const SizedBox(height: Space.s2),
          ReviewQueueNav(
            queue: detail.queue,
            onPrevious: detail.queue.previousId == null
                ? null
                : () => open(detail.queue.previousId!),
            onNext: detail.queue.nextId == null ? null : () => open(detail.queue.nextId!),
          ),
          const SizedBox(height: Space.s2),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: l10n.reviewOpenAssignment,
              icon: AppIcons.assignment,
              variant: AppButtonVariant.tertiary,
              onPressed: () => GoRouter.of(context).go(AppRoutes.staffSubmissions(assignment.id)),
            ),
          ),
        ],
      ),
    );
  }

  /// A file is streamed from the media route behind the bearer header — never a bare URL (§13).
  void _openFile(BuildContext context, Attachment file) {
    final id = file.id;
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfViewerScreen(mediaId: id, title: file.name),
      ),
    );
  }
}

/// The head of a review: the assignment and where it sits in the course, then the learner who
/// handed it in and how far through the course the academy says they are — on one card.
class _ReviewHead extends StatelessWidget {
  const _ReviewHead({required this.detail});

  final SubmissionDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final student = detail.student;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HueTile(icon: AppIcons.assignment, hue: AppNavIcons.of(AppIcons.assignment).hue),
              const SizedBox(width: Space.s3),
              Expanded(
                child: Text(
                  [detail.courseTitle, ?detail.chapterTitle].join(' · '),
                  style: context.type.caption.copyWith(color: c.muted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s3),
          Semantics(header: true, child: Text(detail.assignment.title, style: context.type.titleL)),
          const SizedBox(height: Space.s3),
          const AppDivider(),
          const SizedBox(height: Space.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarInitials(name: student.name, size: AvatarSizes.md),
              const SizedBox(width: Space.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name, style: context.type.titleS),
                    const SizedBox(height: Space.s1),
                    Text(student.email, style: context.type.bodyS.copyWith(color: c.muted)),
                    const SizedBox(height: Space.s2),
                    MetaItem(
                      icon: AppIcons.chart,
                      label: l10n.reviewLearnerProgress(formatFigure(student.progress)),
                    ),
                    if (student.enrolledAt case final at?) ...[
                      const SizedBox(height: Space.s1),
                      MetaItem(
                        icon: AppIcons.date,
                        label: l10n.reviewEnrolledOn(DatesIst.date(at)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
