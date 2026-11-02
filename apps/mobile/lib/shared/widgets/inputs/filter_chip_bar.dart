import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// One chip in a [FilterChipBar]; [count] comes from the server's `counts`.
class FilterOption<T> {
  const FilterOption(this.value, this.label, {this.count});

  final T value;
  final String label;
  final int? count;
}

/// A horizontally scrolling row of single-choice chips with counts (status tabs, filters).
class FilterChipBar<T> extends StatelessWidget {
  const FilterChipBar({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: Space.s4),
  });

  final List<FilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (final option in options) ...[
            AppFilterChip(
              label: option.label,
              count: option.count,
              selected: option.value == selected,
              onTap: () => onSelected(option.value),
            ),
            const SizedBox(width: Space.s2),
          ],
        ],
      ),
    );
  }
}

/// One filter pill: selected is a solid accent fill. [FilterChipBar] is the single-choice row of
/// these; a multi-choice filter lays them out itself.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.count,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.onAccent : c.text;
    final shape = StadiumBorder(side: BorderSide(color: selected ? c.accent : c.border));
    // A 36 dp pill inside a 48 dp touch target (§19): the padding around the pill still answers.
    return Semantics(
      selected: selected,
      button: true,
      label: count == null ? label : '$label, $count',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.s1 + 2),
          child: AnimatedContainer(
            duration: context.reduceMotion ? Duration.zero : Motion.micro,
            curve: Motion.enter,
            decoration: ShapeDecoration(color: selected ? c.accent : c.surface, shape: shape),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onTap,
                child: Padding(
                  // label (20) + 2 × 8 = a 36 dp pill that still grows with the text size.
                  padding: const EdgeInsets.symmetric(horizontal: Space.s4 - 2, vertical: Space.s2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: context.type.label.copyWith(color: fg)),
                      if (count != null) ...[
                        const SizedBox(width: Space.s2 - 2),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.s1 + 2,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? c.onAccent.withValues(alpha: 0.2) : c.surface2,
                            borderRadius: BorderRadius.circular(Radii.pill),
                          ),
                          child: Text(
                            '$count',
                            textAlign: TextAlign.center,
                            style: context.type.caption.copyWith(
                              color: selected ? c.onAccent : c.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
