import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import 'app_button.dart';

/// The bottom action bar for long forms and the lesson player: sits above the system inset,
/// lifted by a soft upward shadow (a hairline in dark mode), holding one primary action (and optionally a secondary) as an
/// [ActionPair].
class StickyActionBar extends StatelessWidget {
  const StickyActionBar({required this.primary, super.key, this.secondary, this.leading});

  final Widget primary;
  final Widget? secondary;

  /// Shown at the start of the bar, before the actions (a course's price).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Theme.of(context).brightness == Brightness.dark
            ? Border(top: BorderSide(color: context.colors.border))
            : null,
        boxShadow: Theme.of(context).brightness == Brightness.dark ? null : context.shadows.up,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s3),
          child: leading == null
              ? ActionPair(primary: primary, secondary: secondary)
              : Row(
                  children: [
                    leading!,
                    const SizedBox(width: Space.s4),
                    Expanded(
                      child: ActionPair(primary: primary, secondary: secondary),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Two actions of equal width: side by side (secondary first) when both labels fit on one line,
/// otherwise stacked with [primary] on top — so a long label is never squeezed onto three lines.
class ActionPair extends StatelessWidget {
  const ActionPair({required this.primary, super.key, this.secondary});

  final Widget primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final second = secondary;
        if (second == null) return Row(children: [Expanded(child: primary)]);
        if (!_fitSideBySide(context, constraints.maxWidth, second)) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primary,
              const SizedBox(height: Space.s2),
              second,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: second),
            const SizedBox(width: Space.s3),
            Expanded(child: primary),
          ],
        );
      },
    );
  }

  bool _fitSideBySide(BuildContext context, double width, Widget second) {
    final half = (width - Space.s3) / 2;
    for (final action in [primary, second]) {
      if (action is AppButton && action.naturalWidth(context) > half) return false;
    }
    return true;
  }
}
