import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../icons/app_icons.dart';
import 'field_label.dart';

/// One choice in an [AppSelectField].
class SelectOption<T> {
  const SelectOption(this.value, this.label, {this.description});

  final T value;
  final String label;
  final String? description;
}

/// A field that opens a bottom sheet of options — the app's dropdown. Works at any text scale
/// and with long option labels, unlike a Material menu.
class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
    this.errorText,
    this.helperText,
  });

  final String label;
  final List<SelectOption<T>> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String? errorText;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final selected = options.where((o) => o.value == value).firstOrNull;
    final enabled = onChanged != null;
    return LabelledField(
      label: label,
      enabled: enabled,
      onLabelTap: enabled ? () => _open(context) : null,
      child: Semantics(
        button: true,
        enabled: enabled,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: enabled ? () => _open(context) : null,
          child: InputDecorator(
            isEmpty: selected == null,
            decoration: InputDecoration(
              errorText: errorText,
              helperText: helperText,
              enabled: enabled,
              suffixIcon: AppIcon(AppIcons.chevronDown, size: 20, color: context.colors.muted),
            ),
            child: Text(
              selected?.label ?? context.l10n.selectPlaceholder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.type.bodyM.copyWith(
                color: selected == null ? context.colors.muted : context.colors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<SelectOption<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SelectSheet<T>(title: label, options: options, selected: value),
    );
    if (picked != null) onChanged?.call(picked.value);
  }
}

/// The sheet body of an [AppSelectField]; pops with the chosen option.
class SelectSheet<T> extends StatelessWidget {
  const SelectSheet({required this.title, required this.options, super.key, this.selected});

  final String title;
  final List<SelectOption<T>> options;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s2),
          child: Semantics(header: true, child: Text(title, style: context.type.titleM)),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final option in options)
                ListTile(
                  minTileHeight: Space.minTap,
                  selected: option.value == selected,
                  selectedColor: context.colors.accentInk,
                  title: Text(option.label, style: context.type.bodyM),
                  subtitle: option.description == null
                      ? null
                      : Text(
                          option.description!,
                          style: context.type.bodyS.copyWith(color: context.colors.muted),
                        ),
                  trailing: option.value == selected
                      ? AppIcon(AppIcons.check, size: 20, color: context.colors.accent)
                      : null,
                  onTap: () => Navigator.of(context).pop(option),
                ),
            ],
          ),
        ),
        const SizedBox(height: Space.s4),
      ],
    );
  }
}

/// Filter or form fields laid out in equal columns: as many per line as fit at 150 dp each (two
/// on a phone), one per line at large text sizes. Replaces fixed-width wraps that left ragged
/// edges on phones.
class FieldRow extends StatelessWidget {
  const FieldRow({required this.children, super.key, this.minFieldWidth = 150});

  final List<Widget> children;
  final double minFieldWidth;

  @override
  Widget build(BuildContext context) {
    // Every field can be conditional; with none left there is nothing to lay out.
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
        final fit = ((constraints.maxWidth + Space.s3) / (minFieldWidth + Space.s3)).floor();
        final perLine = largeText ? 1 : fit.clamp(1, children.length);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var start = 0; start < children.length; start += perLine) ...[
              if (start > 0) const SizedBox(height: Space.s3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = start; i < start + perLine; i++) ...[
                    if (i > start) const SizedBox(width: Space.s3),
                    Expanded(child: i < children.length ? children[i] : const SizedBox.shrink()),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
