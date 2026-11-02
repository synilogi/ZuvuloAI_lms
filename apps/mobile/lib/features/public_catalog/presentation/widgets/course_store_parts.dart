import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/catalog_providers.dart';
import 'course_card.dart';

/// The price as a course's bottom bar shows it, beside the way in: a quiet label over the amount.
/// The amount is the academy's own; there is no list price to strike through and no discount.
class PriceTag extends StatelessWidget {
  const PriceTag({required this.course, super.key});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = coursePriceLabel(l10n, course);
    return Semantics(
      label: '${l10n.coursePriceTagLabel}: $label',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.coursePriceTagLabel,
            style: context.type.caption.copyWith(color: context.colors.muted),
          ),
          Text(label, style: context.type.titleL.copyWith(color: context.colors.accentInk)),
        ],
      ),
    );
  }
}

/// What a course holds, counted from its own outline: videos, readings, documents, tests,
/// assignments, live classes, free previews and the certificate. A line with nothing behind it is
/// left out, and with nothing at all the card is.
class CourseIncludes extends StatelessWidget {
  const CourseIncludes({required this.course, super.key});

  final Course course;

  /// The lines, in the order a learner weighs them.
  static List<(IconData, String)> linesFor(AppLocalizations l10n, Course course) {
    int count(Set<String> types) => course.lessons.where((l) => types.contains(l.type)).length;
    final videos = count(const {'video'});
    final readings = count(const {'reading', 'practice'});
    final documents = count(const {'document'});
    final tests = count(const {'assessment'});
    final assignments = count(const {'assignment'});
    // The academy's own figure for live sessions when it sets one; otherwise the live lessons.
    final live = course.liveSessions > 0 ? course.liveSessions : count(const {'live'});
    final previews = course.previewCount;
    final certificate = course.certificateTitle;
    return [
      if (videos > 0) (AppIcons.lessonVideo, l10n.courseIncludesVideos(videos)),
      if (readings > 0) (AppIcons.lessonReading, l10n.courseIncludesReadings(readings)),
      if (documents > 0) (AppIcons.filePdf, l10n.courseIncludesDocuments(documents)),
      if (tests > 0) (AppIcons.quiz, l10n.courseIncludesTests(tests)),
      if (assignments > 0) (AppIcons.assignment, l10n.courseIncludesAssignments(assignments)),
      if (live > 0) (AppIcons.live, l10n.courseIncludesLive(live)),
      if (previews > 0) (AppIcons.play, l10n.courseIncludesPreviews(previews)),
      if (certificate != null && certificate.isNotEmpty)
        (AppIcons.certificate, l10n.courseIncludesCertificate(certificate)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final lines = linesFor(l10n, course);
    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.courseIncludesTitle),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (icon, label) in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.s2),
                  child: Row(
                    children: [
                      AppIcon(AppIcons.success, size: IconSizes.sm, color: c.accent),
                      const SizedBox(width: Space.s3),
                      Expanded(child: Text(label, style: context.type.bodyM)),
                      const SizedBox(width: Space.s2),
                      AppIcon(icon, size: IconSizes.sm, color: c.faint),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
