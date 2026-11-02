import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/auth.dart';
import '../../../staff_courses/staff_courses.dart';
import '../../../staff_dashboard/staff_dashboard.dart';
import '../../application/staff_live_controller.dart';
import '../widgets/live_parts.dart';

/// `/staff/live/new` and `/staff/live/:liveId/edit` — scheduling a class and saving one. The academy
/// validates it and counts it against the month's allowance; what this form checks is only enough to
/// keep the button honest, and every refusal shown is the academy's own (§18).
class LiveFormScreen extends ConsumerWidget {
  const LiveFormScreen({super.key, this.liveId});

  /// Null when scheduling a new class.
  final String? liveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = liveId;
    if (id == null) return const _Form(liveId: null);
    // An edit starts from the class as it stands, because a PATCH takes the whole object.
    return AsyncView<StaffLiveDetail>(
      value: ref.watch(staffLiveClassProvider(id)),
      onRetry: () => ref.invalidate(staffLiveClassProvider(id)),
      skeleton: const DelayedLoading(skeleton: SkeletonDetail()),
      notFound: NotFoundView(onBack: () => GoRouter.of(context).go(AppRoutes.staffLive)),
      data: (detail) => _Form(liveId: id, detail: detail),
    );
  }
}

class _Form extends ConsumerWidget {
  const _Form({required this.liveId, this.detail});

  final String? liveId;
  final StaffLiveDetail? detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;
    final form = ref.watch(liveFormProvider(liveId));
    final controller = ref.read(liveFormProvider(liveId).notifier);
    final action = ref.watch(liveActionProvider);
    final actions = ref.read(liveActionProvider.notifier);
    final now = liveNow(ref);
    final courses = ref.watch(staffCoursesProvider).value?.rows ?? const [];
    final profile = ref.watch(currentUserProvider);
    final admin = profile?.role == UserRole.admin;
    final instructors = ref.watch(dashboardInstructorsProvider).value ?? const [];
    final registered = detail?.attendeeTotal ?? 0;
    final problems = liveFormProblems(form, now: now, registered: registered);

    // Whatever the academy refused, field by field, in its own words.
    ref.listen(liveActionProvider, (previous, next) {
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
      if (liveId == null) {
        final created = await actions.create(form);
        if (created == null || !context.mounted) return;
        controller.saved();
        showAppSnackbar(context, l10n.staffLiveScheduled, tone: SnackTone.success);
        GoRouter.of(context).go(AppRoutes.staffLiveClass(created));
        return;
      }
      final ok = await actions.save(liveId!, form);
      if (!ok || !context.mounted) return;
      controller.saved();
      showAppSnackbar(context, l10n.staffLiveSaved, tone: SnackTone.success);
      GoRouter.of(context).go(AppRoutes.staffLiveClass(liveId!));
    }

    // The academy's own message about a field beats the app's own reading of it.
    String? issueFor(String field, String fallback) =>
        action.messageFor(field) ?? (problems.contains(field) ? fallback : null);

    Widget header(String title, IconData icon, Hue hue, {String? action, VoidCallback? onAction}) =>
        SectionHeader(
          title: title,
          icon: icon,
          iconColor: c.hue(hue).solid,
          actionLabel: action,
          onAction: onAction,
        );

    return PopScope(
      canPop: !controller.dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !context.mounted) return;
        final leave = await showConfirmDialog(
          context,
          title: l10n.staffLiveLeaveConfirmTitle,
          message: l10n.staffLiveLeaveConfirmBody,
          confirmLabel: l10n.staffLiveLeaveConfirmAction,
          destructive: true,
        );
        if (leave && context.mounted) leavePage(context);
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
        children: [
          // The page's name is in the app bar; the form opens on its first section.
          header(l10n.staffLiveFormSectionClass, AppIcons.live, Hue.pink),
          if (courses.isNotEmpty)
            AppSelectField<String>(
              label: l10n.staffLiveFormCourse,
              value: form.courseId.isEmpty ? null : form.courseId,
              errorText: action.messageFor('course'),
              onChanged: controller.inCourse,
              options: [for (final course in courses) SelectOption(course.id, course.title)],
            ),
          const SizedBox(height: Space.s3),
          AppTextField(
            label: l10n.staffLiveFormTitle,
            initialValue: form.title,
            maxLength: 160,
            required: true,
            errorText: action.messageFor('title'),
            onChanged: controller.titled,
          ),
          // An instructor hosts their own classes; an academy admin picks who does.
          if (admin && instructors.isNotEmpty) ...[
            const SizedBox(height: Space.s3),
            AppSelectField<String>(
              label: l10n.staffLiveFormInstructor,
              value: form.instructorId.isEmpty ? null : form.instructorId,
              errorText: action.messageFor('instructor'),
              onChanged: controller.hostedBy,
              options: [
                for (final instructor in instructors) SelectOption(instructor.id, instructor.name),
              ],
            ),
          ] else if (!admin && form.instructorId.isEmpty && instructors.isNotEmpty) ...[
            const SizedBox(height: Space.s3),
            AppSelectField<String>(
              label: l10n.staffLiveFormInstructor,
              value: null,
              errorText: action.messageFor('instructor'),
              onChanged: controller.hostedBy,
              options: [
                for (final instructor in instructors) SelectOption(instructor.id, instructor.name),
              ],
            ),
          ],
          const SizedBox(height: Space.sectionGap),
          header(l10n.staffLiveFormSectionWhen, AppIcons.date, Hue.blue),
          AppDateTimeField(
            label: l10n.staffLiveFormStart,
            value: form.startsAt,
            // The field reads an IST wall clock and reports the UTC instant the route stores (§21).
            format: (instant) => DatesIst.dateTime(l10n, instant),
            firstDate: now,
            errorText: issueFor('startsAt', l10n.staffLiveStartInPast),
            onChanged: controller.startingAt,
          ),
          const SizedBox(height: Space.s3),
          AppTextField(
            label: l10n.staffLiveFormDuration,
            helperText: l10n.staffLiveFormDurationHelp(
              LiveClassForm.minDuration,
              LiveClassForm.maxDuration,
            ),
            initialValue: '${form.durationMin}',
            keyboardType: TextInputType.number,
            errorText: action.messageFor('duration'),
            onChanged: (text) => controller.lasting(int.tryParse(text.trim()) ?? 0),
          ),
          const SizedBox(height: Space.s3),
          AppTextField(
            label: l10n.staffLiveFormCapacity,
            initialValue: form.capacity == null ? '' : '${form.capacity}',
            keyboardType: TextInputType.number,
            errorText: action.messageFor('capacity'),
            onChanged: (text) => controller.seating(int.tryParse(text.trim())),
          ),
          const SizedBox(height: Space.sectionGap),
          header(l10n.staffLiveFormSectionWhere, AppIcons.lessonLive, Hue.violet),
          AppSelectField<MeetingKind>(
            label: l10n.staffLiveFormMeetingKind,
            value: form.meetingKind == MeetingKind.external
                ? MeetingKind.external
                : MeetingKind.room,
            onChanged: controller.heldIn,
            options: [
              SelectOption(MeetingKind.room, l10n.staffLiveMeetingRoom),
              SelectOption(MeetingKind.external, l10n.staffLiveMeetingExternal),
            ],
          ),
          const SizedBox(height: Space.s3),
          if (form.meetingKind == MeetingKind.external) ...[
            AppTextField(
              label: l10n.staffLiveFormMeeting,
              helperText: l10n.staffLiveFormMeetingHelp,
              initialValue: form.meetingLink,
              keyboardType: TextInputType.url,
              errorText: action.messageFor('meeting'),
              onChanged: controller.meetingAt,
            ),
            const SizedBox(height: Space.s3),
          ],
          const SizedBox(height: Space.sectionGap - Space.s3),
          header(l10n.staffLiveFormSectionLearners, AppIcons.people, Hue.green),
          AppTextField(
            label: l10n.staffLiveFormDescription,
            initialValue: form.description,
            minLines: 3,
            maxLines: 8,
            maxLength: 5000,
            onChanged: controller.describedAs,
          ),
          const SizedBox(height: Space.s3),
          AppSelectField<LiveVisibility>(
            label: l10n.staffLiveFormVisibility,
            value: form.visibility,
            onChanged: controller.seenBy,
            options: [
              SelectOption(LiveVisibility.enrolled, l10n.staffLiveVisibilityEnrolled),
              SelectOption(LiveVisibility.cohort, l10n.staffLiveVisibilityCohort),
              SelectOption(LiveVisibility.public, l10n.staffLiveVisibilityPublic),
            ],
          ),
          const SizedBox(height: Space.sectionGap),
          header(
            l10n.staffLiveFormAgenda,
            AppIcons.list,
            Hue.orange,
            action: l10n.staffLiveFormAgendaAdd,
            onAction: controller.addAgendaItem,
          ),
          for (var i = 0; i < form.agenda.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: l10n.staffLiveFormAgendaItem,
                      initialValue: form.agenda[i].title,
                      maxLength: 200,
                      onChanged: (text) => controller.editAgendaItem(i, title: text),
                    ),
                  ),
                  const SizedBox(width: Space.s2),
                  SizedBox(
                    width: 96,
                    child: AppTextField(
                      label: l10n.staffLiveFormAgendaMinutes,
                      initialValue: '${form.agenda[i].minutes}',
                      keyboardType: TextInputType.number,
                      onChanged: (text) =>
                          controller.editAgendaItem(i, minutes: int.tryParse(text.trim()) ?? 0),
                    ),
                  ),
                  AppIconButton(
                    icon: AppIcons.delete,
                    label: l10n.staffLiveFormAgendaRemove,
                    onPressed: () => controller.removeAgendaItem(i),
                  ),
                ],
              ),
            ),
          if (problems.contains('agenda') || action.messageFor('agenda') != null)
            Text(
              action.messageFor('agenda') ?? l10n.staffLiveFormAgendaTooLong(form.agendaMinutes),
              style: context.type.caption.copyWith(color: c.dangerInk),
            ),
          const SizedBox(height: Space.sectionGap),
          header(l10n.staffLiveRemindersTitle, AppIcons.notifications, Hue.gold),
          ReminderChips(selected: form.reminders, onToggle: controller.toggleReminder),
          const SizedBox(height: Space.s5),
          AppButton(
            label: liveId == null ? l10n.staffLiveFormSchedule : l10n.staffLiveFormSave,
            busy: action.busy,
            expand: true,
            onPressed: problems.isEmpty ? submit : null,
          ),
        ],
      ),
    );
  }
}
