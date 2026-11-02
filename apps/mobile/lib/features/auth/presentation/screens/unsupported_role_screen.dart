import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/session_controller.dart';

/// A platform super admin signed in: the app holds no token for them and points to the web (§6).
class UnsupportedRoleScreen extends ConsumerWidget {
  const UnsupportedRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      body: StateLayout(
        icon: AppIcons.lock,
        title: l10n.unsupportedRoleTitle,
        message: l10n.unsupportedRoleBody,
        actionLabel: l10n.actionBack,
        onAction: () => ref.read(sessionControllerProvider.notifier).signOut(),
      ),
    );
  }
}
