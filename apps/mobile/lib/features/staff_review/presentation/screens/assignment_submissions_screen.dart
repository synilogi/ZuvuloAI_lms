import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/auth/capabilities.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_review_controller.dart';
import '../widgets/review_parts.dart';

/// `/staff/assignments/:assignmentId/submissions` — one assignment's hand-ins, and the learners who
/// still owe it. Who is missing is the academy's answer, not a list the app works out (§18).
class AssignmentSubmissionsScreen extends ConsumerWidget {
  const AssignmentSubmissionsScreen({required this.assignmentId, super.key});

  final String assignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;
    final filter = ref.watch(submissionFilterProvider);
    final controller = ref.read(submissionFilterProvider.notifier);
    final remind = ref.watch(remindProvider);

    // What the academy said about the reminders, once, in its own terms.
    ref.listen(remindProvider, (previous, next) {
      if (next.sent case final sent? when sent != previous?.sent) {
        showAppSnackbar(context, l10n.reviewRemindSent(sent), tone: SnackTone.success);
        ref.read(remindProvider.notifier).clearAnswer();
        return;
      }
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
      ref.read(remindProvider.notifier).clearAnswer();
    });

    return RefreshIndicator(
      onRefresh: () => ref.refresh(assignmentSubmissionsProvider(assignmentId).future),
      child: AsyncView<SubmissionPage>(
        value: ref.watch(assignmentSubmissionsProvider(assignmentId)),
        onRetry: () => ref.invalidate(assignmentSubmissionsProvider(assignmentId)),
        notFound: NotFoundView(onBack: () => GoRouter.of(context).go(AppRoutes.staffReview)),
        data: (page) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(gutter, Space.s3, gutter, Space.s6),
          children: [
            _AssignmentHead(
              title: page.rows.firstOrNull?.assignmentTitle ?? l10n.reviewTitle,
              courseTitle: page.rows.firstOrNull?.courseTitle ?? '',
            ),
            const SizedBox(height: Space.s4),
            ListToolbar(
              chips: FilterChipBar<String>(
                padding: EdgeInsets.zero,
                selected: filter.filter,
                onSelected: controller.show,
                options: [
                  FilterOption(
                    'to-review',
                    l10n.reviewTabToReview,
                    count: page.countOf('to-review'),
                  ),
                  FilterOption('graded', l10n.reviewTabGraded, count: page.countOf('graded')),
                  FilterOption('returned', l10n.reviewTabReturned, count: page.countOf('returned')),
                  FilterOption('missing', l10n.reviewTabMissing, count: page.countOf('missing')),
                  FilterOption('all', l10n.reviewTabAll, count: page.countOf('all')),
                ],
              ),
            ),
            const SizedBox(height: Space.s4),
            if (page.countOf('missing') > 0 && watchCan(ref, Capability.messageLearners))
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s4),
                child: AppButton(
                  label: l10n.reviewRemindAction,
                  icon: AppIcons.notifications,
                  variant: AppButtonVariant.secondary,
                  busy: remind.busy,
                  expand: true,
                  onPressed: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: l10n.reviewRemindConfirmTitle,
                      message: l10n.reviewRemindConfirmBody,
                      confirmLabel: l10n.reviewRemindAction,
                    );
                    if (!confirmed) return;
                    await ref.read(remindProvider.notifier).remind(assignmentId);
                  },
                ),
              ),
            if (page.rows.isEmpty)
              EmptyState(title: l10n.reviewEmptyTitle, message: l10n.reviewEmptyBody)
            else ...[
              for (final row in page.rows) ...[
                SubmissionCard(
                  row: row,
                  onOpen: row.isMissing
                      ? null
                      : () => GoRouter.of(context).go(AppRoutes.staffSubmission(row.id)),
                ),
                const SizedBox(height: Space.s3),
              ],
              PagerRow(
                page: filter.page,
                pages: (page.total / submissionPageSize).ceil(),
                onPage: controller.showPage,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Which assignment these hand-ins are for, and the course it belongs to.
class _AssignmentHead extends StatelessWidget {
  const _AssignmentHead({required this.title, required this.courseTitle});

  final String title;
  final String courseTitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HueTile(icon: AppIcons.assignment, hue: AppNavIcons.of(AppIcons.assignment).hue),
        const SizedBox(width: Space.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text(title, style: context.type.titleM)),
              if (courseTitle.isNotEmpty) ...[
                const SizedBox(height: Space.s1),
                Text(courseTitle, style: context.type.caption.copyWith(color: c.muted)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
