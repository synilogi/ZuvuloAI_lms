import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../actions/app_button.dart';
import '../icons/app_icons.dart';

/// A confirmation dialog for consequential actions (§22.5): title, the consequences first, an
/// acknowledgement checkbox when [destructive], and — if [onConfirm] fails — the error shown in
/// the dialog with the dialog kept open. Pops `true` once [onConfirm] succeeds.
class AppDialog extends StatefulWidget {
  const AppDialog({
    required this.title,
    required this.confirmLabel,
    super.key,
    this.message,
    this.consequences = const [],
    this.destructive = false,
    this.acknowledgementLabel,
    this.onConfirm,
    this.body,
  });

  final String title;
  final String? message;

  /// What will happen, listed before the buttons.
  final List<String> consequences;
  final String confirmLabel;
  final bool destructive;

  /// Overrides the default "I understand this can't be undone".
  final String? acknowledgementLabel;

  /// Runs the action; return an error message to keep the dialog open, or null on success.
  final Future<String?> Function()? onConfirm;

  /// Extra content (a reason field, a date) below the consequences.
  final Widget? body;

  @override
  State<AppDialog> createState() => _AppDialogState();
}

class _AppDialogState extends State<AppDialog> {
  bool _acknowledged = false;
  bool _busy = false;
  String? _error;

  Future<void> _confirm() async {
    final action = widget.onConfirm;
    if (action == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await action();
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final canConfirm = !widget.destructive || _acknowledged;
    return AlertDialog(
      title: Semantics(header: true, child: Text(widget.title)),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null) Text(widget.message!, style: context.type.bodyM),
          for (final line in widget.consequences)
            Padding(
              padding: const EdgeInsets.only(top: Space.s2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: AppIcon(
                      widget.destructive ? AppIcons.warning : AppIcons.info,
                      size: 16,
                      color: widget.destructive ? c.dangerInk : c.muted,
                    ),
                  ),
                  const SizedBox(width: Space.s2),
                  Expanded(child: Text(line, style: context.type.bodyM)),
                ],
              ),
            ),
          if (widget.body != null) ...[const SizedBox(height: Space.s4), widget.body!],
          if (widget.destructive)
            Padding(
              padding: const EdgeInsets.only(top: Space.s3),
              child: CheckboxListTile(
                value: _acknowledged,
                onChanged: _busy ? null : (v) => setState(() => _acknowledged = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  widget.acknowledgementLabel ?? l10n.destructiveAcknowledge,
                  style: context.type.bodyM,
                ),
              ),
            ),
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Container(
                margin: const EdgeInsets.only(top: Space.s3),
                padding: const EdgeInsets.all(Space.s3),
                decoration: BoxDecoration(
                  color: c.dangerSoft,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(_error!, style: context.type.bodyM.copyWith(color: c.dangerInk)),
              ),
            ),
        ],
      ),
      actionsOverflowButtonSpacing: Space.s2,
      actions: [
        AppButton(
          label: l10n.actionCancel,
          variant: AppButtonVariant.tertiary,
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: widget.confirmLabel,
          variant: widget.destructive ? AppButtonVariant.destructive : AppButtonVariant.primary,
          busy: _busy,
          onPressed: canConfirm ? _confirm : null,
        ),
      ],
    );
  }
}

/// Shows an [AppDialog]; resolves `true` when confirmed (and [AppDialog.onConfirm] succeeded).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? message,
  List<String> consequences = const [],
  bool destructive = false,
  Future<String?> Function()? onConfirm,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: context.colors.scrim,
    builder: (_) => AppDialog(
      title: title,
      message: message,
      consequences: consequences,
      confirmLabel: confirmLabel,
      destructive: destructive,
      onConfirm: onConfirm,
    ),
  );
  return result ?? false;
}
