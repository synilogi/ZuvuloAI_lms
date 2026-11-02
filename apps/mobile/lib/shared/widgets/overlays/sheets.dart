import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../actions/app_button.dart';

/// Opens a modal sheet with the design system's shape, drag handle and scrim.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    showDragHandle: true,
    barrierColor: context.colors.scrim,
    builder: builder,
  );
}

/// A sheet body with a title, scrolling content and an optional footer.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({required this.title, required this.child, super.key, this.footer});

  final String title;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s3),
          child: Semantics(header: true, child: Text(title, style: context.type.titleM)),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Space.s4),
            child: child,
          ),
        ),
        if (footer != null)
          SafeArea(
            top: false,
            child: Padding(padding: const EdgeInsets.all(Space.s4), child: footer),
          )
        else
          const SizedBox(height: Space.s4),
      ],
    );
  }
}

/// Filters in a sheet with Reset and Apply; the caller owns the draft values.
class FilterSheet extends StatelessWidget {
  const FilterSheet({
    required this.title,
    required this.children,
    required this.onApply,
    required this.onReset,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onApply;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppBottomSheet(
      title: title,
      footer: Row(
        children: [
          Expanded(
            child: AppButton(
              label: l10n.actionReset,
              variant: AppButtonVariant.secondary,
              onPressed: onReset,
            ),
          ),
          const SizedBox(width: Space.s3),
          Expanded(
            child: AppButton(label: l10n.actionApply, onPressed: onApply),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final child in children) ...[child, const SizedBox(height: Space.s4)],
        ],
      ),
    );
  }
}
