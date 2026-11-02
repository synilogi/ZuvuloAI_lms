import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../icons/app_icons.dart';

/// Question kinds the learner quiz supports (FLUTTER-012).
enum QuestionKind { single, multiple, trueFalse, shortAnswer }

@immutable
class QuestionOption {
  const QuestionOption(this.id, this.label);

  final String id;
  final String label;
}

/// One question with large tappable answer cards. It holds no answer key and never shows
/// correctness — scoring is the server's (§18, F6).
class QuizQuestionCard extends StatelessWidget {
  const QuizQuestionCard({
    required this.number,
    required this.total,
    required this.prompt,
    required this.kind,
    super.key,
    this.options = const [],
    this.selectedIds = const {},
    this.textAnswer,
    this.onSelectionChanged,
    this.onTextChanged,
    this.note,
    this.enabled = true,
  });

  final int number;
  final int total;
  final String prompt;
  final QuestionKind kind;

  /// Choices for single/multiple; true/false supplies its own.
  final List<QuestionOption> options;
  final Set<String> selectedIds;
  final String? textAnswer;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final ValueChanged<String>? onTextChanged;

  /// A line under the prompt — what the question is worth, or what a wrong answer costs.
  final String? note;

  /// False once the answer can no longer change (time is up): shown, but not editable.
  final bool enabled;

  static const trueId = 'true';
  static const falseId = 'false';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    // A true/false question answers with the server's own option ids when it sent them — a quiz
    // built on the web may name them `<question>-true` — worded in this language.
    final choices = kind == QuestionKind.trueFalse
        ? options.isEmpty
              ? [QuestionOption(trueId, l10n.quizTrue), QuestionOption(falseId, l10n.quizFalse)]
              : [
                  for (final o in options)
                    QuestionOption(
                      o.id,
                      o.id == trueId || o.id.endsWith('-$trueId')
                          ? l10n.quizTrue
                          : o.id == falseId || o.id.endsWith('-$falseId')
                          ? l10n.quizFalse
                          : o.label,
                    ),
                ]
        : options;
    final multiple = kind == QuestionKind.multiple;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.quizQuestionCount(number, total),
          style: context.type.label.copyWith(color: c.muted),
        ),
        const SizedBox(height: Space.s2),
        Semantics(header: true, child: Text(prompt, style: context.type.titleM)),
        if (note case final note?) ...[
          const SizedBox(height: Space.s1),
          Text(note, style: context.type.caption.copyWith(color: c.muted)),
        ],
        const SizedBox(height: Space.s2),
        if (kind != QuestionKind.shortAnswer)
          Text(
            multiple ? l10n.quizChooseAll : l10n.quizChooseOne,
            style: context.type.bodyS.copyWith(color: c.muted),
          ),
        const SizedBox(height: Space.s3),
        if (kind == QuestionKind.shortAnswer)
          TextFormField(
            initialValue: textAnswer,
            onChanged: onTextChanged,
            readOnly: !enabled,
            minLines: 2,
            maxLines: 6,
            style: context.type.bodyM,
            decoration: InputDecoration(
              labelText: l10n.quizShortAnswerLabel,
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
          )
        else
          for (final option in choices)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s2),
              child: _AnswerCard(
                label: option.label,
                selected: selectedIds.contains(option.id),
                multiple: multiple,
                onTap: onSelectionChanged == null || !enabled
                    ? null
                    : () {
                        final next = {...selectedIds};
                        if (multiple) {
                          next.contains(option.id) ? next.remove(option.id) : next.add(option.id);
                        } else {
                          next
                            ..clear()
                            ..add(option.id);
                        }
                        onSelectionChanged!(next);
                      },
              ),
            ),
      ],
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.label,
    required this.selected,
    required this.multiple,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool multiple;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.md),
      side: BorderSide(color: selected ? c.accent : c.border, width: selected ? 2 : 1),
    );
    final Widget marker = multiple
        ? Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: selected ? c.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(Radii.xs),
              border: Border.all(color: selected ? c.accent : c.muted, width: 1.5),
            ),
            child: selected ? AppIcon(AppIcons.check, size: 14, color: c.onAccent) : null,
          )
        : Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? c.accent : c.muted, width: selected ? 6 : 1.5),
            ),
          );
    return Semantics(
      checked: multiple ? selected : null,
      inMutuallyExclusiveGroup: multiple ? null : true,
      selected: multiple ? null : selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? c.accentSoft : c.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
              child: Row(
                children: [
                  marker,
                  const SizedBox(width: Space.s3),
                  Expanded(child: Text(label, style: context.type.bodyM)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
