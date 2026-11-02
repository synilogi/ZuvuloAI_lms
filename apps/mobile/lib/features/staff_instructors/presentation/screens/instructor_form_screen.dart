import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../staff_courses/staff_courses.dart';
import '../../application/staff_instructors_controller.dart';
import '../widgets/instructor_parts.dart';

/// `/staff/instructors/invite` and `/staff/instructors/:instructorId/edit` — the whole instructor
/// record. Both routes take a **full** `InstructorInput`, so an edit opens on the record as the
/// academy holds it and sends every field back; a photo is never sent, because the app offers no
/// upload for one and sending nothing leaves the academy's own untouched (§18). A shell body.
class InstructorFormScreen extends ConsumerWidget {
  const InstructorFormScreen({super.key, this.instructorId});

  /// `null` while inviting someone new.
  final String? instructorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = instructorId;
    if (id == null) return const _Form(instructorId: null);

    // An edit cannot begin until the record is read: a field left out would read as cleared.
    return AsyncView<InstructorDetail>(
      value: ref.watch(instructorProvider(id)),
      onRetry: () => ref.invalidate(instructorProvider(id)),
      data: (_) => _Form(instructorId: id),
    );
  }
}

class _Form extends ConsumerWidget {
  const _Form({required this.instructorId});

  final String? instructorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final editing = instructorId != null;
    final form = ref.watch(instructorFormProvider(instructorId));
    final controller = ref.read(instructorFormProvider(instructorId).notifier);
    final action = ref.watch(instructorActionProvider);
    final actions = ref.read(instructorActionProvider.notifier);
    final gutter = WindowSize.of(context).isCompact ? Space.s4 : Space.gutterMedium;
    final courses = ref.watch(staffCoursesProvider).value?.rows ?? const [];
    final problems = instructorFormProblems(form);

    // What the person has filled in. The app's own reading of a field waits until it holds
    // something, so an empty form does not open in red; Send stays disabled until it is complete.
    final filled = <String, bool>{
      'name': form.name.trim().isNotEmpty,
      'title': form.title.trim().isNotEmpty,
      'email': form.email.trim().isNotEmpty,
      'bio': form.bio.trim().isNotEmpty,
      'phone': (form.phone ?? '').trim().isNotEmpty,
      'yearsTeaching': form.yearsTeaching != null,
      'expertise': form.expertise.isNotEmpty,
      'languages': form.languages.isNotEmpty,
    };

    /// The academy's words for a field when it has spoken, and the app's own reading otherwise.
    String? problemFor(String field, String own) =>
        action.messageFor(field) ??
        (problems.contains(field) && (filled[field] ?? true) ? own : null);

    Future<void> submit() async {
      final ok = editing
          ? await actions.save(instructorId!, form)
          : await actions.create(form) != null;
      if (!ok || !context.mounted) return;
      controller.saved();
      showAppSnackbar(
        context,
        editing
            ? l10n.instructorSaved
            : (form.status == InstructorStatus.invited
                  ? l10n.instructorInvited
                  : l10n.instructorSaved),
        tone: SnackTone.success,
      );
      GoRouter.of(
        context,
      ).go(editing ? AppRoutes.staffInstructor(instructorId!) : AppRoutes.staffInstructors);
    }

    return PopScope(
      canPop: !controller.dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !context.mounted) return;
        final leave = await showConfirmDialog(
          context,
          title: l10n.instructorFormLeaveTitle,
          message: l10n.instructorFormLeaveBody,
          confirmLabel: l10n.instructorFormLeaveAction,
        );
        if (leave && context.mounted) leavePage(context);
      },
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
              children: [
                if (action.failure case final failure? when action.issues.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.s4),
                    child: FormErrorSummary(
                      issues: [
                        FormIssue(
                          message: refusalKindOf(failure) == null
                              ? failure.message ?? l10n.stateErrorBody
                              : refusalMessage(
                                  l10n,
                                  refusalKindOf(failure)!,
                                  serverMessage: failure.message,
                                ),
                        ),
                      ],
                    ),
                  ),
                // The app bar names the form ("Invite an instructor", "Edit the instructor"), so the
                // body opens on its first group of fields.
                SectionHeader(
                  title: l10n.staffInstructorsFormWhoTitle,
                  icon: AppIcons.instructor,
                  iconColor: sectionHue(context, AppIcons.instructor),
                ),
                AppTextField(
                  label: l10n.instructorFormNameLabel,
                  initialValue: form.name,
                  required: true,
                  textCapitalization: TextCapitalization.words,
                  errorText: problemFor('name', l10n.instructorProblemName),
                  onChanged: controller.named,
                ),
                const SizedBox(height: Space.s3),
                AppTextField(
                  label: l10n.instructorFormTitleLabel,
                  hintText: l10n.instructorFormTitleHint,
                  initialValue: form.title,
                  required: true,
                  errorText: problemFor('title', l10n.instructorProblemTitle),
                  onChanged: controller.titled,
                ),
                const SizedBox(height: Space.s3),
                AppTextField(
                  label: l10n.instructorFormEmailLabel,
                  initialValue: form.email,
                  required: true,
                  keyboardType: TextInputType.emailAddress,
                  helperText: l10n.instructorFormEmailHelp,
                  errorText: problemFor('email', l10n.instructorProblemEmail),
                  onChanged: controller.emailed,
                ),
                const SizedBox(height: Space.s3),
                AppSelectField<InstructorStatus>(
                  label: l10n.instructorFormStatusLabel,
                  value: form.status,
                  onChanged: controller.asStatus,
                  options: [
                    SelectOption(InstructorStatus.invited, l10n.instructorFormStatusInvited),
                    SelectOption(InstructorStatus.active, l10n.instructorFormStatusActive),
                    SelectOption(InstructorStatus.inactive, l10n.instructorFormStatusInactive),
                  ],
                ),
                const SizedBox(height: Space.sectionGap),
                SectionHeader(
                  title: l10n.staffInstructorsFormProfileTitle,
                  icon: AppIcons.profile,
                  iconColor: sectionHue(context, AppIcons.calendar),
                ),
                AppTextField(
                  label: l10n.instructorFormBioLabel,
                  initialValue: form.bio,
                  minLines: 4,
                  maxLines: 8,
                  helperText: l10n.instructorFormBioHelp,
                  errorText: problemFor('bio', l10n.instructorProblemBio),
                  onChanged: controller.wrote,
                ),
                const SizedBox(height: Space.s3),
                AppTextField(
                  label: l10n.instructorFormCityLabel,
                  initialValue: form.city,
                  textCapitalization: TextCapitalization.words,
                  onChanged: controller.inCity,
                ),
                const SizedBox(height: Space.s3),
                AppTextField(
                  label: l10n.instructorFormPhoneLabel,
                  initialValue: form.phone ?? '',
                  keyboardType: TextInputType.phone,
                  errorText: problemFor('phone', l10n.instructorProblemPhone),
                  onChanged: (text) => controller.phoned(text.isEmpty ? null : text),
                ),
                const SizedBox(height: Space.s3),
                AppTextField(
                  label: l10n.instructorFormYearsLabel,
                  initialValue: form.yearsTeaching?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  errorText: problemFor('yearsTeaching', l10n.instructorProblemYears),
                  onChanged: (text) => controller.teaching(int.tryParse(text)),
                ),
                const SizedBox(height: Space.sectionGap),
                _TagEditor(
                  label: l10n.instructorFormExpertiseLabel,
                  hint: l10n.instructorFormExpertiseHint,
                  icon: AppIcons.rank,
                  hue: Hue.gold,
                  tags: form.expertise,
                  errorText: problemFor('expertise', l10n.instructorProblemExpertise),
                  onToggle: controller.toggleExpertise,
                ),
                const SizedBox(height: Space.sectionGap),
                _TagEditor(
                  label: l10n.instructorFormLanguagesLabel,
                  hint: l10n.instructorFormLanguagesHint,
                  icon: AppIcons.language,
                  hue: Hue.violet,
                  tags: form.languages,
                  errorText: problemFor('languages', l10n.instructorProblemLanguages),
                  onToggle: controller.toggleLanguage,
                ),
                if (courses.isNotEmpty) ...[
                  const SizedBox(height: Space.sectionGap),
                  SectionHeader(
                    title: l10n.instructorFormCoursesLabel,
                    icon: AppIcons.courses,
                    iconColor: sectionHue(context, AppIcons.courses),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.s2),
                    child: Text(
                      l10n.instructorFormCoursesHelp,
                      style: context.type.caption.copyWith(color: context.colors.muted),
                    ),
                  ),
                  GroupedList(
                    children: [
                      for (final course in courses)
                        AppSwitchRow(
                          title: course.title,
                          value: form.courseIds.contains(course.id),
                          onChanged: (_) => controller.toggleCourse(course.id),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: Space.s4),
                Text(
                  l10n.instructorFormNoPhoto,
                  style: context.type.caption.copyWith(color: context.colors.muted),
                ),
              ],
            ),
          ),
          StickyActionBar(
            primary: AppButton(
              label: editing ? l10n.instructorFormSaveAction : l10n.instructorFormInviteAction,
              busy: action.busy,
              // The academy has the last word; the app only stops offering what it knows is wrong.
              onPressed: problems.isEmpty ? submit : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// A list of short tags with a field to add one. Expertise and languages are both free text the
/// academy stores as given.
class _TagEditor extends StatefulWidget {
  const _TagEditor({
    required this.label,
    required this.hint,
    required this.icon,
    required this.hue,
    required this.tags,
    required this.onToggle,
    this.errorText,
  });

  final String label;
  final String hint;

  /// The section's mark and its hue, as the form's other sections have.
  final IconData icon;
  final Hue hue;
  final List<String> tags;
  final String? errorText;
  final void Function(String tag) onToggle;

  @override
  State<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<_TagEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final tag = _controller.text.trim();
    if (tag.isEmpty || widget.tags.contains(tag)) return;
    widget.onToggle(tag);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: widget.label,
          icon: widget.icon,
          iconColor: context.colors.hue(widget.hue).solid,
        ),
        if (widget.tags.isNotEmpty) ...[
          TagRow(tags: widget.tags, onRemove: widget.onToggle),
          const SizedBox(height: Space.s3),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                label: widget.hint,
                controller: _controller,
                errorText: widget.errorText,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: Space.s2),
            Padding(
              padding: const EdgeInsets.only(top: Space.s1),
              child: AppButton(
                label: l10n.instructorFormAddTag,
                variant: AppButtonVariant.secondary,
                onPressed: _add,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
