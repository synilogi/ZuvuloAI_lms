import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../icons/app_icons.dart';

/// A labelled switch row. A [lockedReason] shows the row as fixed (e.g. a notification channel
/// the server requires) with the reason as its subtitle and a lock icon.
class AppSwitchRow extends StatelessWidget {
  const AppSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
    this.subtitle,
    this.lockedReason,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? lockedReason;

  @override
  Widget build(BuildContext context) {
    final locked = lockedReason != null;
    final detail = lockedReason ?? subtitle;
    return SwitchListTile(
      value: value,
      onChanged: locked ? null : onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.s4),
      title: Text(title, style: context.type.titleS),
      subtitle: detail == null
          ? null
          : Text(detail, style: context.type.bodyS.copyWith(color: context.colors.muted)),
      secondary: locked ? AppIcon(AppIcons.lock, size: 20, color: context.colors.muted) : null,
    );
  }
}

/// A labelled checkbox row.
class AppCheckboxRow extends StatelessWidget {
  const AppCheckboxRow({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.s2),
      title: Text(title, style: context.type.bodyM),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: context.type.bodyS.copyWith(color: context.colors.muted)),
    );
  }
}

/// One option of an [AppRadioGroup].
class RadioOption<T> {
  const RadioOption(this.value, this.label, {this.description});

  final T value;
  final String label;
  final String? description;
}

/// A vertical group of radio rows with a visible group label.
class AppRadioGroup<T> extends StatelessWidget {
  const AppRadioGroup({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
    this.showLabel = true,
  });

  final String label;

  /// False when a section header above already says it; [label] still names the group for
  /// screen readers.
  final bool showLabel;
  final List<RadioOption<T>> options;
  final T? value;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      child: RadioGroup<T>(
        groupValue: value,
        onChanged: (v) {
          if (v != null) onChanged?.call(v);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLabel)
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.s4, Space.s2, Space.s4, Space.s1),
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    style: context.type.label.copyWith(color: context.colors.muted),
                  ),
                ),
              ),
            for (final option in options)
              RadioListTile<T>(
                value: option.value,
                enabled: onChanged != null,
                title: Text(option.label, style: context.type.bodyM),
                subtitle: option.description == null
                    ? null
                    : Text(
                        option.description!,
                        style: context.type.bodyS.copyWith(color: context.colors.muted),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
