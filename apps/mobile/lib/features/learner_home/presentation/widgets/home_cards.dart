import 'package:flutter/material.dart';

import '../../../../core/format/dates_ist.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../public_catalog/public_catalog.dart' show Course, coursePriceLabel;
import '../../application/learner_home_providers.dart';
import 'learner_widgets.dart';

/// The colourful 3D art for Home's shortcuts (assets/illustrations/, Fluent Emoji 3D, MIT).
abstract final class HomeArt {
  static const courses = 'assets/illustrations/courses.png';
  static const assignments = 'assets/illustrations/assignments.png';
  static const certificates = 'assets/illustrations/certificates.png';
  static const ranks = 'assets/illustrations/ranks.png';
}

/// A shortcut on Home: a 3D illustration on a tinted tile over a short label — a row of them
/// reads as a set of app shortcuts. One tap target.
class HomeShortcut extends StatelessWidget {
  const HomeShortcut({
    required this.label,
    required this.image,
    required this.hue,
    required this.onTap,
    super.key,
  });

  final String label;

  /// A [HomeArt] asset.
  final String image;
  final Hue hue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = context.colors.hue(hue);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: Space.s2),
          child: Column(
            children: [
              Container(
                width: AvatarSizes.lg,
                height: AvatarSizes.lg,
                decoration: BoxDecoration(
                  color: h.soft,
                  borderRadius: BorderRadius.circular(Radii.lg),
                  border: Border.all(color: h.solid.withValues(alpha: 0.18)),
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  image,
                  width: 40,
                  height: 40,
                  filterQuality: FilterQuality.medium,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(height: Space.s2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: context.type.caption.copyWith(
                  color: context.colors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small tinted label naming what something is ("Assignment", "Quiz").
class KindChip extends StatelessWidget {
  const KindChip({required this.label, required this.hue, super.key});

  final String label;
  final Hue hue;

  @override
  Widget build(BuildContext context) {
    final h = context.colors.hue(hue);
    return DecoratedBox(
      decoration: BoxDecoration(color: h.soft, borderRadius: BorderRadius.circular(Radii.xs)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: 3),
        child: Text(
          label,
          style: context.type.micro.copyWith(color: h.ink, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// The wide tinted bar at the foot of a card that says what tapping it does. The card itself is
/// the tap target, so this is drawn, not a second button.
class _CardCta extends StatelessWidget {
  const _CardCta({
    required this.label,
    required this.hue,
    this.enabled = true,
    this.outlined = false,
  });

  final String label;
  final Hue hue;
  final bool enabled;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final h = c.hue(hue);
    final ink = enabled ? h.ink : c.muted;
    return Container(
      constraints: const BoxConstraints(minHeight: Sizes.buttonSm + Space.s1),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: Space.s2),
      decoration: BoxDecoration(
        color: outlined ? null : (enabled ? h.soft : c.surface2),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: outlined ? Border.all(color: c.borderStrong) : null,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: context.type.bodyS.copyWith(
          color: outlined ? c.text : ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// One thing the learner has to do — an assignment or a quiz — as a card in Home's "To do"
/// carousel: what it is, how urgent the server says it is, the title, where it is from and when,
/// and what tapping it does. The flag is the server's; never colour alone (§19).
class TodoCard extends StatelessWidget {
  const TodoCard({required this.item, required this.onTap, super.key, this.now});

  final UpcomingItem item;
  final VoidCallback? onTap;

  /// Overridable so a test does not depend on the clock.
  final DateTime? now;

  static double width(BuildContext context) => homeCardWidth(context, 252);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final (kind, hue, cta, icon) = switch (item.kind) {
      UpcomingKind.assignment => (
        l10n.upcomingKindAssignment,
        Hue.orange,
        l10n.actionOpenAssignment,
        AppIcons.assignment,
      ),
      UpcomingKind.live => (l10n.upcomingKindLive, Hue.blue, l10n.navLive, AppIcons.live),
      UpcomingKind.quiz || UpcomingKind.unknown => (
        l10n.upcomingKindQuiz,
        Hue.violet,
        l10n.actionStartQuiz,
        AppIcons.quiz,
      ),
    };
    final when = item.kind == UpcomingKind.quiz && item.flag == null
        ? l10n.upcomingReadyNow
        : DatesIst.relative(l10n, item.at, now ?? DateTime.now());
    final status = upcomingStatus(item.flag);
    return SizedBox(
      width: width(context),
      child: Semantics(
        label: '$kind. ${item.title}. ${item.context}. $when',
        button: onTap != null,
        excludeSemantics: true,
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.all(Space.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  KindChip(label: kind, hue: hue),
                  const Spacer(),
                  if (status != null) StatusBadge(status),
                ],
              ),
              const SizedBox(height: Space.s3),
              Text(item.title, style: type.titleS, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: Space.s2),
              if (item.context.isNotEmpty) ...[
                MetaItem(icon: icon, label: item.context),
                const SizedBox(height: Space.s1),
              ],
              MetaItem(
                icon: AppIcons.time,
                label: when,
                color: item.flag == UpcomingFlag.overdue ? c.dangerInk : null,
              ),
              const SizedBox(height: Space.s3),
              _CardCta(label: cta, hue: hue, enabled: onTap != null),
            ],
          ),
        ),
      ),
    );
  }
}

/// A lesson the learner opened lately, as a small card: its type in its hue, the lesson, the
/// course, when — and a way back into it.
class RecentLessonCard extends StatelessWidget {
  const RecentLessonCard({required this.lesson, required this.onTap, super.key, this.now});

  final RecentLesson lesson;
  final VoidCallback onTap;
  final DateTime? now;

  static double width(BuildContext context) => homeCardWidth(context, 196);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final lessonType = LessonType.parse(lesson.type);
    final h = c.hue(lessonHue(lessonType));
    return SizedBox(
      width: width(context),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(Space.s3),
        semanticLabel: '${lesson.lessonTitle}. ${lesson.courseTitle}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: Sizes.iconTile,
                  height: Sizes.iconTile,
                  decoration: BoxDecoration(
                    color: h.soft,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  alignment: Alignment.center,
                  child: LessonTypeIcon(lessonType, size: IconSizes.md, color: h.solid),
                ),
                const SizedBox(width: Space.s2),
                Expanded(
                  child: Text(
                    lessonTypeLabel(l10n, lessonType),
                    style: type.micro.copyWith(color: h.ink, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.s3),
            Text(
              lesson.lessonTitle,
              style: type.bodyM.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              lesson.courseTitle,
              style: type.caption.copyWith(color: c.muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Space.s1),
            Text(
              DatesIst.relative(l10n, lesson.at, now ?? DateTime.now()),
              style: type.caption.copyWith(color: c.faint),
            ),
            const SizedBox(height: Space.s3),
            _CardCta(label: l10n.actionOpenLesson, hue: Hue.violet, outlined: true),
          ],
        ),
      ),
    );
  }
}

/// A catalogue course the learner does not hold yet, as a card in Home's "Discover" carousel:
/// cover, level, title, and the academy's own price. There is no list price or discount to show.
class DiscoverCourseCard extends StatelessWidget {
  const DiscoverCourseCard({
    required this.course,
    required this.levelName,
    required this.onTap,
    super.key,
  });

  final Course course;
  final String levelName;
  final VoidCallback onTap;

  static double width(BuildContext context) => homeCardWidth(context, 224);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final price = coursePriceLabel(l10n, course);
    return SizedBox(
      width: width(context),
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        semanticLabel: '${course.title}. $levelName. $price',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CourseCover(
              motif: CoverMotif.parse(course.coverMotif),
              imageUrl: course.coverImageUrl,
              radius: Radii.lg,
              aspectRatio: 16 / 9,
              topOnly: true,
            ),
            Padding(
              padding: const EdgeInsets.all(Space.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (levelName.isNotEmpty) ...[
                    Text(
                      levelName,
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
                    course.title,
                    style: type.titleS,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Space.s3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(price, style: type.titleM.copyWith(color: c.text)),
                      ),
                      Text(
                        l10n.actionViewCourse,
                        style: type.caption.copyWith(
                          color: c.accentInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AppIcon(AppIcons.chevronRight, size: IconSizes.sm, color: c.accentInk),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
