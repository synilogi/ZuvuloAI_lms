import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/course.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/lesson_controller.dart';

/// The lesson's own heading: type, number and place in the course, and its duration.
class LessonHeader extends StatelessWidget {
  const LessonHeader({required this.view, super.key});

  final LessonView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final lesson = view.lesson;
    final type0 = LessonType.parse(lesson.type);
    return DetailHeader(
      icon: lessonTypeIcon(type0),
      eyebrow: '${lessonTypeLabel(l10n, type0)} · ${view.number}',
      badge: Text(
        l10n.lessonPositionOf(view.position.oneBased, view.position.total),
        style: type.caption.copyWith(color: c.accentInk, fontWeight: FontWeight.w700),
      ),
      title: lesson.title,
      facts: [
        MetaItem(icon: AppIcons.time, label: AppDurations.minutes(l10n, lesson.durationMin)),
        if (view.lessonProgress?.completedAt case final completedAt?)
          MetaItem(
            icon: AppIcons.success,
            label: l10n.lessonCompletedOn(DatesIst.date(completedAt)),
            color: c.accentInk,
          ),
      ],
      footer: [
        if (lesson.description != null && lesson.description!.isNotEmpty)
          Text(lesson.description!, style: type.bodyM.copyWith(color: c.muted)),
      ],
    );
  }
}

/// The assignment a lesson delivers, with the way into it (FLUTTER-013 builds that screen).
class AssignmentSummaryCard extends StatelessWidget {
  const AssignmentSummaryCard({required this.summary, required this.onOpen, super.key});

  final LessonAssignmentSummary summary;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppIcon(AppIcons.assignment, color: c.accentInk),
              const SizedBox(width: Space.s2),
              Expanded(child: Text(l10n.assignmentSummaryTitle, style: context.type.titleS)),
              if (assignmentStatus(summary.state) case final status?) StatusBadge(status),
            ],
          ),
          const SizedBox(height: Space.s2),
          Text(summary.title, style: context.type.bodyM),
          if (summary.dueAt case final due?) ...[
            const SizedBox(height: Space.s1),
            Text(
              l10n.assignmentDueOn(DatesIst.date(due)),
              style: context.type.caption.copyWith(color: c.muted),
            ),
          ],
          const SizedBox(height: Space.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: l10n.actionOpenAssignment,
              variant: AppButtonVariant.secondary,
              onPressed: onOpen,
            ),
          ),
        ],
      ),
    );
  }
}

/// The badge for the server's own assignment state.
StatusKind? assignmentStatus(String state) => switch (state) {
  'not-started' => StatusKind.notStarted,
  'draft' => StatusKind.draftSaved,
  'submitted' => StatusKind.submitted,
  'under-review' => StatusKind.underReview,
  'graded' => StatusKind.graded,
  'overdue' => StatusKind.overdue,
  'closed' => StatusKind.closed,
  _ => null,
};

/// The live class a lesson delivers. Joining and the phase clock are FLUTTER-014.
class LiveSummaryCard extends StatelessWidget {
  const LiveSummaryCard({required this.live, super.key});

  final LiveContent live;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(AppIcons.live, color: c.accentInk),
              const SizedBox(width: Space.s2),
              Text(l10n.liveSummaryTitle, style: context.type.titleS),
            ],
          ),
          if (live.startsAt case final startsAt?) ...[
            const SizedBox(height: Space.s2),
            Text(l10n.liveStartsAt(DatesIst.dateTime(l10n, startsAt)), style: context.type.bodyM),
          ],
          if (live.durationMin > 0) ...[
            const SizedBox(height: Space.s1),
            Text(
              l10n.liveDuration(live.durationMin),
              style: context.type.caption.copyWith(color: c.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// The lesson's notes: typed here, stored on the server. A practice lesson completes on written
/// working, so this is the working area, not a nicety.
class LessonNotes extends ConsumerStatefulWidget {
  const LessonNotes({required this.lesson, required this.initialText, super.key});

  final LessonRef lesson;
  final String initialText;

  @override
  ConsumerState<LessonNotes> createState() => _LessonNotesState();
}

class _LessonNotesState extends ConsumerState<LessonNotes> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialText);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(lessonNoteProvider.notifier).load(widget.initialText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final note = ref.watch(lessonNoteProvider);
    final status = switch (note.status) {
      NoteStatus.saving => l10n.noteSaving,
      NoteStatus.saved =>
        note.savedAt == null ? null : l10n.noteSavedAt(DatesIst.time(note.savedAt!)),
      NoteStatus.failed => l10n.noteFailed,
      NoteStatus.idle => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.noteTitle),
        const SizedBox(height: Space.s2),
        AppTextField(
          label: l10n.noteTitle,
          hintText: l10n.noteHint,
          controller: _controller,
          minLines: 4,
          maxLines: 10,
          maxLength: NoteState.maxLength,
          onChanged: (text) => ref.read(lessonNoteProvider.notifier).edit(widget.lesson, text),
        ),
        const SizedBox(height: Space.s2),
        Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                // The field counts characters itself; this line only says how saving went.
                child: Text(
                  status ?? '',
                  style: context.type.caption.copyWith(
                    color: note.status == NoteStatus.failed ? c.dangerInk : c.muted,
                  ),
                ),
              ),
            ),
            AppButton(
              label: l10n.actionSave,
              variant: AppButtonVariant.secondary,
              busy: note.status == NoteStatus.saving,
              onPressed: () => ref.read(lessonNoteProvider.notifier).save(widget.lesson),
            ),
          ],
        ),
      ],
    );
  }
}
