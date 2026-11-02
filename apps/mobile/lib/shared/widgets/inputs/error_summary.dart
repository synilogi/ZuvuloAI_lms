import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../icons/app_icons.dart';

/// One problem in a [FormErrorSummary]; tapping it focuses [focusNode].
class FormIssue {
  const FormIssue({required this.message, this.fieldLabel, this.focusNode});

  final String message;
  final String? fieldLabel;
  final FocusNode? focusNode;
}

/// The error list at the top of a long form (§16): announces itself, and each issue jumps to
/// its field.
class FormErrorSummary extends StatelessWidget {
  const FormErrorSummary({required this.issues, super.key});

  final List<FormIssue> issues;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Space.s4),
        decoration: BoxDecoration(
          color: c.dangerSoft,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: c.danger),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(AppIcons.warning, size: 20, color: c.dangerInk),
                const SizedBox(width: Space.s2),
                Expanded(
                  child: Text(
                    context.l10n.errorSummaryTitle(issues.length),
                    style: context.type.titleS.copyWith(color: c.dangerInk),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.s2),
            for (final issue in issues)
              InkWell(
                onTap: issue.focusNode?.requestFocus,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: Space.minTap),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      issue.fieldLabel == null
                          ? issue.message
                          : '${issue.fieldLabel}: ${issue.message}',
                      style: context.type.bodyM.copyWith(
                        color: c.dangerInk,
                        decoration: issue.focusNode == null ? null : TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
