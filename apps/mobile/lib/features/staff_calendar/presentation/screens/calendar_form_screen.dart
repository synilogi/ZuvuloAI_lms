import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/platform/clock.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../staff_courses/staff_courses.dart';
import '../../../staff_quizzes/staff_quizzes.dart';
import '../../application/staff_calendar_controller.dart';
import '../widgets/calendar_parts.dart';

/// `/staff/calendar/new` and `/staff/calendar/:eventId/edit`. A live class or an assignment deadline
/// is never written here — the academy refuses it, and the form does not offer the type either.
class CalendarFormScreen extends ConsumerWidget {
  const CalendarFormScreen({super.key, this.eventId});

  final String? eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = eventId;
    if (id == null) return const _Form(eventId: null);
    return AsyncView<CalendarDetail>(
      value: ref.watch(calendarEventProvider(id)),
      onRetry: () => ref.invalidate(calendarEventProvider(id)),
      skeleton: const DelayedLoading(skeleton: SkeletonDetail()),
      notFound: NotFoundView(onBack: () => GoRouter.of(context).go(AppRoutes.staffCalendar)),
      data: (detail) => _Form(eventId: id, detail: detail),
    );
  }
}

class _Form extends ConsumerWidget {
  const _Form({required this.eventId, this.detail});

  final String? eventId;
  final CalendarDetail? detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;
    final form = ref.watch(calendarFormProvider(eventId));
    final controller = ref.read(calendarFormProvider(eventId).notifier);
    final action = ref.watch(calendarActionProvider);
    final actions = ref.read(calendarActionProvider.notifier);
    final now = ref.watch(clockProvider)();
    final problems = calendarFormProblems(form, now: now);
    final courses = ref.watch(staffCoursesProvider).value?.rows ?? const [];
    final quizzes = ref.watch(staffQuizzesProvider).value?.rows ?? const [];
    final chapters = courses
        .where((course) => course.id == form.courseId)
        .expand((course) => course.chapters)
        .toList();

    // The academy refuses a change to a derived event; this screen should never have opened on one.
    if (detail != null && !detail!.editable) {
      return Padding(
        padding: EdgeInsets.all(gutter),
        child: StateLayout(
          icon: AppIcons.warning,
          tone: Tone.warn,
          title: l10n.calendarEditTitle,
          message: switch (detail!.event.type) {
            CalendarEventType.live => l10n.calendarNotEditableLive,
            CalendarEventType.assignment => l10n.calendarNotEditableAssignment,
            _ => l10n.calendarNotEditableOther,
          },
          actionLabel: l10n.actionBack,
          onAction: () => GoRouter.of(context).go(AppRoutes.staffEvent(eventId!)),
        ),
      );
    }

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
      actions.clearAnswer();
    });

    Future<void> submit() async {
      if (eventId == null) {
        final created = await actions.create(form);
        if (created == null || !context.mounted) return;
        controller.saved();
        showAppSnackbar(context, l10n.calendarAdded, tone: SnackTone.success);
        GoRouter.of(context).go(AppRoutes.staffEvent(created));
        return;
      }
      final ok = await actions.save(eventId!, form);
      if (!ok || !context.mounted) return;
      controller.saved();
      showAppSnackbar(context, l10n.calendarSaved, tone: SnackTone.success);
      GoRouter.of(context).go(AppRoutes.staffEvent(eventId!));
    }

    String? issueFor(String field, String fallback) =>
        action.messageFor(field) ?? (problems.contains(field) ? fallback : null);

    Widget header(String title, IconData icon, Hue hue) =>
        SectionHeader(title: title, icon: icon, iconColor: c.hue(hue).solid);

    final needsCourse =
        form.type == CalendarEventType.quiz ||
        form.type == CalendarEventType.milestone ||
        (form.type == CalendarEventType.reminder && form.audience == ReminderAudience.learners);

    // Who it is for and what it points at: only the fields its type and audience call for, in the
    // order they always had.
    final links = <Widget>[
      if (form.type == CalendarEventType.reminder) ...[
        AppSelectField<ReminderAudience>(
          label: l10n.calendarFormAudience,
          value: form.audience,
          onChanged: controller.seenBy,
          options: [
            SelectOption(ReminderAudience.me, l10n.calendarAudienceMe),
            SelectOption(ReminderAudience.learners, l10n.calendarAudienceLearners),
          ],
        ),
      ],
      if (needsCourse && courses.isNotEmpty) ...[
        AppSelectField<String>(
          label: l10n.calendarFormCourse,
          value: form.courseId,
          errorText: action.messageFor('course'),
          onChanged: controller.inCourse,
          options: [for (final course in courses) SelectOption(course.id, course.title)],
        ),
      ],
      if (form.type == CalendarEventType.quiz && quizzes.isNotEmpty) ...[
        AppSelectField<String>(
          label: l10n.calendarFormQuiz,
          value: form.quizId,
          errorText: action.messageFor('quiz'),
          onChanged: controller.forQuiz,
          options: [for (final row in quizzes) SelectOption(row.quiz.id, row.quiz.title)],
        ),
      ],
      if (form.type == CalendarEventType.milestone) ...[
        AppSelectField<MilestoneKind>(
          label: l10n.calendarFormMilestone,
          value: form.milestone,
          errorText: action.messageFor('milestone'),
          onChanged: controller.marking,
          options: [
            for (final kind in MilestoneKind.values)
              if (kind != MilestoneKind.unknown) SelectOption(kind, milestoneLabel(l10n, kind)),
          ],
        ),
        if (form.milestone == MilestoneKind.chapterRelease && chapters.isNotEmpty) ...[
          AppSelectField<String>(
            label: l10n.calendarFormChapter,
            value: form.chapterId,
            errorText: action.messageFor('chapter'),
            onChanged: controller.inChapter,
            options: [for (final chapter in chapters) SelectOption(chapter.id, chapter.title)],
          ),
        ],
      ],
    ];

    return PopScope(
      canPop: !controller.dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !context.mounted) return;
        final leave = await showConfirmDialog(
          context,
          title: l10n.calendarLeaveConfirmTitle,
          message: l10n.calendarLeaveConfirmBody,
          confirmLabel: l10n.calendarLeaveConfirmAction,
          destructive: true,
        );
        if (leave && context.mounted) leavePage(context);
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
        children: [
          // The page's name is in the app bar; the form opens on its first section.
          header(l10n.staffCalendarFormSectionEvent, AppIcons.calendar, Hue.blue),
          // Only the three types the calendar owns: a live class and a deadline live elsewhere.
          AppSelectField<CalendarEventType>(
            label: l10n.calendarFormType,
            value: form.type,
            errorText: action.messageFor('type'),
            onChanged: controller.ofType,
            options: [
              SelectOption(CalendarEventType.reminder, l10n.calendarTypeReminder),
              SelectOption(CalendarEventType.milestone, l10n.calendarTypeMilestone),
              SelectOption(CalendarEventType.quiz, l10n.calendarTypeQuiz),
            ],
          ),
          const SizedBox(height: Space.s3),
          AppTextField(
            label: l10n.calendarFormTitle,
            initialValue: form.title,
            maxLength: 160,
            required: true,
            errorText: action.messageFor('title'),
            onChanged: controller.titled,
          ),
          const SizedBox(height: Space.sectionGap),
          header(l10n.staffCalendarFormSectionWhen, AppIcons.date, Hue.pink),
          AppSelectField<CalendarTiming>(
            label: l10n.calendarFormTiming,
            value: form.timing,
            onChanged: controller.timed,
            options: [
              SelectOption(CalendarTiming.timed, l10n.calendarTimingTimed),
              SelectOption(CalendarTiming.moment, l10n.calendarTimingMoment),
              SelectOption(CalendarTiming.allDay, l10n.calendarTimingAllDay),
            ],
          ),
          const SizedBox(height: Space.s3),
          AppDateTimeField(
            label: form.timing == CalendarTiming.allDay
                ? l10n.calendarFormDay
                : l10n.calendarFormStart,
            value: form.startsAt,
            // The field reads an IST wall clock and reports the instant the route stores (§21).
            format: (instant) => form.timing == CalendarTiming.allDay
                ? DatesIst.date(instant)
                : DatesIst.dateTime(l10n, instant),
            includeTime: form.timing != CalendarTiming.allDay,
            errorText: issueFor(
              'startsAt',
              form.timing == CalendarTiming.allDay
                  ? l10n.calendarDayInPast
                  : l10n.calendarStartInPast,
            ),
            onChanged: controller.startingAt,
          ),
          if (form.timing == CalendarTiming.timed) ...[
            const SizedBox(height: Space.s3),
            AppTextField(
              label: l10n.calendarFormDuration,
              helperText: l10n.calendarFormDurationHelp(CalendarEventForm.minDuration),
              initialValue: '${form.durationMin}',
              keyboardType: TextInputType.number,
              errorText: action.messageFor('duration'),
              onChanged: (text) => controller.lasting(int.tryParse(text.trim()) ?? 0),
            ),
          ],
          if (links.isNotEmpty) ...[
            const SizedBox(height: Space.sectionGap),
            header(l10n.staffCalendarFormSectionLinks, AppIcons.people, Hue.green),
            for (var i = 0; i < links.length; i++) ...[
              if (i > 0) const SizedBox(height: Space.s3),
              links[i],
            ],
          ],
          const SizedBox(height: Space.sectionGap),
          header(l10n.staffCalendarFormSectionNotes, AppIcons.notifications, Hue.gold),
          AppSelectField<int>(
            label: l10n.calendarFormNotify,
            value: form.notifyMin ?? 0,
            onChanged: (minutes) => controller.notifying(minutes == 0 ? null : minutes),
            options: [
              SelectOption(0, l10n.calendarNotifyNone),
              for (final minutes in [10, 30, 60, 240, 1440])
                SelectOption(minutes, reminderLabelFor(l10n, minutes)),
            ],
          ),
          const SizedBox(height: Space.s3),
          AppTextField(
            label: l10n.calendarFormDescription,
            initialValue: form.description,
            minLines: 3,
            maxLines: 8,
            maxLength: 5000,
            onChanged: controller.describedAs,
          ),
          if (problems.contains('startsAt') && action.messageFor('startsAt') == null) ...[
            const SizedBox(height: Space.s2),
            Text(
              form.timing == CalendarTiming.allDay
                  ? l10n.calendarDayInPast
                  : l10n.calendarStartInPast,
              style: context.type.caption.copyWith(color: c.dangerInk),
            ),
          ],
          const SizedBox(height: Space.s5),
          AppButton(
            label: eventId == null ? l10n.calendarFormAdd : l10n.calendarFormSave,
            busy: action.busy,
            expand: true,
            onPressed: problems.isEmpty ? submit : null,
          ),
        ],
      ),
    );
  }
}
