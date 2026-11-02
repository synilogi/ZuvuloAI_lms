import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../staff_live/staff_live.dart';
import '../../application/staff_calendar_controller.dart';
import '../widgets/calendar_parts.dart';

/// `/staff/calendar/:eventId` — one event, read by its type. A live class or a deadline is changed
/// where it lives, and this screen says so and points there (§26).
class CalendarEventScreen extends ConsumerWidget {
  const CalendarEventScreen({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView<CalendarDetail>(
      value: ref.watch(calendarEventProvider(eventId)),
      onRetry: () => ref.invalidate(calendarEventProvider(eventId)),
      skeleton: const DelayedLoading(skeleton: SkeletonDetail()),
      notFound: NotFoundView(onBack: () => GoRouter.of(context).go(AppRoutes.staffCalendar)),
      data: (detail) => _Event(eventId: eventId, detail: detail),
    );
  }
}

class _Event extends ConsumerWidget {
  const _Event({required this.eventId, required this.detail});

  final String eventId;
  final CalendarDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final event = detail.event;
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;
    final action = ref.watch(calendarActionProvider);
    final controller = ref.read(calendarActionProvider.notifier);

    ref.listen(calendarActionProvider, (previous, next) {
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

    Future<void> remove() async {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.calendarRemoveConfirmTitle,
        message: l10n.calendarRemoveConfirmBody,
        confirmLabel: l10n.calendarRemoveAction,
        destructive: true,
      );
      if (!confirmed || !context.mounted) return;
      final ok = await controller.remove(eventId);
      if (ok && context.mounted) {
        showAppSnackbar(context, l10n.calendarRemoved, tone: SnackTone.success);
        GoRouter.of(context).go(AppRoutes.staffCalendar);
      }
    }

    /// Where a derived event really lives.
    final source = event.source;

    Widget header(String title, IconData icon, Hue hue) =>
        SectionHeader(title: title, icon: icon, iconColor: c.hue(hue).solid);

    final facts = [
      if (detail.courseTitle case final title?) (l10n.calendarFormCourse, title),
      if (detail.chapterTitle case final title?) (l10n.calendarFormChapter, title),
      if (detail.instructorName case final name?) (l10n.staffCoursesInstructorLabel, name),
      if (event.milestone case final kind? when kind != MilestoneKind.unknown)
        (l10n.calendarFormMilestone, milestoneLabel(l10n, kind)),
      if (event.audience case final audience?)
        (
          l10n.calendarFormAudience,
          audience == ReminderAudience.learners
              ? l10n.calendarAudienceLearners
              : l10n.calendarAudienceMe,
        ),
      if (event.notifyMin case final minutes?)
        (l10n.calendarFormNotify, reminderLabelFor(l10n, minutes)),
      if (detail.audienceSize case final size?)
        (l10n.calendarFormAudience, l10n.calendarAudienceSize(size)),
    ];

    final actions = <Widget>[
      // A derived event is opened where it really lives.
      if (source?.kind == 'live-class')
        AppButton(
          label: l10n.calendarOpenLive,
          icon: AppIcons.live,
          variant: AppButtonVariant.secondary,
          onPressed: () => GoRouter.of(context).go(AppRoutes.staffLiveClass(source!.id)),
        ),
      if (source?.kind == 'assignment')
        AppButton(
          label: l10n.calendarOpenSubmissions,
          icon: AppIcons.assignment,
          variant: AppButtonVariant.secondary,
          onPressed: () => GoRouter.of(context).go(AppRoutes.staffSubmissions(source!.id)),
        ),
      if (event.quizId case final quizId? when event.type == CalendarEventType.quiz)
        AppButton(
          label: l10n.calendarOpenQuiz,
          icon: AppIcons.quiz,
          variant: AppButtonVariant.tertiary,
          onPressed: () => GoRouter.of(context).go(AppRoutes.staffQuiz(quizId)),
        ),
      if (detail.editable) ...[
        if (event.type == CalendarEventType.reminder)
          AppButton(
            label: event.done ? l10n.calendarUndoneAction : l10n.calendarDoneAction,
            icon: event.done ? null : AppIcons.check,
            variant: event.done ? AppButtonVariant.tertiary : AppButtonVariant.primary,
            busy: action.busy,
            onPressed: () => controller.setDone(eventId, done: !event.done),
          ),
        AppButton(
          label: l10n.staffLiveEditAction,
          icon: AppIcons.edit,
          variant: AppButtonVariant.secondary,
          onPressed: () => GoRouter.of(context).go(AppRoutes.staffEventEdit(eventId)),
        ),
        AppButton(
          label: l10n.calendarRemoveAction,
          variant: AppButtonVariant.destructiveOutline,
          busy: action.busy,
          onPressed: remove,
        ),
      ],
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
      children: [
        _EventHeader(detail: detail),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: Space.s3),
          Wrap(spacing: Space.s2, runSpacing: Space.s2, children: actions),
        ],
        // Why it cannot be changed here, in the terms the academy uses.
        if (!detail.editable) ...[
          const SizedBox(height: Space.s2),
          Text(switch (event.type) {
            CalendarEventType.live => l10n.calendarNotEditableLive,
            CalendarEventType.assignment => l10n.calendarNotEditableAssignment,
            _ => l10n.calendarNotEditableOther,
          }, style: context.type.caption.copyWith(color: c.muted)),
        ],
        if (facts.isNotEmpty) ...[
          const SizedBox(height: Space.sectionGap),
          header(l10n.staffCalendarDetailsTitle, AppIcons.info, Hue.blue),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s1),
            child: KeyValueTable(rows: facts),
          ),
        ],
        if (event.description case final description? when description.isNotEmpty) ...[
          const SizedBox(height: Space.sectionGap),
          header(l10n.calendarFormDescription, AppIcons.lessonReading, Hue.violet),
          Text(description, style: context.type.bodyM),
        ],
        if (detail.live case final live?) ...[
          const SizedBox(height: Space.sectionGap),
          header(l10n.calendarTypeLive, AppIcons.live, eventTypeHue(CalendarEventType.live)),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s1),
            child: KeyValueTable(
              rows: [
                (
                  l10n.staffLiveAttendeesTitle,
                  live.capacity == null
                      ? l10n.staffLiveRegisteredCount(live.registered)
                      : l10n.staffLiveOfCapacity(live.registered, live.capacity!),
                ),
                if (live.attended case final attended?) (l10n.staffLiveAttended, '$attended'),
              ],
            ),
          ),
        ],
        if (detail.quiz case final quiz?) ...[
          const SizedBox(height: Space.sectionGap),
          header(l10n.calendarFormQuiz, AppIcons.quiz, eventTypeHue(CalendarEventType.quiz)),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s1),
            child: KeyValueTable(
              rows: [
                (l10n.calendarFormQuiz, quiz.title),
                (l10n.staffQuizQuestionsTitle, '${quiz.questions}'),
                if (quiz.passMark case final mark?) (l10n.staffQuizPassMarkLabel, '$mark%'),
                if (quiz.attempts case final attempts?)
                  (l10n.staffQuizAttemptsLabel, l10n.quizAttemptsAllowed(attempts)),
                if (quiz.timeLimitMin case final limit?)
                  (l10n.staffQuizTimeLimitLabel, l10n.quizTimeLimit(limit)),
              ],
            ),
          ),
        ],
        if (detail.due case final due?) ...[
          const SizedBox(height: Space.sectionGap),
          header(
            l10n.calendarTypeAssignment,
            AppIcons.assignment,
            eventTypeHue(CalendarEventType.assignment),
          ),
          Text(l10n.calendarDueSummary(due.submitted, due.learners), style: context.type.bodyM),
          if (detail.learnersDue.isNotEmpty) ...[
            const SizedBox(height: Space.sectionGap),
            header(l10n.calendarLearnersDueTitle, AppIcons.people, Hue.green),
            GroupedList(
              children: [
                for (final learner in detail.learnersDue)
                  AppListTile(
                    title: learner.name,
                    leading: AvatarInitials(name: learner.name, size: AvatarSizes.sm),
                    trailing: learner.submitted
                        ? StatusBadge(StatusKind.submitted, labelOverride: l10n.calendarHandedIn)
                        : null,
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

/// The head of the page: what kind of event it is and where it stands, on a strip in its kind's
/// colour (a live class in its phase's), then its title and when it happens.
class _EventHeader extends StatelessWidget {
  const _EventHeader({required this.detail});

  final CalendarDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    final event = detail.event;
    final strip = eventStripColors(
      context,
      type: event.type,
      done: event.done,
      phase: detail.phase,
    );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: strip.soft,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.lg)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.s4, Space.s2, Space.s3, Space.s2),
              child: Row(
                children: [
                  AppIcon(eventTypeIcon(event.type), size: IconSizes.md, color: strip.solid),
                  const SizedBox(width: Space.s2),
                  Expanded(
                    child: Text(
                      eventTypeLabel(l10n, event.type),
                      style: type.caption.copyWith(color: strip.ink, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...switch ((detail.phase, event.done)) {
                    (final phase?, final done) => [
                      const SizedBox(width: Space.s2),
                      StatusBadge(livePhaseKind(phase)),
                      if (done) ...[
                        const SizedBox(width: Space.s1),
                        const StatusBadge(StatusKind.done),
                      ],
                    ],
                    (null, true) => [
                      const SizedBox(width: Space.s2),
                      const StatusBadge(StatusKind.done),
                    ],
                    _ => const <Widget>[],
                  },
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(header: true, child: Text(event.title, style: type.titleL)),
                const SizedBox(height: Space.s2),
                MetaItem(
                  icon: AppIcons.date,
                  label: event.timing == CalendarTiming.allDay
                      ? '${DatesIst.date(event.startsAt)} · ${l10n.calendarAllDay}'
                      : DatesIst.dateTime(l10n, event.startsAt),
                ),
                if (event.timing == CalendarTiming.timed && event.durationMin != null) ...[
                  const SizedBox(height: Space.s1),
                  MetaItem(
                    icon: AppIcons.duration,
                    label: AppDurations.minutes(l10n, event.durationMin!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
