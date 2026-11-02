import 'package:flutter/material.dart';

import '../../../../core/format/durations.dart';
import '../../../../core/format/money.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/catalog_providers.dart';

/// How a course's format reads.
String courseFormatLabel(AppLocalizations l10n, CourseFormat format) => switch (format) {
  CourseFormat.selfPaced || CourseFormat.unknown => l10n.courseFormatSelfPaced,
  CourseFormat.cohort => l10n.courseFormatCohort,
  CourseFormat.hybrid => l10n.courseFormatHybrid,
};

/// A course's price by how it is joined: "Free", its price in whole rupees (all-inclusive), or "Not
/// open yet" when the academy has not decided — never a price nobody can pay.
String coursePriceLabel(AppLocalizations l10n, Course course) => switch (course.sale) {
  FreeCourseSale() => l10n.coursePriceFree,
  PaidCourseSale(:final price) => Money.formatMajor(price.amount, price.currency),
  UnavailableCourseSale() => l10n.coursePriceNotOpen,
};

/// One course in the catalogue, laid out like a shop shelf: the cover whole across the top (an
/// uploaded banner keeps its words), the level as a label, the title, what it holds, who teaches
/// it — then the price and the one button that opens it. The price is the academy's own; there is
/// no list price or discount to show. The whole card is also one tap target.
class CourseCard extends StatelessWidget {
  const CourseCard({
    required this.course,
    required this.levelName,
    required this.instructorNames,
    required this.onTap,
    super.key,
    this.enrolled = false,
  });

  final Course course;

  /// The signed-in learner is enrolled (Explore): the card says so and its button continues.
  final bool enrolled;

  /// The level's name from `/catalog/levels`; empty when the app has not read it yet.
  final String levelName;
  final List<String> instructorNames;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final lessons = course.lessons.length;
    final price = coursePriceLabel(l10n, course);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.s2),
      semanticLabel: '${course.title}. $levelName. ${l10n.courseLessonCount(lessons)}. $price',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The web's cover shape, so a banner made for it is shown whole, not cropped.
          CourseCover(
            motif: CoverMotif.parse(course.coverMotif),
            imageUrl: course.coverImageUrl,
            radius: Radii.md,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s2, Space.s3, Space.s2, Space.s1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (levelName.isNotEmpty) ...[
                  Text(
                    levelName,
                    style: type.caption.copyWith(color: c.accentInk, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: Space.s1),
                ],
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
                const SizedBox(height: Space.s2),
                Wrap(
                  spacing: Space.s3,
                  runSpacing: Space.s1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MetaItem(icon: AppIcons.lessonReading, label: l10n.courseLessonCount(lessons)),
                    if (course.durationMin > 0)
                      MetaItem(
                        icon: AppIcons.time,
                        label: AppDurations.minutes(l10n, course.durationMin),
                      ),
                    if (course.rating != null && course.ratingCount != null)
                      CourseRating(rating: course.rating!, count: course.ratingCount!),
                  ],
                ),
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
                const SizedBox(height: Space.s3),
                const AppDivider(),
                const SizedBox(height: Space.s3),
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
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(price, style: type.titleL.copyWith(color: c.accentInk)),
                          if (enrolled)
                            const StatusBadge(StatusKind.enrolled)
                          else if (course.previewCount > 0)
                            const StatusBadge(StatusKind.freePreview),
                        ],
                      ),
                      AppButton(
                        label: enrolled ? l10n.actionContinue : l10n.actionViewCourse,
                        variant: enrolled ? AppButtonVariant.secondary : AppButtonVariant.primary,
                        size: AppButtonSize.sm,
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

/// The academy's rating, shown only when the server sends one — it withholds ratings until its
/// own minimum count is met (`apps/api/src/routes/catalog.ts`), and the app never computes one.
class CourseRating extends StatelessWidget {
  const CourseRating({required this.rating, required this.count, super.key});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final value = rating.toStringAsFixed(1);
    return Semantics(
      label: l10n.courseRatingLabel(value, count),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AppIcons.rating, size: IconSizes.xs, color: c.warn),
          const SizedBox(width: Space.s1),
          Text(
            l10n.courseRatingSummary(value, count),
            style: context.type.caption.copyWith(color: c.muted),
          ),
        ],
      ),
    );
  }
}
