import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/auth/capabilities.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/format/figures.dart';
import '../../../../core/format/money.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/platform/external_link.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/course.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/auth.dart';
import '../../application/staff_courses_controller.dart';
import '../widgets/course_parts.dart';

/// Where the web edits this course, for the signed-in role (C2): an academy admin edits it under
/// `/admin`, an instructor under `/teach`.
Uri courseEditUrl(Uri webBaseUrl, UserRole role, String courseId) => webBaseUrl.replace(
  path: '${role == UserRole.admin ? '/admin' : '/teach'}/courses/$courseId/edit',
);

/// `/staff/courses/:courseId` — one course: what it is, how it is going, and the decisions that
/// change its life. Every refusal shown here is the academy's own (§18).
class StaffCourseScreen extends ConsumerWidget {
  const StaffCourseScreen({required this.courseId, super.key});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView<Course>(
      value: ref.watch(staffCourseProvider(courseId)),
      onRetry: () => ref.invalidate(staffCourseProvider(courseId)),
      skeleton: const DelayedLoading(skeleton: SkeletonDetail()),
      notFound: NotFoundView(onBack: () => GoRouter.of(context).go(AppRoutes.staffCourses)),
      data: (course) => _Course(course: course),
    );
  }
}

class _Course extends ConsumerWidget {
  const _Course({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;
    final stats = ref.watch(staffCourseStatsProvider(course.id));

    // A refusal the academy did not answer with a checklist is shown in its own words.
    ref.listen(courseActionProvider, (previous, next) {
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
      ref.read(courseActionProvider.notifier).clearAnswer();
    });
    ref.listen(courseActionProvider, (previous, next) {
      if (next.checklist.isEmpty || next.checklist == previous?.checklist) return;
      final checklist = next.checklist;
      ref.read(courseActionProvider.notifier).clearAnswer();
      showPublishChecklist(context, checklist);
    });

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(staffCourseProvider(course.id))
          ..invalidate(staffCourseStatsProvider(course.id));
        await ref.read(staffCourseProvider(course.id).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
        children: [
          _Header(course: course),
          const SizedBox(height: Space.s4),
          _Actions(course: course),
          const SizedBox(height: Space.sectionGap),
          SectionHeader(
            title: l10n.staffCourseStatsTitle,
            icon: AppIcons.reports,
            iconColor: c.hue(Hue.violet).solid,
          ),
          AsyncView<CourseStats>(
            value: stats,
            onRetry: () => ref.invalidate(staffCourseStatsProvider(course.id)),
            skeleton: const DelayedLoading(skeleton: SkeletonCard()),
            data: (stats) => _Stats(stats: stats, course: course),
          ),
          const SizedBox(height: Space.sectionGap),
          SectionHeader(
            title: l10n.staffCourseCurriculumTitle,
            icon: AppIcons.courses,
            iconColor: c.hue(Hue.blue).solid,
          ),
          GroupedList(
            children: [
              AppListTile(
                title: l10n.staffCourseCurriculumFacts(
                  course.chapters.length,
                  course.lessons.length,
                ),
                subtitle: course.durationMin > 0
                    ? AppDurations.minutes(l10n, course.durationMin)
                    : null,
                leading: const HueTile(icon: AppIcons.list, hue: Hue.blue),
                showChevron: true,
                onTap: () => GoRouter.of(context).go(AppRoutes.staffCurriculum(course.id)),
              ),
            ],
          ),
          if (course.description.isNotEmpty) ...[
            const SizedBox(height: Space.sectionGap),
            SectionHeader(
              title: l10n.courseAboutTitle,
              icon: AppIcons.info,
              iconColor: c.hue(Hue.violet).solid,
            ),
            Text(course.description, style: context.type.bodyM),
          ],
          if (course.outcomes.isNotEmpty) ...[
            const SizedBox(height: Space.sectionGap),
            SectionHeader(
              title: l10n.staffCourseOutcomesTitle,
              icon: AppIcons.success,
              iconColor: c.hue(Hue.green).solid,
            ),
            for (final outcome in course.outcomes)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(AppIcons.check, size: IconSizes.sm, color: c.accentInk),
                    const SizedBox(width: Space.s2),
                    Expanded(child: Text(outcome, style: context.type.bodyM)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: Space.sectionGap),
          SectionHeader(
            title: l10n.staffCourseOverviewTitle,
            icon: AppIcons.settings,
            iconColor: c.hue(Hue.gold).solid,
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s1),
            child: KeyValueTable(
              rows: [
                (l10n.courseFormatLabel, _formatLabel(l10n, course.format)),
                (l10n.staffCourseVisibilityLabel, visibilityLabel(l10n, course.visibility)),
                if (course.language.isNotEmpty) (l10n.courseLanguageLabel, course.language),
                if (course.price case final price?)
                  (l10n.courseEnrolledLabel, Money.formatMajor(price.amount, price.currency)),
                if (course.certificateTitle case final title?) (l10n.courseCertificateLabel, title),
                if (course.liveSessions > 0)
                  (l10n.courseLiveSessionsLabel, formatFigure(course.liveSessions)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(AppLocalizations l10n, CourseFormat format) => switch (format) {
    CourseFormat.selfPaced || CourseFormat.unknown => l10n.courseFormatSelfPaced,
    CourseFormat.cohort => l10n.courseFormatCohort,
    CourseFormat.hybrid => l10n.courseFormatHybrid,
  };
}

/// What the course is and where it stands: its cover, status, title and subtitle, and the size of
/// it — learners, lessons and running time, as the server counted them.
class _Header extends StatelessWidget {
  const _Header({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: courseThumbSize,
                child: CourseCover(
                  motif: CoverMotif.parse(course.coverMotif),
                  imageUrl: course.coverImageUrl,
                  semanticLabel: l10n.courseCoverLabel,
                  aspectRatio: 1,
                ),
              ),
              const SizedBox(width: Space.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(courseStatusKind(course.status)),
                    const SizedBox(height: Space.s2),
                    Semantics(header: true, child: Text(course.title, style: context.type.titleL)),
                    if (course.subtitle.isNotEmpty) ...[
                      const SizedBox(height: Space.s1),
                      Text(course.subtitle, style: context.type.bodyM.copyWith(color: c.muted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s3),
          Wrap(
            spacing: Space.s4,
            runSpacing: Space.s1,
            children: [
              MetaItem(
                icon: AppIcons.people,
                label: l10n.staffCourseLearners(course.enrolledCount),
              ),
              MetaItem(
                icon: AppIcons.lessonReading,
                label: l10n.staffCourseLessons(course.lessons.length),
              ),
              if (course.durationMin > 0)
                MetaItem(
                  icon: AppIcons.duration,
                  label: AppDurations.minutes(l10n, course.durationMin),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Publishing, unpublishing, archiving and restoring, each offered only to someone the academy
/// lets do it — and always confirmed, because each one changes what learners see (§22.5).
class _Actions extends ConsumerWidget {
  const _Actions({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final busy = ref.watch(courseActionProvider).busy;
    final profile = ref.watch(currentUserProvider);
    final role = profile?.role ?? UserRole.unknown;
    final actions = ref.read(courseActionProvider.notifier);
    final webBase = ref.watch(appConfigProvider).webBaseUrl;
    // While the plan that included courses has ended, a course can still be unpublished, archived
    // and edited, but not put in front of learners: Publish stays, disabled, and says why.
    final readOnly = watchModuleAccess(ref, WorkspaceModule.courses) == ModuleAccess.readOnly;
    final offersPublish =
        can(profile, Capability.publishCourses) &&
        course.status != CourseStatus.archived &&
        course.status != CourseStatus.published;

    Future<void> run(Future<bool> Function() action, String doneMessage) async {
      final ok = await action();
      if (ok && context.mounted) {
        showAppSnackbar(context, doneMessage, tone: SnackTone.success);
      }
    }

    // The decision that changes what learners see leads, full width; the rest follow it.
    final lifecycle = <Widget>[
      if (can(profile, Capability.publishCourses) && course.status != CourseStatus.archived)
        if (course.status == CourseStatus.published)
          AppButton(
            label: l10n.staffCourseActionUnpublish,
            variant: AppButtonVariant.secondary,
            busy: busy,
            expand: true,
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: l10n.staffCourseUnpublishConfirmTitle,
                message: l10n.staffCourseUnpublishConfirmBody,
                confirmLabel: l10n.staffCourseActionUnpublish,
              );
              if (!confirmed || !context.mounted) return;
              await run(() => actions.unpublish(course.id), l10n.staffCourseUnpublished);
            },
          )
        else
          AppButton(
            label: l10n.staffCourseActionPublish,
            busy: busy,
            expand: true,
            onPressed: readOnly
                ? null
                : () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: l10n.staffCoursePublishConfirmTitle,
                      message: l10n.staffCoursePublishConfirmBody,
                      confirmLabel: l10n.staffCourseActionPublish,
                    );
                    if (!confirmed || !context.mounted) return;
                    await run(() => actions.publish(course.id), l10n.staffCoursePublished);
                  },
          ),
    ];
    final others = <Widget>[
      if (can(profile, Capability.archiveCourses))
        if (course.status == CourseStatus.archived)
          AppButton(
            label: l10n.staffCourseActionRestore,
            variant: AppButtonVariant.secondary,
            busy: busy,
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: l10n.staffCourseRestoreConfirmTitle,
                message: l10n.staffCourseRestoreConfirmBody,
                confirmLabel: l10n.staffCourseActionRestore,
              );
              if (!confirmed || !context.mounted) return;
              await run(() => actions.restore(course.id), l10n.staffCourseRestored);
            },
          )
        else
          AppButton(
            label: l10n.staffCourseActionArchive,
            variant: AppButtonVariant.destructiveOutline,
            busy: busy,
            onPressed: () async {
              // Archiving takes a course away from learners, so it asks for an acknowledgement.
              final confirmed = await showDialog<bool>(
                context: context,
                barrierColor: context.colors.scrim,
                builder: (_) => AppDialog(
                  title: l10n.staffCourseArchiveConfirmTitle,
                  message: l10n.staffCourseArchiveConfirmBody,
                  confirmLabel: l10n.staffCourseActionArchive,
                  destructive: true,
                  acknowledgementLabel: l10n.staffCourseArchiveAcknowledge,
                ),
              );
              if (confirmed != true || !context.mounted) return;
              await run(() => actions.archive(course.id), l10n.staffCourseArchived);
            },
          ),
      AppButton(
        label: l10n.staffCourseEditOnWeb,
        icon: AppIcons.external,
        variant: AppButtonVariant.tertiary,
        onPressed: () =>
            ref.read(openExternalLinkProvider)(courseEditUrl(webBase, role, course.id)),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...lifecycle,
        if (lifecycle.isNotEmpty) const SizedBox(height: Space.s2),
        Wrap(spacing: Space.s2, runSpacing: Space.s2, children: others),
        if (readOnly && offersPublish) ...[
          const SizedBox(height: Space.s2),
          Text(
            readOnlyActionReason(l10n, WorkspaceModule.courses),
            style: context.type.caption.copyWith(color: context.colors.muted),
          ),
        ],
      ],
    );
  }
}

/// How the course is going, in the academy's figures: the three that matter most side by side,
/// the rest as a table, the server's own charts, and who joined lately.
class _Stats extends StatelessWidget {
  const _Stats({required this.stats, required this.course});

  final CourseStats stats;
  final Course course;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatSummaryCard(
          figures: [
            StatFigure(
              value: formatFigure(stats.enrolled),
              label: l10n.staffCourseStatEnrolled,
              icon: AppIcons.people,
              hue: Hue.green,
            ),
            StatFigure(
              value: formatFigure(stats.active),
              label: l10n.staffCourseStatActive,
              icon: AppIcons.rocket,
              hue: Hue.blue,
            ),
            StatFigure(
              value: '${formatFigure(stats.completionRate)}%',
              label: l10n.staffCourseStatCompletion,
              icon: AppIcons.success,
              hue: Hue.violet,
            ),
          ],
        ),
        const SizedBox(height: Space.s3),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s1),
          child: KeyValueTable(
            rows: [
              (l10n.staffCourseStatProgress, '${formatFigure(stats.avgProgress)}%'),
              (l10n.staffCourseStatCertificates, formatFigure(stats.certificatesIssued)),
              (l10n.staffCourseStatReviews, formatFigure(stats.reviewsWaiting)),
              (l10n.staffCourseStatMinutes, AppDurations.minutes(l10n, stats.totalMinutes)),
              (l10n.staffCourseUpcomingLiveTitle, formatFigure(stats.upcomingLive)),
            ],
          ),
        ),
        if (stats.weekly.isNotEmpty) ...[
          const SizedBox(height: Space.s4),
          TrendChart(
            title: l10n.staffCourseWeeklyTitle,
            points: [
              for (final point in stats.weekly)
                ChartPoint(
                  point.day == null ? point.date : DatesIst.shortDate(point.day!),
                  point.value.toDouble(),
                  formatFigure(point.value),
                ),
            ],
          ),
        ],
        if (stats.progressBuckets.isNotEmpty) ...[
          const SizedBox(height: Space.s4),
          BarList(
            title: l10n.staffCourseProgressSpreadTitle,
            points: [
              // The band labels are the server's own ("0-20%"), so the app never renames them.
              for (final bucket in stats.progressBuckets)
                ChartPoint(bucket.label, bucket.value.toDouble(), formatFigure(bucket.value)),
            ],
          ),
        ],
        const SizedBox(height: Space.sectionGap),
        SectionHeader(
          title: l10n.staffCourseRecentTitle,
          icon: AppIcons.people,
          iconColor: c.hue(Hue.green).solid,
        ),
        if (stats.recent.isEmpty)
          AppCard(
            child: Text(
              l10n.staffCourseNoLearnersYet,
              style: context.type.bodyM.copyWith(color: c.muted),
            ),
          )
        else
          GroupedList(
            children: [
              for (final learner in stats.recent)
                AppListTile(
                  title: learner.name,
                  subtitle: '${formatFigure(learner.progress)}%',
                  meta: learner.enrolledAt == null ? null : DatesIst.date(learner.enrolledAt!),
                  leading: AvatarInitials(name: learner.name, size: AvatarSizes.sm),
                ),
            ],
          ),
      ],
    );
  }
}
