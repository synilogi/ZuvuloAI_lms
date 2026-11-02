import 'package:flutter/material.dart';

import '../../../../core/format/durations.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/catalog_providers.dart';
import 'course_card.dart';

/// One course in the signed-in Courses tab, laid out like a batch card on a store's shelf: the
/// cover whole across the top, the level as a coloured label beside how the course runs, the
/// title, what it holds and who teaches it, where the learner stands with it — then the price and
/// the one button that opens it. Every figure is the course's own; the price is the academy's, with
/// no list price or discount to show. The whole card is also one tap target.
class CourseBatchCard extends StatelessWidget {
  const CourseBatchCard({
    required this.course,
    required this.levelName,
    required this.instructorNames,
    required this.onTap,
    super.key,
    this.enrolled = false,
  });

  final Course course;

  /// The level's name from `/catalog/levels`; empty when the app has not read it yet.
  final String levelName;
  final List<String> instructorNames;
  final VoidCallback onTap;

  /// The signed-in learner is enrolled: the card says so and its button continues.
  final bool enrolled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final lessons = course.lessons.length;
    final price = coursePriceLabel(l10n, course);
    final previews = course.previewCount;
    final weeks = course.estimatedWeeks;
    final (dot, note) = enrolled
        ? (c.hue(Hue.green), l10n.statusEnrolled)
        : previews > 0
        ? (c.hue(Hue.blue), l10n.statusFreePreview)
        : (null, null);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      semanticLabel: [
        course.title,
        if (levelName.isNotEmpty) levelName,
        l10n.courseLessonCount(lessons),
        ?note,
        price,
      ].join('. '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The web's cover shape, so a banner made for it is shown whole, not cropped.
          CourseCover(
            motif: CoverMotif.parse(course.coverMotif),
            imageUrl: course.coverImageUrl,
            radius: Radii.lg,
            topOnly: true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        levelName,
                        style: type.bodyS.copyWith(
                          color: c.hue(Hue.orange).ink,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: Space.s2),
                    OutlinePill(label: courseFormatLabel(l10n, course.format)),
                  ],
                ),
                const SizedBox(height: Space.s1),
                Text(
                  course.title,
                  style: type.titleM,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (course.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    course.subtitle,
                    style: type.caption.copyWith(color: c.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: Space.s3),
                MetaItem(
                  icon: AppIcons.lessonReading,
                  label: [
                    l10n.courseLessonCount(lessons),
                    if (course.durationMin > 0) AppDurations.minutes(l10n, course.durationMin),
                  ].join(' · '),
                ),
                if (weeks != null && weeks > 0) ...[
                  const SizedBox(height: Space.s1),
                  MetaItem(icon: AppIcons.date, label: l10n.courseWeeks(weeks)),
                ],
                if (course.liveSessions > 0) ...[
                  const SizedBox(height: Space.s1),
                  MetaItem(
                    icon: AppIcons.live,
                    label: l10n.courseIncludesLive(course.liveSessions),
                  ),
                ],
                if (instructorNames.isNotEmpty) ...[
                  const SizedBox(height: Space.s2),
                  Row(
                    children: [
                      AvatarInitials(name: instructorNames.first, size: AvatarSizes.sm - Space.s2),
                      const SizedBox(width: Space.s2),
                      Expanded(
                        child: Text(
                          instructorNames.join(' · '),
                          style: type.caption.copyWith(color: c.text, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (note != null || (course.rating != null && course.ratingCount != null)) ...[
                  const SizedBox(height: Space.s2),
                  Wrap(
                    spacing: Space.s3,
                    runSpacing: Space.s1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (note != null && dot != null) _StatusDot(label: note, hue: dot),
                      if (course.rating != null && course.ratingCount != null)
                        CourseRating(rating: course.rating!, count: course.ratingCount!),
                    ],
                  ),
                ],
                const SizedBox(height: Space.s4),
                // Price on the left, the way in on the right; they stack at large text sizes. The
                // row takes the card's full width, or "space between" has no space to share.
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: Space.s3,
                    runSpacing: Space.s2,
                    children: [
                      Text(price, style: type.titleL.copyWith(color: c.text)),
                      AppButton(
                        label: enrolled ? l10n.actionContinue : l10n.actionViewCourse,
                        variant: enrolled ? AppButtonVariant.secondary : AppButtonVariant.primary,
                        onPressed: onTap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small outlined label in capitals: how a course runs ("SELF-PACED").
class OutlinePill extends StatelessWidget {
  const OutlinePill({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.xs),
        border: Border.all(color: c.borderStrong),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: 2),
        child: Text(
          label.toUpperCase(),
          style: context.type.micro.copyWith(
            color: c.text,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

/// "● Enrolled" — a coloured dot before a word, never the colour alone.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.label, required this.hue});

  final String label;
  final ToneColors hue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            width: Space.s2,
            height: Space.s2,
            decoration: BoxDecoration(color: hue.solid, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: Space.s2 - 2),
        Text(
          label,
          style: context.type.caption.copyWith(color: hue.ink, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
