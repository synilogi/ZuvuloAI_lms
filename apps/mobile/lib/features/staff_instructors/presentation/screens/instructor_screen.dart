import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/auth/capabilities.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/figures.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_instructors_controller.dart';
import '../widgets/instructor_parts.dart';

/// `/staff/instructors/:instructorId` — one instructor: who they are, what they teach and how their
/// teaching is going. Every figure is the academy's arithmetic, including the comparisons with the
/// academy as a whole; the app only formats them (§18). A shell body.
class InstructorScreen extends ConsumerWidget {
  const InstructorScreen({required this.instructorId, super.key});

  final String instructorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    // The academy's answer to a status change or an invitation, said once.
    ref.listen(instructorActionProvider, (previous, next) {
      if (next.invitedTo case final email? when email != previous?.invitedTo) {
        showAppSnackbar(context, l10n.instructorResendInviteSent(email), tone: SnackTone.success);
        ref.read(instructorActionProvider.notifier).clearAnswer();
        return;
      }
      if (next.done && !(previous?.done ?? false) && next.invitedTo == null) {
        showAppSnackbar(context, l10n.instructorStatusChanged, tone: SnackTone.success);
        ref.read(instructorActionProvider.notifier).clearAnswer();
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
      ref.read(instructorActionProvider.notifier).clearAnswer();
    });

    return RefreshIndicator(
      onRefresh: () => ref.refresh(instructorProvider(instructorId).future),
      child: AsyncView<InstructorDetail>(
        value: ref.watch(instructorProvider(instructorId)),
        onRetry: () => ref.invalidate(instructorProvider(instructorId)),
        data: (detail) => _Instructor(instructorId: instructorId, detail: detail),
      ),
    );
  }
}

class _Instructor extends ConsumerStatefulWidget {
  const _Instructor({required this.instructorId, required this.detail});

  final String instructorId;
  final InstructorDetail detail;

  @override
  ConsumerState<_Instructor> createState() => _InstructorState();
}

class _InstructorState extends ConsumerState<_Instructor> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final detail = widget.detail;
    final instructor = detail.instructor;
    final gutter = WindowSize.of(context).isCompact ? Space.s4 : Space.gutterMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, Space.s3, gutter, Space.s2),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AvatarInitials(name: instructor.name, size: AvatarSizes.lg),
                    const SizedBox(width: Space.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(instructor.name, style: context.type.titleL),
                          ),
                          const SizedBox(height: Space.s1),
                          Text(
                            [
                              instructor.title,
                              if (instructor.city.isNotEmpty) instructor.city,
                            ].where((part) => part.isNotEmpty).join(' · '),
                            style: context.type.bodyS.copyWith(color: c.muted),
                          ),
                          const SizedBox(height: Space.s2),
                          StatusBadge(instructorStatusKind(instructor.status)),
                        ],
                      ),
                    ),
                  ],
                ),
                _Actions(instructorId: widget.instructorId, instructor: instructor),
              ],
            ),
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: l10n.instructorTabOverview),
            Tab(text: l10n.instructorTabCourses),
            Tab(text: l10n.instructorTabPerformance),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _Overview(detail: detail),
              _Courses(detail: detail),
              _Performance(performance: detail.performance),
            ],
          ),
        ),
      ],
    );
  }
}

/// What may be done to this instructor, offered only where the academy allows it.
class _Actions extends ConsumerWidget {
  const _Actions({required this.instructorId, required this.instructor});

  final String instructorId;
  final AcademyInstructor instructor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mayManage = watchCan(ref, Capability.manageInstructors);
    final maySetStatus = watchCan(ref, Capability.setInstructorStatus);
    final action = ref.watch(instructorActionProvider);
    final controller = ref.read(instructorActionProvider.notifier);
    if (!mayManage && !maySetStatus) return const SizedBox.shrink();

    final goingInactive = instructor.status != InstructorStatus.inactive;

    Future<void> changeStatus() async {
      final confirmed = await showConfirmDialog(
        context,
        title: goingInactive ? l10n.instructorMakeInactiveTitle : l10n.instructorMakeActiveTitle,
        message: goingInactive ? l10n.instructorMakeInactiveBody : l10n.instructorMakeActiveBody,
        confirmLabel: goingInactive
            ? l10n.instructorMakeInactiveAction
            : l10n.instructorMakeActiveAction,
      );
      if (!confirmed) return;
      await controller.setStatus(
        instructorId,
        goingInactive ? InstructorStatus.inactive : InstructorStatus.active,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: Space.s4),
      child: Wrap(
        spacing: Space.s2,
        runSpacing: Space.s2,
        children: [
          if (mayManage)
            AppButton(
              label: l10n.instructorEditAction,
              variant: AppButtonVariant.secondary,
              icon: AppIcons.edit,
              onPressed: () => GoRouter.of(context).go(AppRoutes.staffInstructorEdit(instructorId)),
            ),
          // Only someone waiting on an invitation needs another one.
          if (mayManage && instructor.awaitsInvite)
            AppButton(
              label: l10n.instructorResendInviteAction,
              variant: AppButtonVariant.tertiary,
              busy: action.busy,
              onPressed: () => controller.resendInvite(instructorId),
            ),
          if (maySetStatus)
            AppButton(
              label: goingInactive
                  ? l10n.instructorMakeInactiveAction
                  : l10n.instructorMakeActiveAction,
              variant: goingInactive
                  ? AppButtonVariant.destructiveOutline
                  : AppButtonVariant.secondary,
              busy: action.busy,
              onPressed: changeStatus,
            ),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.detail});

  final InstructorDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final instructor = detail.instructor;
    final reach = detail.reach;
    final gutter = WindowSize.of(context).isCompact ? Space.s4 : Space.gutterMedium;

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
      children: [
        SectionHeader(
          title: l10n.instructorAboutTitle,
          icon: AppIcons.info,
          iconColor: sectionHue(context, AppIcons.reports),
        ),
        AppCard(
          child: Text(
            instructor.bio.isEmpty ? l10n.instructorNoBio : instructor.bio,
            style: context.type.bodyM,
          ),
        ),
        if (instructor.expertise.isNotEmpty) ...[
          const SizedBox(height: Space.sectionGap),
          SectionHeader(
            title: l10n.instructorExpertiseTitle,
            icon: AppIcons.rank,
            iconColor: context.colors.hue(Hue.gold).solid,
          ),
          TagRow(tags: instructor.expertise),
        ],
        const SizedBox(height: Space.sectionGap),
        SectionHeader(
          title: l10n.instructorReachTitle,
          icon: AppIcons.people,
          iconColor: sectionHue(context, AppIcons.people),
        ),
        TileGrid(
          children: [
            KpiTile(
              icon: AppIcons.people,
              tone: Tone.info,
              label: l10n.instructorReachStudents,
              value: '${reach.students}',
            ),
            KpiTile(
              icon: AppIcons.rocket,
              tone: Tone.accent,
              label: l10n.instructorReachActive,
              value: '${reach.active}',
            ),
            KpiTile(
              icon: AppIcons.success,
              tone: Tone.accent,
              label: l10n.instructorReachCompleted,
              value: '${reach.completed}',
            ),
            KpiTile(
              icon: AppIcons.add,
              tone: Tone.accent,
              label: l10n.instructorReachNewThisMonth,
              value: '${reach.newThisMonth}',
            ),
          ],
        ),
        if (reach.cities.isNotEmpty) ...[
          const SizedBox(height: Space.sectionGap),
          SectionHeader(
            title: l10n.instructorCitiesTitle,
            icon: AppIcons.explore,
            iconColor: sectionHue(context, AppIcons.calendar),
          ),
          BarList(
            points: [
              for (final city in reach.cities)
                ChartPoint(
                  city.city,
                  city.count.toDouble(),
                  l10n.instructorCityLearners(city.count),
                ),
            ],
          ),
        ],
        const SizedBox(height: Space.sectionGap),
        SectionHeader(
          title: l10n.instructorDetailsTitle,
          icon: AppIcons.profile,
          iconColor: sectionHue(context, AppIcons.profile),
        ),
        _Facts(
          rows: [
            (l10n.instructorEmailLabel, instructor.email),
            if (instructor.phone case final phone? when phone.isNotEmpty)
              (l10n.instructorPhoneLabel, phone),
            if (instructor.city.isNotEmpty) (l10n.instructorCityLabel, instructor.city),
            if (instructor.languages.isNotEmpty)
              (l10n.instructorLanguagesLabel, instructor.languages.join(', ')),
            if (instructor.yearsTeaching case final years?) (l10n.instructorYearsLabel, '$years'),
            (l10n.instructorJoinedLabel, DatesIst.date(instructor.joinedAt)),
          ],
        ),
        const SizedBox(height: Space.sectionGap),
        SectionHeader(
          title: l10n.instructorActivityTitle,
          icon: AppIcons.list,
          iconColor: sectionHue(context, AppIcons.reports),
        ),
        if (detail.activity.isEmpty)
          EmptyState(title: l10n.instructorActivityTitle, message: l10n.instructorActivityEmpty)
        else
          InstructorActivityList(events: detail.activity),
      ],
    );
  }
}

class _Courses extends StatelessWidget {
  const _Courses({required this.detail});

  final InstructorDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gutter = WindowSize.of(context).isCompact ? Space.s4 : Space.gutterMedium;

    if (detail.courses.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(gutter),
        child: EmptyState(title: l10n.instructorTabCourses, message: l10n.instructorCoursesEmpty),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
      children: [
        for (final course in detail.courses) ...[
          InstructorCourseCard(
            course: course,
            onOpen: () => GoRouter.of(context).go(AppRoutes.staffCourse(course.id)),
          ),
          const SizedBox(height: Space.s3),
        ],
      ],
    );
  }
}

class _Performance extends StatelessWidget {
  const _Performance({required this.performance});

  final InstructorPerformance performance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gutter = WindowSize.of(context).isCompact ? Space.s4 : Space.gutterMedium;

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
      children: [
        TileGrid(
          children: [
            KpiTile(
              icon: AppIcons.chart,
              tone: Tone.accent,
              label: l10n.instructorPerformanceRating,
              value: performance.rating == null
                  ? l10n.instructorNoFigureYet
                  : formatFigure(performance.rating!),
              // The academy's own average is the comparison; the gap is arithmetic on its figures.
              delta: performance.ratingGap,
              deltaUnit: '',
              comparisonLabel: l10n.instructorVsAcademy,
            ),
            KpiTile(
              icon: AppIcons.success,
              tone: Tone.accent,
              label: l10n.instructorPerformanceCompletion,
              value: performance.completion == null
                  ? l10n.instructorNoFigureYet
                  : '${performance.completion}%',
              delta: performance.completionGap?.toDouble(),
              deltaUnit: ' pts',
              comparisonLabel: l10n.instructorVsAcademy,
            ),
          ],
        ),
        const SizedBox(height: Space.sectionGap),
        SectionHeader(
          title: l10n.instructorReviewTitle,
          icon: AppIcons.review,
          iconColor: sectionHue(context, AppIcons.review),
        ),
        _Facts(
          rows: [
            (
              l10n.instructorReviewMedian,
              performance.reviewHoursMedian == null
                  ? l10n.instructorNoFigureYet
                  : l10n.instructorReviewMedianHours(performance.reviewHoursMedian!),
            ),
            (
              l10n.instructorReviewOnTime,
              performance.reviewsOnTime == null
                  ? l10n.instructorNoFigureYet
                  : '${performance.reviewsOnTime}%',
            ),
            (l10n.instructorReviewed, '${performance.reviewed}'),
            (l10n.instructorReviewWaiting, '${performance.toReview}'),
          ],
        ),
        const SizedBox(height: Space.sectionGap),
        SectionHeader(
          title: l10n.instructorLiveTitle,
          icon: AppIcons.live,
          iconColor: sectionHue(context, AppIcons.live),
        ),
        _Facts(
          rows: [
            (l10n.instructorLiveDelivered, '${performance.liveDelivered}'),
            (l10n.instructorLiveUpcoming, '${performance.liveUpcoming}'),
            (
              l10n.instructorAttendance,
              performance.attendance == null
                  ? l10n.instructorNoFigureYet
                  : '${performance.attendance}%',
            ),
          ],
        ),
        if (performance.enrollmentsByMonth.isNotEmpty) ...[
          const SizedBox(height: Space.sectionGap),
          EnrolmentMonths(months: performance.enrollmentsByMonth),
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
