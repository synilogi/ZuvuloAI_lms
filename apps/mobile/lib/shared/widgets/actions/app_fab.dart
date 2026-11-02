import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../icons/app_icons.dart';

/// Extended floating action button — used sparingly, for a screen's one creation action.
///
/// With [onPressed] null it is drawn disabled; [disabledReason] then says why — as its tooltip and
/// in what a screen reader announces — so a creation the plan does not allow is explained, not hidden.
class AppFab extends StatelessWidget {
  const AppFab({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
    this.disabledReason,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    final background = enabled ? c.accent : c.surface3;
    final foreground = enabled ? c.onAccent : c.muted;
    final fab = FloatingActionButton.extended(
      // Pages in one tab replace each other; a shared default tag would fly one FAB into the next.
      heroTag: null,
      onPressed: onPressed,
      backgroundColor: background,
      foregroundColor: foreground,
      disabledElevation: 0,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
      icon: AppIcon(icon, color: foreground),
      label: Text(label, style: context.type.label.copyWith(color: foreground)),
    );
    final reason = disabledReason;
    if (enabled || reason == null) return fab;
    return Tooltip(
      message: reason,
      triggerMode: TooltipTriggerMode.tap,
      child: Semantics(hint: reason, child: fab),
    );
  }
}

/// A list page with its one creation action floating at the bottom end, the same place on every
/// page. [body] should leave [FabLayout.clearance] of space at its end so the last row can scroll
/// clear of the button.
class FabLayout extends StatelessWidget {
  const FabLayout({required this.body, super.key, this.fab});

  final Widget body;
  final Widget? fab;

  /// Bottom padding a scrolling body needs so nothing hides behind the button.
  static const double clearance = 88;

  @override
  Widget build(BuildContext context) {
    if (fab == null) return body;
    return Stack(
      children: [
        Positioned.fill(child: body),
        PositionedDirectional(end: Space.s4, bottom: Space.s4, child: fab!),
      ],
    );
  }
}
