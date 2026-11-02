import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../containers/containers.dart';
import '../icons/app_icons.dart';
import '../status/progress.dart';
import 'lesson_widgets.dart';

/// A lesson's state as the server reports it — the tree never computes locks or completion.
enum LessonNodeState { locked, available, inProgress, completed }

@immutable
class CurriculumLessonNode {
  const CurriculumLessonNode({
    required this.id,
    required this.title,
    required this.type,
    required this.state,
    this.numberLabel,
    this.durationLabel,
    this.lockedReason,
    this.isCurrent = false,
  });

  final String id;
  final String title;
  final LessonType type;
  final LessonNodeState state;

  /// "2.3"
  final String? numberLabel;

  /// "12 min"
  final String? durationLabel;
  final String? lockedReason;
  final bool isCurrent;
}

@immutable
class CurriculumChapterNode {
  const CurriculumChapterNode({required this.id, required this.title, required this.lessons});

  final String id;
  final String title;
  final List<CurriculumLessonNode> lessons;

  int get completedCount => lessons.where((l) => l.state == LessonNodeState.completed).length;
}

/// Chapter → lesson list with state nodes (filled check, half ring, ring, dashed lock): shape
/// carries the state as well as colour. Chapters collapse; the current chapter starts open.
class CurriculumTree extends StatelessWidget {
  const CurriculumTree({
    required this.chapters,
    required this.onLessonTap,
    super.key,
    this.cards = false,
  });

  final List<CurriculumChapterNode> chapters;

  /// Called for any lesson, locked ones included (the player shows the lock reason).
  final ValueChanged<CurriculumLessonNode> onLessonTap;

  /// Each chapter as a card of its own — its number on a coloured tile, how far through it the
  /// learner is — the way a course page lists its chapters. Off, the tree is one flat list.
  final bool cards;

  /// The hues the chapters' number tiles take in turn.
  static const _hues = [Hue.violet, Hue.blue, Hue.green, Hue.orange, Hue.pink, Hue.gold];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < chapters.length; i++)
          if (cards)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s3),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.lg),
                  child: _ChapterSection(
                    chapter: chapters[i],
                    onLessonTap: onLessonTap,
                    number: i + 1,
                    hue: _hues[i % _hues.length],
                  ),
                ),
              ),
            )
          else
            _ChapterSection(chapter: chapters[i], onLessonTap: onLessonTap),
      ],
    );
  }
}

class _ChapterSection extends StatelessWidget {
  const _ChapterSection({required this.chapter, required this.onLessonTap, this.number, this.hue});

  final CurriculumChapterNode chapter;
  final ValueChanged<CurriculumLessonNode> onLessonTap;

  /// Set for a chapter drawn as a card: its number, on a tile of [hue].
  final int? number;
  final Hue? hue;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final total = chapter.lessons.length;
    final done = chapter.completedCount;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: chapter.lessons.any((l) => l.isCurrent),
        tilePadding: EdgeInsets.symmetric(
          horizontal: Space.s4,
          vertical: number == null ? 0 : Space.s1,
        ),
        childrenPadding: const EdgeInsets.only(bottom: Space.s2),
        iconColor: c.muted,
        collapsedIconColor: c.muted,
        leading: number == null || hue == null
            ? null
            : ExcludeSemantics(
                child: Container(
                  width: AvatarSizes.md + Space.s1,
                  height: AvatarSizes.md + Space.s1,
                  decoration: BoxDecoration(
                    color: c.hue(hue!).soft,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$number',
                    style: context.type.titleM.copyWith(color: c.hue(hue!).ink),
                  ),
                ),
              ),
        title: Semantics(
          label: l10n.curriculumChapterLabel(chapter.title, done, total),
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(chapter.title, style: context.type.titleS),
              const SizedBox(height: 2),
              Text(
                l10n.curriculumProgress(done, total),
                style: context.type.caption.copyWith(color: c.muted),
              ),
              if (number != null && total > 0) ...[
                const SizedBox(height: Space.s2),
                ProgressBar(value: done / total, height: 4),
              ],
            ],
          ),
        ),
        children: [
          for (final lesson in chapter.lessons)
            _LessonRow(lesson: lesson, onTap: () => onLessonTap(lesson)),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson, required this.onTap});

  final CurriculumLessonNode lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final locked = lesson.state == LessonNodeState.locked;
    final stateLabel = switch (lesson.state) {
      LessonNodeState.locked => l10n.statusLocked,
      LessonNodeState.available => l10n.statusNotStarted,
      LessonNodeState.inProgress => l10n.statusInProgress,
      LessonNodeState.completed => l10n.statusCompleted,
    };
    final meta = [lessonTypeLabel(l10n, lesson.type), ?lesson.durationLabel].join(' · ');
    return Semantics(
      button: true,
      selected: lesson.isCurrent,
      label: [
        ?lesson.numberLabel,
        lesson.title,
        meta,
        stateLabel,
        if (locked && lesson.lockedReason != null) lesson.lockedReason!,
      ].join(', '),
      excludeSemantics: true,
      child: Material(
        color: lesson.isCurrent ? c.accentSoft : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s2),
              child: Row(
                children: [
                  _StateNode(state: lesson.state),
                  const SizedBox(width: Space.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.numberLabel == null
                              ? lesson.title
                              : '${lesson.numberLabel}  ${lesson.title}',
                          style: context.type.bodyM.copyWith(
                            color: locked ? c.muted : c.text,
                            fontWeight: lesson.isCurrent ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            LessonTypeIcon(lesson.type, size: 14, color: c.muted),
                            const SizedBox(width: Space.s1),
                            Flexible(
                              child: Text(
                                meta,
                                style: context.type.caption.copyWith(color: c.muted),
                              ),
                            ),
                          ],
                        ),
                        if (locked && lesson.lockedReason != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              lesson.lockedReason!,
                              style: context.type.caption.copyWith(color: c.muted),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StateNode extends StatelessWidget {
  const _StateNode({required this.state});

  final LessonNodeState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox.square(
      dimension: 24,
      child: switch (state) {
        LessonNodeState.completed => DecoratedBox(
          decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
          child: Center(child: AppIcon(AppIcons.check, size: 14, color: c.onAccent)),
        ),
        LessonNodeState.inProgress => CustomPaint(painter: _HalfRingPainter(c.accent)),
        LessonNodeState.available => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: c.borderStrong, width: 2),
          ),
        ),
        LessonNodeState.locked => Center(child: AppIcon(AppIcons.lock, size: 18, color: c.faint)),
      },
    );
  }
}

class _HalfRingPainter extends CustomPainter {
  _HalfRingPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas
      ..drawCircle(rect.center, size.width / 2 - 1, ring)
      ..drawArc(rect.deflate(4), -1.5708, 3.1416, true, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HalfRingPainter old) => old.color != color;
}
