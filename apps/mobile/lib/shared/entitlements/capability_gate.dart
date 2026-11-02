import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/capabilities.dart';
import '../session/current_user.dart';

/// Shows [child] only to someone who holds [capability] (§7). UX only: the screen behind it still
/// handles the server's refusal, because a grant can be taken away between two calls.
///
/// [fallback] replaces the control when it should still occupy its place (a disabled button with a
/// reason); by default the control is simply not offered.
class CapabilityGate extends ConsumerWidget {
  const CapabilityGate({required this.capability, required this.child, super.key, this.fallback});

  final Capability capability;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = can(ref.watch(currentUserProvider), capability);
    return allowed ? child : (fallback ?? const SizedBox.shrink());
  }
}

/// Whether the signed-in person holds [capability] — for code that needs the answer, not a widget.
bool watchCan(WidgetRef ref, Capability capability) =>
    can(ref.watch(currentUserProvider), capability);
