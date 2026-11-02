import 'package:flutter/material.dart';

import '../../../../core/format/dates_ist.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../media/media.dart';
import '../../application/assignment_controller.dart';
import '../screens/assignments_screen.dart';

/// What the assignment is and where this learner stands with it: the course it belongs to, its
/// title, the badge, the deadline the **server** worked out for them, and the academy's late
/// policy when the deadline has gone (§26).
class AssignmentHeader extends StatelessWidget {
  const AssignmentHeader({required this.row, super.key, this.now});

  final LearnerAssignment row;

  /// Overridable so a test does not depend on the clock.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final a = row.assignment;
    final due = row.dueAt;
    final at = now ?? DateTime.now();
    final late = due != null && at.isAfter(due);
    return DetailHeader(
      icon: AppIcons.assignment,
      tone: late ? Tone.warn : Tone.accent,
      eyebrow: [row.courseTitle, ?row.chapterTitle].join(' · '),
      badge: switch (assignmentStateBadge(row)) {
        final status? => StatusBadge(status),
        null => null,
      },
      title: a.title,
      facts: [
        MetaItem(
          icon: AppIcons.date,
          label: due == null
              ? l10n.assignmentNoDeadline
              : l10n.assignmentDueOn(DatesIst.dateTime(l10n, due)),
          color: late ? c.warnInk : null,
        ),
        MetaItem(icon: AppIcons.check, label: l10n.assignmentTotalPoints(a.totalPoints)),
      ],
      footer: [
        if (late && row.canSubmit)
          Text(
            a.acceptsLate
                ? (a.latePenalty > 0
                      ? l10n.assignmentLateWarning(a.latePenalty)
                      : l10n.assignmentLateNoPenalty)
                : l10n.assignmentClosedNote,
            style: context.type.bodyS.copyWith(color: c.warnInk),
          ),
      ],
    );
  }
}

/// The brief, in the same small markup articles use.
class AssignmentBrief extends StatelessWidget {
  const AssignmentBrief({required this.instructions, super.key});

  final String instructions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: context.l10n.assignmentBriefTitle,
          icon: AppIcons.info,
          iconColor: context.colors.hue(Hue.violet).solid,
        ),
        ArticleBody(body: instructions),
      ],
    );
  }
}

/// The files the instructor attached. Media is authenticated, so a document opens in the app's
/// own viewer rather than a browser (§13).
class AssignmentAttachments extends StatelessWidget {
  const AssignmentAttachments({required this.attachments, required this.onOpen, super.key});

  final List<Attachment> attachments;
  final void Function(Attachment attachment) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.assignmentAttachmentsTitle,
          icon: AppIcons.file,
          iconColor: context.colors.hue(Hue.blue).solid,
        ),
        GroupedList(
          children: [
            for (final file in attachments)
              AppListTile(
                title: file.name,
                meta: l10n.assignmentAttachmentSize(file.sizeMb.toStringAsFixed(1)),
                leading: AppIcon(attachmentIcon(file), color: context.colors.muted),
                showChevron: true,
                onTap: file.id == null ? null : () => onOpen(file),
              ),
          ],
        ),
      ],
    );
  }
}

/// The icon for a file, from the same classification the upload rules use.
IconData attachmentIcon(Attachment file) =>
    switch (MediaRules.classify(fileName: file.name, mimeType: file.mime)?.kind) {
      MediaKind.document => AppIcons.filePdf,
      MediaKind.image => AppIcons.fileImage,
      _ => AppIcons.file,
    };

/// How the work is marked: the criteria and their points, with the scores filled in once it has
/// been graded. Without a rubric there is only the maximum and the pass mark.
class AssignmentRubric extends StatelessWidget {
  const AssignmentRubric({required this.assignment, super.key, this.review});

  final CourseAssignment assignment;

  /// The reviewer's per-criterion points, when they have been given.
  final Review? review;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final graded = review?.status == ReviewStatus.graded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.assignmentRubricTitle,
          icon: AppIcons.check,
          iconColor: context.colors.hue(Hue.green).solid,
        ),
        AppCard(
          child: KeyValueTable(
            rows: [
              for (final criterion in assignment.rubric)
                (
                  criterion.title,
                  graded && review!.scores[criterion.id] != null
                      ? l10n.assignmentCriterionScore(
                          pointsLabel(review!.scores[criterion.id]!),
                          criterion.points,
                        )
                      : l10n.assignmentRubricPoints(criterion.points),
                ),
              (l10n.assignmentPassMarkLabel, l10n.assignmentRubricPoints(assignment.passMark)),
              (l10n.assignmentTotalLabel, l10n.assignmentRubricPoints(assignment.totalPoints)),
            ],
          ),
        ),
      ],
    );
  }
}

/// The written answer, with the word count the server counts by. A limit is a real rule here:
/// `validateSubmission` refuses a longer answer.
class AssignmentTextArea extends StatefulWidget {
  const AssignmentTextArea({
    required this.initialText,
    required this.onChanged,
    super.key,
    this.wordLimit,
    this.label,
    this.errorText,
    this.enabled = true,
  });

  final String initialText;
  final ValueChanged<String> onChanged;
  final int? wordLimit;
  final String? label;
  final String? errorText;
  final bool enabled;

  @override
  State<AssignmentTextArea> createState() => _AssignmentTextAreaState();
}

class _AssignmentTextAreaState extends State<AssignmentTextArea> {
  late final _controller = TextEditingController(text: widget.initialText);
  late var _words = AssignmentWork(text: widget.initialText).wordCount;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final limit = widget.wordLimit;
    final over = limit != null && _words > limit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: widget.label ?? l10n.assignmentWorkTitle,
          controller: _controller,
          hintText: l10n.assignmentWorkHint,
          errorText: widget.errorText,
          enabled: widget.enabled,
          minLines: 5,
          maxLines: 12,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (value) {
            setState(() => _words = AssignmentWork(text: value).wordCount);
            widget.onChanged(value);
          },
        ),
        const SizedBox(height: Space.s1),
        Text(
          limit == null
              ? l10n.assignmentWordCount(_words)
              : l10n.assignmentWordLimit(_words, limit),
          style: context.type.caption.copyWith(
            color: over ? context.colors.dangerInk : context.colors.muted,
          ),
        ),
      ],
    );
  }
}

/// The files handed in: what is attached so far, and the uploader for the next one. A file is
/// sent back exactly as the media route returned it, so the server can see it is the learner's
/// own (§13, §18).
class AssignmentFilesArea extends StatelessWidget {
  const AssignmentFilesArea({
    required this.files,
    required this.onAdd,
    required this.onRemove,
    super.key,
    this.limit = AssignmentWork.maxSubmissionFiles,
    this.errorText,
  });

  final List<Attachment> files;
  final void Function(Attachment file) onAdd;
  final void Function(Attachment file) onRemove;
  final int limit;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.assignmentFilesTitle,
          icon: AppIcons.upload,
          iconColor: context.colors.hue(Hue.orange).solid,
        ),
        if (files.isEmpty)
          Text(
            l10n.assignmentNoFiles,
            style: context.type.bodyS.copyWith(color: context.colors.muted),
          )
        else
          for (final file in files)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s2),
              child: AppFilePickerTile(
                name: file.name,
                sizeLabel: l10n.assignmentAttachmentSize(file.sizeMb.toStringAsFixed(1)),
                kind: switch (MediaRules.classify(fileName: file.name, mimeType: file.mime)?.kind) {
                  MediaKind.document => PickedFileKind.pdf,
                  MediaKind.image => PickedFileKind.image,
                  _ => PickedFileKind.other,
                },
                onRemove: () => onRemove(file),
              ),
            ),
        const SizedBox(height: Space.s2),
        if (files.length < limit)
          MediaUploadTile(
            accept: const [MediaKind.document, MediaKind.image],
            onUploaded: (uploaded) => onAdd(
              Attachment(
                id: uploaded.id,
                name: uploaded.name,
                sizeMb: uploaded.sizeMb,
                url: uploaded.url,
                mime: uploaded.mime,
              ),
            ),
          ),
        const SizedBox(height: Space.s1),
        Text(
          errorText ?? l10n.assignmentFilesLimit(limit),
          style: context.type.caption.copyWith(
            color: errorText == null ? context.colors.muted : context.colors.dangerInk,
          ),
        ),
      ],
    );
  }
}

/// The birth details a chart hand-in carries. The academy takes them as one thing, so they are
/// asked for together.
class AssignmentChartForm extends StatefulWidget {
  const AssignmentChartForm({
    required this.initial,
    required this.onChanged,
    super.key,
    this.errorText,
  });

  final BirthDetails? initial;
  final ValueChanged<BirthDetails> onChanged;
  final String? errorText;

  @override
  State<AssignmentChartForm> createState() => _AssignmentChartFormState();
}

class _AssignmentChartFormState extends State<AssignmentChartForm> {
  late final BirthDetails _start = widget.initial ?? const BirthDetails();
  late final _controllers = <String, TextEditingController>{
    'label': TextEditingController(text: _start.label),
    'date': TextEditingController(text: _start.date),
    'time': TextEditingController(text: _start.time),
    'place': TextEditingController(text: _start.place),
    'lagna': TextEditingController(text: _start.lagna),
    'moonSign': TextEditingController(text: _start.moonSign),
    'nakshatra': TextEditingController(text: _start.nakshatra),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(
    BirthDetails(
      label: _controllers['label']!.text,
      date: _controllers['date']!.text,
      time: _controllers['time']!.text,
      place: _controllers['place']!.text,
      lagna: _controllers['lagna']!.text,
      moonSign: _controllers['moonSign']!.text,
      nakshatra: _controllers['nakshatra']!.text,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fields = <(String, String)>[
      ('label', l10n.assignmentChartLabel),
      ('date', l10n.assignmentChartDate),
      ('time', l10n.assignmentChartTime),
      ('place', l10n.assignmentChartPlace),
      ('lagna', l10n.assignmentChartLagna),
      ('moonSign', l10n.assignmentChartMoonSign),
      ('nakshatra', l10n.assignmentChartNakshatra),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.assignmentChartTitle),
        for (final (key, label) in fields)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s3),
            child: AppTextField(
              label: label,
              controller: _controllers[key],
              required: true,
              onChanged: (_) => _emit(),
            ),
          ),
        Text(
          widget.errorText ?? l10n.assignmentChartNote,
          style: context.type.caption.copyWith(
            color: widget.errorText == null ? context.colors.muted : context.colors.dangerInk,
          ),
        ),
      ],
    );
  }
}

/// Where the draft stands, in one quiet line that a screen reader announces as it changes.
class DraftStatusLine extends StatelessWidget {
  const DraftStatusLine({required this.state, super.key, this.now});

  final AssignmentWorkState state;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final (text, colour) = switch (state.status) {
      DraftStatus.saving => (l10n.assignmentDraftSaving, c.muted),
      DraftStatus.saved => (
        l10n.assignmentDraftSaved(
          state.savedAt == null
              ? ''
              : DatesIst.relative(l10n, state.savedAt!, now ?? DateTime.now()),
        ),
        c.muted,
      ),
      DraftStatus.failed => (l10n.assignmentDraftFailed, c.dangerInk),
      DraftStatus.offline => (l10n.assignmentDraftOffline, c.warnInk),
      DraftStatus.idle => (null, c.muted),
    };
    if (text == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Text(text, style: context.type.caption.copyWith(color: colour)),
    );
  }
}

/// What was handed in, once it has been: when, which attempt, and the work itself.
class SubmissionSummary extends StatelessWidget {
  const SubmissionSummary({
    required this.submission,
    required this.onOpenFile,
    super.key,
    this.title,
  });

  final Submission submission;
  final void Function(Attachment file) onOpenFile;

  /// The heading. It defaults to the learner's own wording; a reviewer reading someone else's work
  /// needs different words for the same thing (FLUTTER-020).
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final chart = submission.chart;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: title ?? l10n.assignmentSubmissionTitle,
          icon: AppIcons.upload,
          iconColor: context.colors.hue(Hue.orange).solid,
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.assignmentSubmittedOn(DatesIst.dateTime(l10n, submission.submittedAt)),
                      style: context.type.bodyM,
                    ),
                  ),
                  if (submission.late) const StatusBadge(StatusKind.late),
                ],
              ),
              const SizedBox(height: Space.s1),
              Text(
                l10n.assignmentAttemptNumber(submission.attempt),
                style: context.type.caption.copyWith(color: c.muted),
              ),
              if (submission.text?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: Space.s3),
                Text(submission.text!, style: context.type.bodyM),
              ],
              if (chart != null && !chart.isEmpty) ...[
                const SizedBox(height: Space.s3),
                KeyValueTable(
                  rows: [
                    (l10n.assignmentChartLabel, chart.label),
                    (l10n.assignmentChartDate, chart.date),
                    (l10n.assignmentChartTime, chart.time),
                    (l10n.assignmentChartPlace, chart.place),
                    (l10n.assignmentChartLagna, chart.lagna),
                    (l10n.assignmentChartMoonSign, chart.moonSign),
                    (l10n.assignmentChartNakshatra, chart.nakshatra),
                  ],
                ),
              ],
              for (final file in submission.files)
                AppListTile(
                  title: file.name,
                  meta: l10n.assignmentAttachmentSize(file.sizeMb.toStringAsFixed(1)),
                  leading: AppIcon(attachmentIcon(file), color: c.muted),
                  showChevron: true,
                  onTap: file.id == null ? null : () => onOpenFile(file),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The reviewer's verdict: the score once it is graded, and their feedback. A returned submission
/// says so instead of showing a score it has not really been given.
class ReviewPanel extends StatelessWidget {
  const ReviewPanel({required this.review, required this.assignment, super.key});

  final Review review;
  final CourseAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final score = review.gradedScore;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: review.isReturned ? l10n.assignmentReturnedTitle : l10n.assignmentReviewTitle,
          icon: AppIcons.rating,
          iconColor: context.colors.hue(Hue.gold).solid,
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (score != null) ...[
                Text(
                  l10n.assignmentScore(pointsLabel(score), assignment.totalPoints),
                  style: context.type.titleM.copyWith(
                    color: score >= assignment.passMark ? c.accentInk : c.dangerInk,
                  ),
                ),
                const SizedBox(height: Space.s1),
                Text(
                  l10n.assignmentPassMark(assignment.passMark),
                  style: context.type.caption.copyWith(color: c.muted),
                ),
              ] else if (!review.isReturned)
                Text(
                  l10n.assignmentAwaitingReview,
                  style: context.type.bodyM.copyWith(color: c.muted),
                ),
              if (review.feedback.trim().isNotEmpty) ...[
                const SizedBox(height: Space.s3),
                Text(
                  l10n.assignmentFeedbackTitle,
                  style: context.type.label.copyWith(color: c.muted),
                ),
                const SizedBox(height: Space.s1),
                Text(review.feedback, style: context.type.bodyM),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
