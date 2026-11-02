import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../icons/app_icons.dart';

/// An icon-only button. [label] is required: it is the tooltip and the screen-reader name.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
    this.color,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  /// Optional count badge (e.g. unread notifications); hidden when null or zero.
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final glyph = AppIcon(icon, color: color ?? context.colors.text);
    final count = badgeCount ?? 0;
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: Space.minTap, minHeight: Space.minTap),
      icon: count > 0
          ? Badge(
              label: Text(count > 99 ? '99+' : '$count'),
              backgroundColor: context.colors.danger,
              textColor: context.colors.onAccent,
              child: glyph,
            )
          : glyph,
    );
  }
}
