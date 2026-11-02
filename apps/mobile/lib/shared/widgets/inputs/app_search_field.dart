import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../icons/app_icons.dart';

/// A search box with a clear button. [hintText] names what is searched ("Search students").
class AppSearchField extends StatefulWidget {
  const AppSearchField({required this.onChanged, super.key, this.hintText, this.initialValue});

  final ValueChanged<String> onChanged;
  final String? hintText;
  final String? initialValue;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hint = widget.hintText ?? l10n.searchHint;
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, value, _) => TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        style: context.type.bodyM,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: context.colors.surface2,
          semanticCounterText: '',
          isDense: true,
          constraints: const BoxConstraints(minHeight: Sizes.searchField),
          contentPadding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3 - 2),
          prefixIcon: AppIcon(AppIcons.search, color: context.colors.muted),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: l10n.actionClearSearch,
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                  icon: AppIcon(AppIcons.close, color: context.colors.muted),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.pill),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.pill),
            borderSide: BorderSide.none,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: Space.minTap - Space.s1),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.pill),
            borderSide: BorderSide(color: context.colors.accent, width: 2),
          ),
        ),
      ),
    );
  }
}

/// A search field that is a button: it looks like [AppSearchField] and opens the screen that
/// owns the search (Home → Explore) instead of searching in place.
class SearchLauncher extends StatelessWidget {
  const SearchLauncher({required this.hintText, required this.onTap, super.key});

  final String hintText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(Radii.pill);
    return Semantics(
      button: true,
      label: hintText,
      excludeSemantics: true,
      child: Material(
        color: c.surface2,
        shape: RoundedRectangleBorder(borderRadius: radius),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.searchField),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s2),
              child: Row(
                children: [
                  AppIcon(AppIcons.search, color: c.muted),
                  const SizedBox(width: Space.s3),
                  Expanded(
                    child: Text(
                      hintText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.type.bodyM.copyWith(color: c.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
