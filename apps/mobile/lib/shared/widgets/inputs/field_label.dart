import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// A form field's name, set above its box rather than inside it: always visible, never a
/// placeholder (§19), and the same for text, date and select fields. The field it names merges
/// with it for assistive technology (see [LabelledField]).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.enabled = true, this.onTap});

  final String text;
  final bool enabled;

  /// What tapping the label does — the same as tapping its field, as a label does on the web.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = Padding(
      padding: const EdgeInsets.only(left: Space.s1, bottom: Space.s2),
      child: Text(
        text,
        style: context.type.bodyS.copyWith(
          color: enabled ? c.text : c.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    if (onTap == null || !enabled) return label;
    // The field itself is the accessible control; the label is only a larger place to tap it.
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: label);
  }
}

/// A [FieldLabel] over its field, read out as one: TalkBack announces "Email, edit box", not the
/// label and the box as two stops.
class LabelledField extends StatelessWidget {
  const LabelledField({
    required this.label,
    required this.child,
    super.key,
    this.enabled = true,
    this.onLabelTap,
  });

  final String label;
  final Widget child;
  final bool enabled;

  /// What tapping the label does: focus the text field, or open the picker.
  final VoidCallback? onLabelTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(label, enabled: enabled, onTap: onLabelTap),
          child,
        ],
      ),
    );
  }
}
