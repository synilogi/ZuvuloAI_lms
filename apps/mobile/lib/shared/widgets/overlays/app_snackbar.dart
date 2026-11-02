import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../icons/app_icons.dart';

enum SnackTone { success, info, error }

/// Shows a floating snackbar with an icon for its tone and an optional Undo (§22.5). Screen
/// readers announce it.
void showAppSnackbar(
  BuildContext context,
  String message, {
  SnackTone tone = SnackTone.info,
  VoidCallback? onUndo,
}) {
  final c = context.colors;
  final icon = switch (tone) {
    SnackTone.success => AppIcons.success,
    SnackTone.info => AppIcons.info,
    SnackTone.error => AppIcons.warning,
  };
  final iconColor = switch (tone) {
    SnackTone.success => c.accentSoft,
    SnackTone.info => c.surface,
    SnackTone.error => c.dangerSoft,
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: Duration(seconds: onUndo == null ? 4 : 6),
        content: Row(
          children: [
            AppIcon(icon, size: 20, color: iconColor),
            const SizedBox(width: Space.s3),
            Expanded(child: Text(message)),
          ],
        ),
        action: onUndo == null
            ? null
            : SnackBarAction(label: context.l10n.actionUndo, onPressed: onUndo),
      ),
    );
}
