import 'package:flutter/material.dart';

import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/learner_home_providers.dart';

/// The hero: where the learner left off, laid out like a batch card — the course's own cover
/// across the top, the course as a coloured label, the lesson the server picked as the title, and
/// the progress beside the one button that resumes it. The lesson is the server's `next` — the
/// app never picks one.
class ContinueCard extends StatelessWidget {
  const ContinueCard({required this.course, required this.onResume, super.key});

  final LearnerCourse course;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final next = course.next;
    final started = course.progress.percent > 0;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(Radii.xl);
    // Beside the progress at the default size; under it once the text is large.
    final roomy = MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    final resume = AppButton(
      label: started ? l10n.actionResume : l10n.actionStart,
      icon: AppIcons.play,
      expand: !roomy,
      onPressed: onResume,
    );

    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: radius,
          border: dark ? Border.all(color: c.border) : null,
          boxShadow: dark ? null : context.shadows.e2,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  CourseCover(
                    motif: CoverMotif.parse(course.course.coverMotif),
                    imageUrl: course.course.coverImageUrl,
                    aspectRatio: 2.1,
                    radius: 0,
                  ),
                  Positioned(
                    left: Space.s3,
                    top: Space.s3,
                    child: _CoverChip(label: l10n.homeContinueTitle),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.course.title,
                      style: type.caption.copyWith(
                        color: c.hue(Hue.orange).ink,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Space.s1),
                    Text(
                      next?.title ?? course.course.title,
                      style: type.titleL,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (next != null) ...[
                      const SizedBox(height: Space.s2),
                      Row(
                        children: [
                          LessonTypeIcon(
                            LessonType.parse(next.type),
                            size: IconSizes.sm,
                            color: c.muted,
                          ),
                          const SizedBox(width: Space.s2 - 2),
                          Flexible(
                            child: Text(
                              l10n.lessonNumberAndLength(
                                next.lessonNumber,
                                AppDurations.minutes(l10n, next.durationMin),
                              ),
                              style: type.caption.copyWith(color: c.muted),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: Space.s3),
                    const AppDivider(),
                    const SizedBox(height: Space.s3),
                    Row(
                      children: [
                        ProgressRing(
                          value: course.progress.fraction,
                          size: AvatarSizes.md,
                          showLabel: false,
                        ),
                        const SizedBox(width: Space.s3),
                        // The figure large, what is left beneath it — read as one phrase.
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                label: l10n.progressPercentComplete(course.progress.percent),
                                excludeSemantics: true,
                                child: Text(
                                  '${course.progress.percent}%',
                                  style: type.titleL.copyWith(color: c.accentInk),
                                ),
                              ),
                              if (course.progress.remainingMin > 0)
                                Text(
                                  l10n.courseRemaining(
                                    AppDurations.minutes(l10n, course.progress.remainingMin),
                                  ),
                                  style: type.caption.copyWith(color: c.muted),
                                ),
                            ],
                          ),
                        ),
                        if (roomy) ...[const SizedBox(width: Space.s3), resume],
                      ],
                    ),
                    if (!roomy) ...[const SizedBox(height: Space.s3), resume],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A label laid over a cover photo: light text on the media scrim, legible on any image.
class _CoverChip extends StatelessWidget {
  const _CoverChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.scrim, borderRadius: BorderRadius.circular(Radii.pill)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.s3 - 2, vertical: 3),
        child: Text(
          label,
          style: context.type.micro.copyWith(color: c.mediaInk, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// One thing the learner has to do — an assignment or a quiz — as a row of Home's "To do" list
/// (or a live class, when the schedule itself could not be read). The flag is the server's; gold
/// for what is close, danger for what is late — never colour alone (§19).
class UpcomingRow extends StatelessWidget {
  const UpcomingRow({required this.item, required this.onTap, super.key, this.now});

  final UpcomingItem item;
  final VoidCallback? onTap;

  /// Overridable so a test does not depend on the clock.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (kind, icon, tone) = switch (item.kind) {
      UpcomingKind.live => (l10n.upcomingKindLive, AppIcons.live, Tone.info),
      UpcomingKind.assignment => (l10n.upcomingKindAssignment, AppIcons.assignment, Tone.warn),
      UpcomingKind.quiz ||
      UpcomingKind.unknown => (l10n.upcomingKindQuiz, AppIcons.quiz, Tone.accent),
    };
    final when = item.kind == UpcomingKind.quiz && item.flag == null
        ? l10n.upcomingReadyNow
        : DatesIst.relative(l10n, item.at, now ?? DateTime.now());
    final status = upcomingStatus(item.flag);
    return Semantics(
      label: '$kind. ${item.title}. ${item.context}. $when',
      button: onTap != null,
      excludeSemantics: true,
      child: AppListTile(
        title: item.title,
        subtitle: item.context.isEmpty ? kind : '$kind · ${item.context}',
        meta: when,
        leading: IconTile(icon: icon, tone: tone),
        trailing: status == null ? null : StatusBadge(status),
        showChevron: onTap != null,
        onTap: onTap,
      ),
    );
  }
}

/// The badge a server flag maps onto; no flag means nothing is urgent.
StatusKind? upcomingStatus(UpcomingFlag? flag) => switch (flag) {
  null || UpcomingFlag.unknown => null,
  UpcomingFlag.liveNow => StatusKind.live,
  UpcomingFlag.startingSoon => StatusKind.startingSoon,
  UpcomingFlag.overdue => StatusKind.overdue,
  UpcomingFlag.dueSoon => StatusKind.dueSoon,
};

/// One enrolled course as a card in the home carousel, laid out like a batch card: the cover
/// across the top, the level as a coloured label, the title, how far through it is and since when
/// — then the progress bar. [LearnerCourseRow] is the same course as a list row.
class LearnerCourseCard extends StatelessWidget {
  const LearnerCourseCard({
    required this.course,
    required this.onTap,
    super.key,
    this.expand = false,
  });

  /// Wide enough for a two-line title at the default text size; grows with it.
  static double width(BuildContext context) => homeCardWidth(context, 264);

  final LearnerCourse course;
  final VoidCallback onTap;

  /// Takes the width it is given (a list, My Courses) instead of the carousel's.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final status = enrolmentStatus(course.enrollment.status);
    final enrolledAt = course.enrollment.enrolledAt;
    final going = c.hue(Hue.green);
    final note = enrolmentNote(l10n, course.enrollment);
    return SizedBox(
      width: expand ? null : width(context),
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        semanticLabel:
            '${course.course.title}. ${l10n.progressPercentComplete(course.progress.percent)}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CourseCover(
              motif: CoverMotif.parse(course.course.coverMotif),
              imageUrl: course.course.coverImageUrl,
              radius: Radii.lg,
              aspectRatio: 16 / 9,
              topOnly: true,
            ),
            Padding(
              padding: const EdgeInsets.all(Space.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (course.levelTitle.isNotEmpty) ...[
                    Text(
                      course.levelTitle,
                      style: type.caption.copyWith(
                        color: c.hue(Hue.orange).ink,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    course.course.title,
                    style: type.titleS,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Space.s2),
                  MetaItem(
                    icon: AppIcons.lessonReading,
                    label: l10n.curriculumProgress(
                      course.progress.completed,
                      course.progress.total,
                    ),
                  ),
                  const SizedBox(height: Space.s2),
                  if (status != null)
                    Wrap(
                      spacing: Space.s2,
                      runSpacing: Space.s1,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusBadge(status),
                        if (note != null) Text(note, style: type.caption.copyWith(color: c.muted)),
                      ],
                    )
                  else ...[
                    // "● In progress | Enrolled 2 Oct 2026" — the server's enrolment, as read.
                    Row(
                      children: [
                        ExcludeSemantics(
                          child: Container(
                            width: Space.s2,
                            height: Space.s2,
                            decoration: BoxDecoration(color: going.solid, shape: BoxShape.circle),
                          ),
                        ),
                        const SizedBox(width: Space.s2 - 2),
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: l10n.statusInProgress,
                                  style: TextStyle(color: going.ink, fontWeight: FontWeight.w600),
                                ),
                                if (enrolledAt != null)
                                  TextSpan(
                                    text: '  |  ${l10n.homeEnrolledOn(DatesIst.date(enrolledAt))}',
                                  ),
                              ],
                            ),
                            style: type.caption.copyWith(color: c.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.s3),
                    Row(
                      children: [
                        Expanded(child: ProgressBar(value: course.progress.fraction)),
                        const SizedBox(width: Space.s2),
                        Text(
                          '${course.progress.percent}%',
                          style: type.caption.copyWith(
                            color: c.accentInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A home carousel card's width: [base] at the default text size, growing with it up to half
/// again, so a card keeps its lines rather than wrapping every word.
double homeCardWidth(BuildContext context, double base) =>
    base * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);

/// One enrolled course: cover, title, progress bar and what the server says is left. A paused or
/// expired enrolment carries its status instead of a call to action.
class LearnerCourseRow extends StatelessWidget {
  const LearnerCourseRow({required this.course, required this.onTap, super.key});

  final LearnerCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final status = enrolmentStatus(course.enrollment.status);
    final note = enrolmentNote(l10n, course.enrollment);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.s2),
      semanticLabel:
          '${course.course.title}. ${l10n.progressPercentComplete(course.progress.percent)}',
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: CourseCover(
              motif: CoverMotif.parse(course.course.coverMotif),
              imageUrl: course.course.coverImageUrl,
              radius: Radii.md,
              aspectRatio: 1,
            ),
          ),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: Space.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.course.title,
                    style: type.titleS,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Space.s1),
                  MetaItem(
                    icon: AppIcons.lessonReading,
                    label: l10n.curriculumProgress(
                      course.progress.completed,
                      course.progress.total,
                    ),
                  ),
                  const SizedBox(height: Space.s2),
                  if (status != null)
                    Row(
                      children: [
                        StatusBadge(status),
                        if (note != null) ...[
                          const SizedBox(width: Space.s2),
                          Expanded(
                            child: Text(
                              note,
                              style: type.caption.copyWith(color: c.muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(child: ProgressBar(value: course.progress.fraction)),
                        const SizedBox(width: Space.s2),
                        Text(
                          '${course.progress.percent}%',
                          style: type.caption.copyWith(
                            color: c.accentInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (course.progress.remainingMin > 0) ...[
                      const SizedBox(height: Space.s1),
                      Text(
                        l10n.courseRemaining(
                          AppDurations.minutes(l10n, course.progress.remainingMin),
                        ),
                        style: type.caption.copyWith(color: c.muted),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The badge an enrolment carries. An active one needs none — the progress bar says it.
StatusKind? enrolmentStatus(EnrollmentStatus status) => switch (status) {
  EnrollmentStatus.active || EnrollmentStatus.unknown => null,
  EnrollmentStatus.completed => StatusKind.completed,
  EnrollmentStatus.paused => StatusKind.paused,
  EnrollmentStatus.expired => StatusKind.expired,
};

/// What a paused or expired enrolment says, in the server's own terms.
String? enrolmentNote(AppLocalizations l10n, Enrollment enrollment) => switch (enrollment.status) {
  EnrollmentStatus.expired =>
    enrollment.expiresAt == null
        ? null
        : l10n.enrolmentExpiredOn(DatesIst.date(enrollment.expiresAt!)),
  EnrollmentStatus.paused => l10n.enrolmentPausedNote,
  _ => null,
};

/// A course the learner saved but has not enrolled in.
class SavedCourseRow extends StatelessWidget {
  const SavedCourseRow({required this.saved, required this.onTap, super.key});

  final SavedCourse saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.s2),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: CourseCover(
              motif: CoverMotif.parse(saved.course.coverMotif),
              imageUrl: saved.course.coverImageUrl,
              radius: Radii.md,
              aspectRatio: 1,
            ),
          ),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(saved.course.title, style: type.titleS, maxLines: 2),
                const SizedBox(height: Space.s1),
                Text(saved.levelTitle, style: type.caption.copyWith(color: c.muted)),
                if (saved.instructorNames.isNotEmpty) ...[
                  const SizedBox(height: Space.s1),
                  Text(
                    saved.instructorNames.join(' · '),
                    style: type.caption.copyWith(color: c.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// The seven days the server sent, labelled with their weekday and with today marked. `date` is
/// already an IST calendar day, so it is read at midday UTC — 17:30 IST, the same day whatever
/// the device's zone (§7, D-002-x).
List<StudyDay> studyWeek(List<StudyDayMinutes> week, {DateTime? today}) {
  final todayKey = DatesIst.queryDate(today ?? DateTime.now());
  return [
    for (final entry in week)
      StudyDay(
        label: entry.day == null
            ? entry.date
            : DatesIst.parts(
                DateTime.utc(entry.day!.year, entry.day!.month, entry.day!.day, 12),
              ).weekday,
        minutes: entry.minutes,
        isToday: entry.date == todayKey,
      ),
  ];
}
