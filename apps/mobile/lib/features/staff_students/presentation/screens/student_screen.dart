import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/auth/capabilities.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/format/figures.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/activity.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../staff_courses/staff_courses.dart';
import '../../application/staff_students_controller.dart';
import '../widgets/student_parts.dart';

/// `/staff/students/:studentId` — one learner: who they are, what they are on, how far they have
/// got, and what they have been doing. Every figure and every status is the academy's; an instructor
/// is served only the courses they teach (§7).
class StudentScreen extends ConsumerWidget {
  const StudentScreen({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    // Whatever the academy answered an action with is said once, in its own words.
    ref.listen(studentActionProvider, (previous, next) {
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
      ref.read(studentActionProvider.notifier).clearAnswer();
    });

    return AsyncView<StudentProfile>(
      value: ref.watch(studentProfileProvider(studentId)),
      onRetry: () => ref.invalidate(studentProfileProvider(studentId)),
      skeleton: const DelayedLoading(skeleton: SkeletonDetail()),
      notFound: NotFoundView(onBack: () => GoRouter.of(context).go(AppRoutes.staffStudents)),
      data: (profile) => _Student(studentId: studentId, profile: profile),
    );
  }
}

class _Student extends ConsumerStatefulWidget {
  const _Student({required this.studentId, required this.profile});

  final String studentId;
  final StudentProfile profile;

  @override
  ConsumerState<_Student> createState() => _StudentState();
}

class _StudentState extends ConsumerState<_Student> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = widget.profile;
    final student = profile.student;
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, Space.s3, gutter, Space.s3),
          child: AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarInitials(name: student.name, size: AvatarSizes.lg),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(student.name, style: context.type.titleL),
                      ),
                      const SizedBox(height: Space.s2),
                      StatusBadge(studentStatusKind(profile.status)),
                      const SizedBox(height: Space.s2),
                      // Their rank and how quiet they have been, read as one line.
                      MetaItem(
                        icon: AppIcons.rank,
                        label: [
                          profile.rank.title,
                          l10n.studentsQuietDays(profile.quietDays),
                        ].join(' · '),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: l10n.studentTabOverview),
            Tab(text: l10n.studentTabCourses),
            Tab(text: l10n.studentTabProgress),
            Tab(text: l10n.studentTabActivity),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _Overview(profile: profile, studentId: widget.studentId),
              _Courses(profile: profile, studentId: widget.studentId),
              _Progress(studentId: widget.studentId),
              _Activity(studentId: widget.studentId),
            ],
          ),
        ),
      ],
    );
  }
}

/// Who they are, how they are doing, and the decisions an admin may take about them.
class _Overview extends ConsumerWidget {
  const _Overview({required this.profile, required this.studentId});

  final StudentProfile profile;
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final student = profile.student;
    final summary = profile.summary;
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;
    final busy = ref.watch(studentActionProvider).busy;
    final maySuspend = watchCan(ref, Capability.suspendLearners);

    Future<void> setSuspended({required bool suspended}) async {
      final reason = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        barrierColor: c.scrim,
        builder: (_) => AppDialog(
          title: suspended ? l10n.studentSuspendConfirmTitle : l10n.studentRestoreConfirmTitle,
          message: suspended ? l10n.studentSuspendConfirmBody : l10n.studentRestoreConfirmBody,
          confirmLabel: suspended ? l10n.studentSuspendAction : l10n.studentRestoreAction,
          destructive: suspended,
          acknowledgementLabel: suspended ? l10n.studentSuspendAcknowledge : null,
          body: suspended
              ? AppTextField(
                  label: l10n.studentSuspendReasonLabel,
                  controller: reason,
                  maxLength: 500,
                  maxLines: 2,
                )
              : null,
        ),
      );
      if (confirmed != true || !context.mounted) return;
      final ok = await ref
          .read(studentActionProvider.notifier)
          .setSuspended(
            studentId,
            suspended: suspended,
            reason: reason.text.trim().isEmpty ? null : reason.text.trim(),
          );
      if (ok && context.mounted) {
        showAppSnackbar(
          context,
          suspended ? l10n.studentSuspended : l10n.studentRestored,
          tone: SnackTone.success,
        );
      }
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, Space.s3, gutter, Space.s6),
      children: [
        _header(context, l10n.studentContactTitle, AppIcons.email, Hue.blue),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s1),
          child: KeyValueTable(
            rows: [
              (l10n.studentEmailLabel, student.email),
              if (student.phone case final phone? when phone.isNotEmpty)
                (l10n.studentPhoneLabel, phone),
              if (student.city.isNotEmpty) (l10n.verifyCityLabel, student.city),
              if (student.joinedAt case final at?) (l10n.studentJoinedLabel, DatesIst.date(at)),
            ],
          ),
        ),
        const SizedBox(height: Space.s2),
        MetaItem(icon: AppIcons.lock, label: l10n.studentStaffOnlyNote),
        const SizedBox(height: Space.sectionGap),
        _header(context, l10n.studentSummaryTitle, AppIcons.reports, Hue.violet),
        // The three figures that say most, then the rest as plain rows.
        StatSummaryCard(
          figures: [
            StatFigure(
              value: formatFigure(summary.enrolled),
              label: l10n.studentStatEnrolled,
              icon: AppIcons.courses,
              hue: Hue.blue,
            ),
            StatFigure(
              value: '${formatFigure(summary.avgProgress)}%',
              label: l10n.studentStatAvgProgress,
              icon: AppIcons.chart,
              hue: Hue.green,
            ),
            // Nothing marked yet is a dash, never a zero the learner did not earn.
            StatFigure(
              value: summary.avgScore == null ? '—' : '${formatFigure(summary.avgScore!)}%',
              label: l10n.studentStatAvgScore,
              icon: AppIcons.rating,
              hue: Hue.gold,
            ),
          ],
        ),
        const SizedBox(height: Space.s3),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s1),
          child: KeyValueTable(
            rows: [
              (l10n.studentStatActive, formatFigure(summary.active)),
              (l10n.studentStatCompleted, formatFigure(summary.completed)),
              (l10n.studentStatStudyMinutes, AppDurations.minutes(l10n, summary.studyMinutes)),
              (l10n.studentStatSubmissions, formatFigure(summary.submissions)),
            ],
          ),
        ),
        const SizedBox(height: Space.sectionGap),
        _header(context, l10n.studentCertificatesTitle, AppIcons.certificate, Hue.gold),
        if (profile.certificates.isEmpty)
          AppCard(
            child: Text(
              l10n.studentNoCertificates,
              style: context.type.bodyM.copyWith(color: c.muted),
            ),
          )
        else
          GroupedList(
            children: [
              for (final certificate in profile.certificates)
                AppListTile(
                  title: certificate.title,
                  subtitle: certificate.issuedAt == null
                      ? certificate.credentialId
                      : l10n.studentCertificateIssued(
                          DatesIst.date(certificate.issuedAt!),
                          certificate.credentialId,
                        ),
                  leading: const HueTile(icon: AppIcons.certificate, hue: Hue.gold),
                ),
            ],
          ),
        if (maySuspend) ...[
          const SizedBox(height: Space.sectionGap),
          AppButton(
            label: student.isSuspended ? l10n.studentRestoreAction : l10n.studentSuspendAction,
            variant: student.isSuspended
                ? AppButtonVariant.secondary
                : AppButtonVariant.destructiveOutline,
            busy: busy,
            expand: true,
            onPressed: () => setSuspended(suspended: !student.isSuspended),
          ),
        ],
      ],
    );
  }
}

/// A section of the learner's page: its title, with an icon in the section's hue.
Widget _header(BuildContext context, String title, IconData icon, Hue hue) =>
    SectionHeader(title: title, icon: icon, iconColor: context.colors.hue(hue).solid);

/// What they are on, and what staff may do about each enrolment.
class _Courses extends ConsumerWidget {
  const _Courses({required this.profile, required this.studentId});

  final StudentProfile profile;
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;
    final action = ref.watch(studentActionProvider);
    final mayEnrol = watchCan(ref, Capability.enrollLearners);
    final courses = ref.watch(staffCoursesProvider).value?.rows ?? const [];
    final controller = ref.read(studentActionProvider.notifier);
    final alreadyOn = profile.enrollments.map((e) => e.enrollment.courseId).toSet();

    Future<void> say(bool ok, String message) async {
      if (ok && context.mounted) {
        showAppSnackbar(context, message, tone: SnackTone.success);
      }
    }

    Future<void> enrol() async {
      final options = courses.where((c) => !alreadyOn.contains(c.id)).toList();
      if (options.isEmpty) return;
      final courseId = await showAppBottomSheet<String>(
        context,
        builder: (_) => SelectSheet<String>(
          title: l10n.studentEnrolAction,
          options: [for (final course in options) SelectOption(course.id, course.title)],
        ),
      );
      if (courseId == null || !context.mounted) return;
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.studentEnrolConfirmTitle,
        message: l10n.studentEnrolConfirmBody,
        confirmLabel: l10n.studentEnrolAction,
      );
      if (!confirmed || !context.mounted) return;
      await say(await controller.enroll(studentId, courseId: courseId), l10n.studentEnrolled);
    }

    Future<void> pause(StudentEnrollment row) async {
      final paused = row.enrollment.status == EnrollmentStatus.paused;
      if (!paused) {
        final confirmed = await showConfirmDialog(
          context,
          title: l10n.studentPauseConfirmTitle,
          message: l10n.studentPauseConfirmBody,
          confirmLabel: l10n.studentPauseAction,
        );
        if (!confirmed || !context.mounted) return;
      }
      await say(
        await controller.pause(studentId, row.enrollment.id, paused: !paused),
        paused ? l10n.studentResumed : l10n.studentPaused,
      );
    }

    Future<void> remove(StudentEnrollment row) async {
      // Removing takes their progress with it, so it asks for an acknowledgement.
      final confirmed = await showDialog<bool>(
        context: context,
        barrierColor: context.colors.scrim,
        builder: (_) => AppDialog(
          title: l10n.studentRemoveConfirmTitle,
          message: l10n.studentRemoveConfirmBody,
          confirmLabel: l10n.studentRemoveAction,
          destructive: true,
          acknowledgementLabel: l10n.studentRemoveAcknowledge,
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await say(
        await controller.removeEnrollment(studentId, row.enrollment.id),
        l10n.studentRemoved,
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, Space.s3, gutter, Space.s6),
      children: [
        if (mayEnrol && courses.any((c) => !alreadyOn.contains(c.id)))
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s4),
            child: AppButton(
              label: l10n.studentEnrolAction,
              icon: AppIcons.add,
              variant: AppButtonVariant.secondary,
              busy: action.busy,
              expand: true,
              onPressed: enrol,
            ),
          ),
        if (profile.enrollments.isEmpty)
          EmptyState(title: l10n.studentTabCourses, message: l10n.studentCoursesEmpty)
        else
          for (final row in profile.enrollments) ...[
            EnrollmentCard(
              row: row,
              busy: action.busy,
              onPause: mayEnrol && row.enrollment.isOpen ? () => pause(row) : null,
              onRemove: mayEnrol ? () => remove(row) : null,
            ),
            const SizedBox(height: Space.s3),
          ],
      ],
    );
  }
}

/// How far they have got: per course by chapter, then quizzes, hand-ins and time studying.
class _Progress extends ConsumerWidget {
  const _Progress({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;

    return AsyncView<StudentProgress>(
      value: ref.watch(studentProgressProvider(studentId)),
      onRetry: () => ref.invalidate(studentProgressProvider(studentId)),
      data: (progress) => ListView(
        padding: EdgeInsets.fromLTRB(gutter, Space.s3, gutter, Space.s6),
        children: [
          if (progress.courses.isEmpty && progress.quizzes.isEmpty && progress.assignments.isEmpty)
            EmptyState(title: l10n.studentTabProgress, message: l10n.studentProgressEmpty),
          if (progress.courses.isNotEmpty) ...[
            _header(context, l10n.staffStudentsProgressByCourse, AppIcons.courses, Hue.blue),
            for (final course in progress.courses) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(course.courseTitle, style: context.type.titleS)),
                        const SizedBox(width: Space.s2),
                        Text('${formatFigure(course.progress)}%', style: context.type.numeral),
                      ],
                    ),
                    const SizedBox(height: Space.s3),
                    for (final chapter in course.chapters)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.s2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '${chapter.title} · ${chapter.completed}/${chapter.total}',
                              style: context.type.caption.copyWith(color: c.muted),
                            ),
                            const SizedBox(height: Space.s1),
                            ProgressBar(value: (chapter.percent / 100).clamp(0, 1).toDouble()),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Space.s3),
            ],
          ],
          if (progress.quizzes.isNotEmpty) ...[
            const SizedBox(height: Space.s2),
            _header(context, l10n.studentQuizzesTitle, AppIcons.quiz, Hue.orange),
            GroupedList(
              children: [
                for (final quiz in progress.quizzes)
                  AppListTile(
                    title: quiz.title,
                    subtitle: l10n.studentQuizBest(
                      formatFigure(quiz.best),
                      formatFigure(quiz.passMark),
                    ),
                    meta: quiz.lastAt == null ? null : DatesIst.date(quiz.lastAt!),
                    trailing: StatusBadge(quiz.passed ? StatusKind.passed : StatusKind.notPassed),
                  ),
              ],
            ),
          ],
          if (progress.assignments.isNotEmpty) ...[
            const SizedBox(height: Space.sectionGap),
            _header(context, l10n.studentAssignmentsTitle, AppIcons.assignment, Hue.orange),
            GroupedList(
              children: [
                for (final assignment in progress.assignments)
                  AppListTile(
                    title: assignment.title,
                    subtitle: assignment.score == null
                        ? assignment.courseTitle
                        : '${formatFigure(assignment.score!)} / ${formatFigure(assignment.max)}',
                    meta: assignment.submittedAt == null
                        ? null
                        : DatesIst.date(assignment.submittedAt!),
                    trailing: assignment.late ? const StatusBadge(StatusKind.late) : null,
                  ),
              ],
            ),
          ],
          if (progress.studyWeeks.isNotEmpty) ...[
            const SizedBox(height: Space.sectionGap),
            ColumnChart(
              title: l10n.studentStudyWeeksTitle,
              points: [
                for (final week in progress.studyWeeks)
                  ChartPoint(week.label, week.minutes.toDouble(), '${week.minutes}'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// What they have been doing, in the academy's own words, filtered by kind.
class _Activity extends ConsumerWidget {
  const _Activity({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;
    final filter = ref.watch(activityFilterProvider);
    final controller = ref.read(activityFilterProvider.notifier);
    final activity = ref.watch(studentActivityProvider(studentId));
    final counts = activity.value;

    return AsyncView<StudentActivity>(
      value: activity,
      onRetry: () => ref.invalidate(studentActivityProvider(studentId)),
      data: (activity) => ListView(
        padding: EdgeInsets.fromLTRB(gutter, Space.s3, gutter, Space.s6),
        children: [
          FilterChipBar<String>(
            padding: EdgeInsets.zero,
            selected: filter.kind ?? 'all',
            onSelected: controller.ofKind,
            options: [
              FilterOption('all', l10n.studentActivityAll, count: counts?.countOf('all')),
              for (final kind in ActivityKind.values)
                if (kind != ActivityKind.unknown && (counts?.countOf(kind.wireName) ?? 0) > 0)
                  FilterOption(
                    kind.wireName,
                    activityLabel(l10n, kind),
                    count: counts?.countOf(kind.wireName),
                  ),
            ],
          ),
          const SizedBox(height: Space.s4),
          if (activity.events.isEmpty)
            EmptyState(title: l10n.studentTabActivity, message: l10n.studentActivityEmpty)
          else
            GroupedList(
              children: [
                for (final event in activity.events)
                  AppListTile(
                    title: event.title,
                    subtitle: activityLabel(l10n, event.kind),
                    meta: DatesIst.dateTime(l10n, event.at),
                    leading: AppIcon(activityIcon(event.kind), color: c.muted),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
