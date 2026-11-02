import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../icons/app_icons.dart';
import 'field_label.dart';

/// A labelled text input: the label above a white, rounded box, an optional leading icon that
/// takes the accent while the field is focused, and an optional [hintText] showing what to type.
/// The label is always visible (never placeholder-only, §19); [errorText] carries a server issue
/// for this field, [validator] the client-side check that mirrors the route's schema (UX only).
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.label,
    super.key,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.helperText,
    this.errorText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscure = false,
    this.enabled = true,
    this.required = false,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.inputFormatters,
    this.prefixIcon,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? initialValue;
  final String? helperText;
  final String? errorText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  /// Password-style input with a show/hide toggle.
  final bool obscure;
  final bool enabled;

  /// Marks the label as required (text, not colour alone).
  final bool required;

  /// Shows a character counter when set.
  final int? maxLength;
  final int? minLines;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? prefixIcon;
  final TextCapitalization textCapitalization;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  /// The field's focus: the caller's, or one of its own so that tapping the label can focus it.
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = widget.required ? '${widget.label} · ${l10n.requiredFieldMarker}' : widget.label;
    final field = TextFormField(
      controller: widget.controller,
      focusNode: _focus,
      initialValue: widget.controller == null ? widget.initialValue : null,
      enabled: widget.enabled,
      obscureText: _hidden,
      enableSuggestions: !widget.obscure,
      autocorrect: !widget.obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      maxLength: widget.maxLength,
      minLines: widget.obscure ? 1 : widget.minLines,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      inputFormatters: widget.inputFormatters,
      textCapitalization: widget.textCapitalization,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: context.type.bodyM,
      decoration: InputDecoration(
        helperText: widget.helperText,
        errorText: widget.errorText,
        hintText: widget.hintText,
        // Coloured by the theme's prefixIconColor: muted, the accent when focused, danger on error.
        prefixIcon: widget.prefixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(start: Space.s1),
                child: AppIcon(widget.prefixIcon!, size: IconSizes.md),
              ),
        suffixIcon: widget.obscure
            ? IconButton(
                tooltip: _hidden ? l10n.actionShowPassword : l10n.actionHidePassword,
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: AppIcon(
                  _hidden ? AppIcons.eye : AppIcons.eyeOff,
                  size: 20,
                  color: context.colors.muted,
                ),
              )
            : null,
      ),
    );
    return LabelledField(
      label: label,
      enabled: widget.enabled,
      onLabelTap: _focus.requestFocus,
      child: field,
    );
  }
}
