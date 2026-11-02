import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../../entitlements/entitlements.dart';
import '../icons/app_icons.dart';

/// One destination in [AppNavBar].
@immutable
class AppNavDestination {
  const AppNavDestination({
    required this.icon,
    required this.label,
    this.access = ModuleAccess.open,
  });

  /// The destination's [AppIcons] glyph; [AppNavIcons] gives its line, filled and hue looks.
  final IconData icon;
  final String label;

  /// How the academy's plan opens it: a locked or read-only module keeps its badge.
  final ModuleAccess access;
}

/// The phone's bottom navigation: a surface with rounded top corners lifted off the page, each
/// destination a light line glyph and a quiet label while idle; selected, the filled glyph and a
/// bold label in the destination's own hue, on a rounded pill of its soft tint that grows in. The
/// glyph pops as it is chosen and the item presses in under a finger. Every animation is skipped
/// when the platform asks for reduced motion. Works in both themes: the hues carry their own dark
/// values, and in dark mode the bar is outlined rather than shadowed.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  /// The bar's content height, above the system's bottom inset.
  static const double height = 68;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    const radius = BorderRadius.vertical(top: Radius.circular(Radii.xxl));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: radius,
        border: dark ? Border(top: BorderSide(color: c.border)) : null,
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: c.text.withValues(alpha: 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s2),
            child: Row(
              children: [
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: _NavItem(
                      destination: destinations[i],
                      selected: i == selectedIndex,
                      position: i + 1,
                      count: destinations.length,
                      onTap: () => onDestinationSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.position,
    required this.count,
    required this.onTap,
  });

  final AppNavDestination destination;
  final bool selected;
  final int position;
  final int count;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  void _press(bool down) {
    if (_pressed != down) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final calm = MediaQuery.disableAnimationsOf(context);
    Duration d(int ms) => calm ? Duration.zero : Duration(milliseconds: ms);
    final glyph = AppNavIcons.of(widget.destination.icon);
    final h = c.hue(glyph.hue);
    final selected = widget.selected;
    final iconColor = selected ? h.solid : c.muted;
    // A module outside the plan says so to a screen reader too, as its badge does on screen.
    final hint = switch (widget.destination.access) {
      ModuleAccess.locked => ', ${context.l10n.navLockedHint}',
      ModuleAccess.readOnly => ', ${context.l10n.navReadOnlyHint}',
      _ => '',
    };

    Widget icon = IconTheme.merge(
      data: IconThemeData(color: iconColor),
      child: PlanAwareNavIcon(
        key: ValueKey(selected),
        icon: selected ? glyph.active : glyph.idle,
        access: widget.destination.access,
        size: IconSizes.lg,
      ),
    );
    icon = AnimatedSwitcher(
      duration: d(220),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: Tween<double>(begin: 0.7, end: 1).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: icon,
    );

    return Semantics(
      button: true,
      selected: selected,
      label: '${widget.destination.label}, tab ${widget.position} of ${widget.count}$hint',
      excludeSemantics: true,
      child: Tooltip(
        message: widget.destination.label,
        excludeFromSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _press(true),
          onTapUp: (_) => _press(false),
          onTapCancel: () => _press(false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1,
            duration: d(120),
            curve: Motion.enter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // The pill grows from the glyph's width to its full width as the tab is chosen.
                AnimatedContainer(
                  duration: d(260),
                  curve: Curves.easeOutCubic,
                  width: selected ? 60 : 40,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? h.soft : h.soft.withValues(alpha: 0),
                    borderRadius: BorderRadius.circular(Radii.pill),
                    border: Border.all(
                      color: selected
                          ? h.solid.withValues(alpha: 0.18)
                          : h.solid.withValues(alpha: 0),
                    ),
                  ),
                  child: icon,
                ),
                const SizedBox(height: Space.s1),
                AnimatedDefaultTextStyle(
                  duration: d(200),
                  style: type.micro.copyWith(
                    color: selected ? h.ink : c.muted,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                  child: Text(
                    widget.destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
