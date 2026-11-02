import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../icons/app_icons.dart';

/// One line of a scoring sheet, as the scorer draws it. Named apart from the domain's
/// `RubricCriterion` (`shared/domain/assignment.dart`) because a screen holds both: the academy's
/// rubric, and what this component needs to draw a stepper for it.
@immutable
class ScoringCriterion {
  const ScoringCriterion({
    required this.id,
    required this.title,
    required this.maxPoints,
    this.description,
  });

  final String id;
  final String title;
  final String? description;
  final num maxPoints;
}

/// Criterion steppers with a running total. The total shown is the sum of the scores entered —
/// the grade itself is validated and stored by the server (FLUTTER-020).
class RubricScorer extends StatelessWidget {
  const RubricScorer({
    required this.criteria,
    required this.scores,
    required this.onChanged,
    super.key,
    this.step = 1,
  });

  final List<ScoringCriterion> criteria;
  final Map<String, num> scores;
  final void Function(String criterionId, num score)? onChanged;
  final num step;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final format = NumberFormat('#,##0.##', Localizations.localeOf(context).toString());
    final total = criteria.fold<num>(0, (sum, cr) => sum + (scores[cr.id] ?? 0));
    final max = criteria.fold<num>(0, (sum, cr) => sum + cr.maxPoints);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final criterion in criteria)
          _CriterionRow(
            criterion: criterion,
            score: scores[criterion.id] ?? 0,
            step: step,
            format: format,
            onChanged: onChanged == null ? null : (v) => onChanged!(criterion.id, v),
          ),
        const SizedBox(height: Space.s2),
        Semantics(
          liveRegion: true,
          child: Text(
            l10n.rubricTotal(format.format(total), format.format(max)),
            textAlign: TextAlign.end,
            style: context.type.titleM.copyWith(color: c.accentInk),
          ),
        ),
      ],
    );
  }
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({
    required this.criterion,
    required this.score,
    required this.step,
    required this.format,
    required this.onChanged,
  });

  final ScoringCriterion criterion;
  final num score;
  final num step;
  final NumberFormat format;
  final ValueChanged<num>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final canDecrease = onChanged != null && score - step >= 0;
    final canIncrease = onChanged != null && score + step <= criterion.maxPoints;
    final scoreText = format.format(score);
    final maxText = format.format(criterion.maxPoints);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(criterion.title, style: context.type.titleS),
                if (criterion.description != null)
                  Text(criterion.description!, style: context.type.bodyS.copyWith(color: c.muted)),
              ],
            ),
          ),
          Semantics(
            label: l10n.rubricCriterionScore(criterion.title, scoreText, maxText),
            value: scoreText,
            increasedValue: canIncrease ? format.format(score + step) : null,
            decreasedValue: canDecrease ? format.format(score - step) : null,
            onIncrease: canIncrease ? () => onChanged!(score + step) : null,
            onDecrease: canDecrease ? () => onChanged!(score - step) : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.actionDecrease,
                  onPressed: canDecrease ? () => onChanged!(score - step) : null,
                  icon: AppIcon(AppIcons.remove, color: canDecrease ? c.text : c.faint),
                ),
                ExcludeSemantics(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 56),
                    child: Text(
                      '$scoreText / $maxText',
                      textAlign: TextAlign.center,
                      style: context.type.titleS,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.actionIncrease,
                  onPressed: canIncrease ? () => onChanged!(score + step) : null,
                  icon: AppIcon(AppIcons.add, color: canIncrease ? c.text : c.faint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
