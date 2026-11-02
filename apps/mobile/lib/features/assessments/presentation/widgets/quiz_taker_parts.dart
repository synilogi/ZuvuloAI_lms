import 'package:flutter/material.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/quiz.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/quiz_taker_controller.dart';

/// A moment the server named (a quiz opening or closing, a deadline, results released) on the
/// academy's clock, as every time in the app: "1 Nov 2026, 10:00 AM", plus "IST" when the phone is
/// in another zone.
String quizTime(AppLocalizations l10n, DateTime instant) => DatesIst.dateTime(l10n, instant);

/// Marks as the server counted them: whole numbers plain, a fraction to two places, a loss with
/// a minus sign.
String quizMarks(num marks) {
  final text = marks.abs().toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  return marks < 0 ? '\u2212$text' : text;
}

/// The countdown as a pill: calm, then amber from five minutes, red from one. It is a display —
/// the server's deadline decides everything — and a screen reader reads it as a sentence rather
/// than being told every second.
class QuizTimerChip extends StatelessWidget {
  const QuizTimerChip({required this.remaining, super.key});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final clock = AppDurations.clock(remaining.inSeconds);
    final (Color bg, Color ink) = remaining <= const Duration(minutes: 1)
        ? (c.dangerSoft, c.dangerInk)
        : remaining <= const Duration(minutes: 5)
        ? (c.warnSoft, c.warnInk)
        : (c.surface2, c.text);
    return Semantics(
      label: l10n.quizTimerSemantics(clock),
      excludeSemantics: true,
      child: _Pill(
        color: bg,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIcons.time, size: IconSizes.sm, color: ink),
            const SizedBox(width: Space.s1 + 2),
            Flexible(
              child: Text(
                // At 0:00 the notice under it says time is up; the chip only keeps the count.
                l10n.quizTimeLeft(clock),
                style: context.type.label.copyWith(
                  color: ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the answers stand against the server: answered on this phone is not the same as saved,
/// and the chip says which. A save that stopped offers to try again.
class QuizSaveChip extends StatelessWidget {
  const QuizSaveChip({required this.status, super.key, this.onRetry});

  final QuizSaveStatus status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final (String label, String hint, IconData icon, Color ink) = switch (status) {
      QuizSaveStatus.idle || QuizSaveStatus.saved => (
        l10n.quizSaveSaved,
        l10n.quizSaveSavedHint,
        AppIcons.success,
        c.accentInk,
      ),
      QuizSaveStatus.unsaved => (
        l10n.quizSaveUnsaved,
        l10n.quizSaveUnsavedHint,
        AppIcons.edit,
        c.muted,
      ),
      QuizSaveStatus.saving => (
        l10n.quizSaveSaving,
        l10n.quizSaveSavingHint,
        AppIcons.upload,
        c.muted,
      ),
      QuizSaveStatus.retrying => (
        l10n.quizSaveRetrying,
        l10n.quizSaveRetryingHint,
        AppIcons.offline,
        c.warnInk,
      ),
      QuizSaveStatus.failed => (
        l10n.quizSaveFailed,
        l10n.quizSaveFailedHint,
        AppIcons.warning,
        c.dangerInk,
      ),
    };
    final chip = Semantics(
      liveRegion: status == QuizSaveStatus.failed || status == QuizSaveStatus.retrying,
      label: hint,
      excludeSemantics: true,
      child: _Pill(
        color: c.surface2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: IconSizes.sm, color: ink),
            const SizedBox(width: Space.s1 + 2),
            Flexible(
              child: Text(label, style: context.type.caption.copyWith(color: ink)),
            ),
          ],
        ),
      ),
    );
    if (status != QuizSaveStatus.failed || onRetry == null) return chip;
    return Wrap(
      spacing: Space.s1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        chip,
        AppButton(
          label: l10n.actionRetry,
          variant: AppButtonVariant.tertiary,
          size: AppButtonSize.sm,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Radii.pill)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: Space.s1 + 2),
      child: child,
    ),
  );
}

/// Every question as a numbered button: filled when answered, outlined when not, ringed when on
/// screen. Each says as much to a screen reader.
class QuizPalette extends StatelessWidget {
  const QuizPalette({
    required this.questions,
    required this.state,
    required this.onSelect,
    super.key,
  });

  final List<LearnerQuizQuestion> questions;
  final QuizTakerState state;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Semantics(
      container: true,
      label: l10n.quizQuestionNavigator,
      child: Wrap(
        spacing: Space.s2,
        runSpacing: Space.s2,
        children: [
          for (var i = 0; i < questions.length; i++)
            Builder(
              builder: (context) {
                final answered = state.answered(questions[i]);
                final current = i == state.index;
                final status = !answered
                    ? l10n.quizUnansweredLabel
                    : state.savedOnServer(questions[i])
                    ? l10n.quizAnsweredLabel
                    : l10n.quizAnsweredNotSaved;
                return Semantics(
                  button: true,
                  selected: current,
                  label: current
                      ? l10n.quizPaletteCurrent(i + 1, status)
                      : l10n.quizPaletteItem(i + 1, status),
                  excludeSemantics: true,
                  child: Material(
                    color: answered ? c.accent : c.surface,
                    shape: CircleBorder(
                      side: BorderSide(
                        color: current ? c.text : (answered ? c.accent : c.borderStrong),
                        width: current ? 2.5 : 1,
                      ),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onSelect(i),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: Space.minTap,
                          minHeight: Space.minTap,
                        ),
                        // Sized to the number, at least a tap target: an unbounded Center would
                        // take the whole row and stack the palette one question per line.
                        child: Center(
                          widthFactor: 1,
                          heightFactor: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(Space.s1),
                            child: Text(
                              '${i + 1}',
                              style: context.type.label.copyWith(
                                color: answered ? c.onAccent : c.text,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// A notice in a tinted box: the offline state, negative marking, a refusal.
class QuizNotice extends StatelessWidget {
  const QuizNotice({required this.text, required this.icon, super.key, this.tone = Tone.info});

  final String text;
  final IconData icon;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors.tone(tone);
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.soft,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(icon, size: IconSizes.sm, color: colors.ink),
              const SizedBox(width: Space.s2),
              Expanded(
                child: Text(text, style: context.type.bodyS.copyWith(color: colors.ink)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
