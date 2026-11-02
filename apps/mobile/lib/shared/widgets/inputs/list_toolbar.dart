import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../actions/app_button.dart';
import '../icons/app_icons.dart';
import '../overlays/sheets.dart';

/// The head of a list page: the search box, a Filters button beside it, and the status chips
/// under both. The page's secondary narrowing (sort, course, instructor) lives in a sheet behind
/// the button rather than above the results, so the first rows are visible without scrolling; the
/// button counts the filters that are on, so a narrowed list says so.
class ListToolbar extends StatelessWidget {
  const ListToolbar({
    super.key,
    this.search,
    this.chips,
    this.filters,
    this.activeFilters = 0,
    this.onClearFilters,
  });

  /// Usually an [AppSearchField].
  final Widget? search;

  /// Usually a [FilterChipBar] of the list's views or statuses, with their counts.
  final Widget? chips;

  /// The sheet's fields. Built inside the sheet, so a field that watches a provider follows it
  /// while the sheet is open. Null means the page has nothing to narrow by but [chips].
  final WidgetBuilder? filters;

  /// How many of the sheet's filters are narrowing the list now.
  final int activeFilters;

  /// Puts every filter in the sheet back to its default; offered in the sheet while any is on.
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final filters = this.filters;
    final top = <Widget>[
      if (search != null) Expanded(child: search!),
      if (filters != null) ...[
        if (search != null) const SizedBox(width: Space.s2),
        FiltersButton(
          active: activeFilters,
          onPressed: () => showFilterSheet(context, builder: filters, onClear: onClearFilters),
        ),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (top.isNotEmpty) Row(children: top),
        if (top.isNotEmpty && chips != null) const SizedBox(height: Space.s3),
        ?chips,
      ],
    );
  }
}

/// A square button the height of a search field that opens a list's filters, marked with how many
/// are on.
class FiltersButton extends StatelessWidget {
  const FiltersButton({required this.active, required this.onPressed, super.key});

  final int active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final on = active > 0;
    final label = on ? l10n.filtersActiveCount(active) : l10n.actionFilters;
    final radius = BorderRadius.circular(Radii.md);
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: on ? c.accentSoft : c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: on ? c.accent : c.border),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: SizedBox.square(
              dimension: Sizes.searchField,
              child: Badge(
                isLabelVisible: on,
                label: Text('$active'),
                backgroundColor: c.accent,
                textColor: c.onAccent,
                offset: const Offset(6, -6),
                child: Center(
                  child: AppIcon(
                    AppIcons.filter,
                    size: IconSizes.md,
                    color: on ? c.accentInk : c.text,
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

/// A list's filters in a sheet: the fields, then Done and — while any is on — Clear filters. The
/// fields apply as they change, as they did above the list; Done only closes the sheet.
Future<void> showFilterSheet(
  BuildContext context, {
  required WidgetBuilder builder,
  VoidCallback? onClear,
}) {
  final l10n = context.l10n;
  return showAppBottomSheet<void>(
    context,
    builder: (sheetContext) => AppBottomSheet(
      title: l10n.actionFilters,
      footer: Row(
        children: [
          if (onClear != null) ...[
            Expanded(
              child: AppButton(
                label: l10n.actionClearFilters,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  onClear();
                  Navigator.of(sheetContext).pop();
                },
              ),
            ),
            const SizedBox(width: Space.s3),
          ],
          Expanded(
            child: AppButton(
              label: l10n.actionDone,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.s2),
        child: Builder(builder: builder),
      ),
    ),
  );
}

/// Previous · Page n of m · Next under a paged list. Nothing at all for a single page.
class PagerRow extends StatelessWidget {
  const PagerRow({required this.page, required this.pages, required this.onPage, super.key});

  /// The page shown now, from 1.
  final int page;
  final int pages;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (pages <= 1) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: Space.s2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppButton(
            label: l10n.actionPrevious,
            variant: AppButtonVariant.tertiary,
            onPressed: page > 1 ? () => onPage(page - 1) : null,
          ),
          Flexible(
            child: Text(
              l10n.pagerPageOf(page, pages),
              style: context.type.caption.copyWith(color: context.colors.muted),
              textAlign: TextAlign.center,
            ),
          ),
          AppButton(
            label: l10n.actionNext,
            variant: AppButtonVariant.tertiary,
            onPressed: page < pages ? () => onPage(page + 1) : null,
          ),
        ],
      ),
    );
  }
}
