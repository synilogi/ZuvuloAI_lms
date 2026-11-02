import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../actions/app_button.dart';
import '../icons/app_icons.dart';

/// The backend's `LessonType` (`packages/domain/src/catalog.ts`).
enum LessonType {
  video,
  reading,
  document,
  live,
  practice,
  assignment,
  assessment,
  unknown;

  static LessonType parse(String? value) =>
      LessonType.values.firstWhere((t) => t.name == value, orElse: () => LessonType.unknown);
}

String lessonTypeLabel(AppLocalizations l10n, LessonType type) => switch (type) {
  LessonType.video => l10n.lessonTypeVideo,
  LessonType.reading || LessonType.unknown => l10n.lessonTypeReading,
  LessonType.document => l10n.lessonTypeDocument,
  LessonType.live => l10n.lessonTypeLive,
  LessonType.practice => l10n.lessonTypePractice,
  LessonType.assignment => l10n.lessonTypeAssignment,
  LessonType.assessment => l10n.lessonTypeQuiz,
};

IconData lessonTypeIcon(LessonType type) => switch (type) {
  LessonType.video => AppIcons.lessonVideo,
  LessonType.reading || LessonType.unknown => AppIcons.lessonReading,
  LessonType.document => AppIcons.lessonDocument,
  LessonType.live => AppIcons.lessonLive,
  LessonType.practice => AppIcons.lessonPractice,
  LessonType.assignment => AppIcons.lessonAssignment,
  LessonType.assessment => AppIcons.lessonQuiz,
};

/// The hue a lesson's type is drawn in wherever lessons are listed (Home, a course's page), so a
/// video always reads blue and a reading violet. Paired with the type's icon, never alone.
Hue lessonHue(LessonType type) => switch (type) {
  LessonType.video => Hue.blue,
  LessonType.reading || LessonType.unknown => Hue.violet,
  LessonType.document => Hue.orange,
  LessonType.live => Hue.pink,
  LessonType.practice => Hue.green,
  LessonType.assignment => Hue.gold,
  LessonType.assessment => Hue.pink,
};

/// A lesson type's icon, labelled with the type's name.
class LessonTypeIcon extends StatelessWidget {
  const LessonTypeIcon(this.type, {super.key, this.size = 20, this.color});

  final LessonType type;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => AppIcon(
    lessonTypeIcon(type),
    size: size,
    color: color ?? context.colors.accentInk,
    semanticLabel: lessonTypeLabel(context.l10n, type),
  );
}

/// How the lesson player's primary action reads — decided by the server's completion rule.
sealed class CompletionAction {
  const CompletionAction();
}

/// The learner may mark the lesson complete now.
class CanComplete extends CompletionAction {
  const CanComplete();
}

/// Already complete.
class AlreadyComplete extends CompletionAction {
  const AlreadyComplete();
}

/// Not yet completable; [hint] is the rule in words ("Watch 80% to complete").
class CompletionHint extends CompletionAction {
  const CompletionHint(this.hint);

  final String hint;
}

/// Previous · Mark complete (or the rule's hint) · Next, pinned to the bottom of the player.
class LessonNavBar extends StatelessWidget {
  const LessonNavBar({
    required this.completion,
    super.key,
    this.onPrevious,
    this.onNext,
    this.onMarkComplete,
    this.busy = false,
  });

  final CompletionAction completion;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onMarkComplete;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final Widget centre = switch (completion) {
      CanComplete() => AppButton(
        label: l10n.actionMarkComplete,
        icon: AppIcons.check,
        busy: busy,
        onPressed: onMarkComplete,
        expand: true,
      ),
      AlreadyComplete() => AppButton(
        label: l10n.lessonCompleteAction,
        icon: AppIcons.success,
        variant: AppButtonVariant.secondary,
        onPressed: null,
        expand: true,
      ),
      CompletionHint(:final hint) => Semantics(
        liveRegion: true,
        child: Text(
          hint,
          textAlign: TextAlign.center,
          style: context.type.bodyS.copyWith(color: c.muted),
        ),
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: Space.s2),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.actionPrevious,
                onPressed: onPrevious,
                icon: AppIcon(AppIcons.back, color: onPrevious == null ? c.faint : c.text),
              ),
              Expanded(child: centre),
              IconButton(
                tooltip: l10n.actionNext,
                onPressed: onNext,
                icon: AppIcon(AppIcons.forward, color: onNext == null ? c.faint : c.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A short countdown or timing chip ("Starts in 12 min", "Closes today"); the caller formats
/// the text from server timestamps and re-renders on its own ticker.
class CountdownChip extends StatelessWidget {
  const CountdownChip({required this.label, super.key, this.tone = Tone.warn});

  final String label;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors.tone(tone);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: Space.s1),
        decoration: BoxDecoration(
          color: colors.soft,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIcons.time, size: 14, color: colors.ink),
            const SizedBox(width: Space.s1),
            Flexible(
              child: Text(
                label,
                style: context.type.caption.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
