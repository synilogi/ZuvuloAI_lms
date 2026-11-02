import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../l10n/l10n.dart';
import '../../entitlements/entitlement_refusal.dart';
import 'skeleton.dart';
import 'state_views.dart';

/// The failure behind [error], when the app produced one.
AppFailure? failureOf(Object error) => error is ApiException ? error.failure : null;

/// Renders one loaded value, the state view its refusal calls for, or a skeleton — the same three
/// states on every screen (§17). [notFound] is drawn for a 404, which is also how the API answers
/// "not yours to see" (§7).
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    required this.value,
    required this.data,
    required this.onRetry,
    super.key,
    this.skeleton,
    this.notFound,
    this.keepDataOnError = false,
  });

  final AsyncValue<T> value;
  final Widget Function(T value) data;
  final VoidCallback onRetry;

  /// What loading looks like; a delayed list skeleton by default.
  final Widget? skeleton;

  /// What a 404 looks like; the shared not-found view by default.
  final Widget? notFound;

  /// Whether a failed **re-read** keeps what was already on screen. A screen that reads itself again
  /// in the background (a poll) sets this, and says the refresh failed in its own way
  /// (`value.hasError`); only a first read with nothing to show draws the error state.
  final bool keepDataOnError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (keepDataOnError && value is AsyncError<T> && value.hasValue) {
      return data(value.value as T);
    }
    return switch (value) {
      AsyncData(:final value) => data(value),
      AsyncError(:final error) => switch (failureOf(error)) {
        NotFoundFailure() => notFound ?? const NotFoundView(),
        PermissionFailure(:final message) => PermissionDeniedView(detail: message),
        NetworkFailure() => ErrorState(onRetry: onRetry, message: l10n.offlineActionDisabled),
        // A refusal about the academy's plan is not an error to retry: it says what the plan does
        // not include, or that it has lapsed, in the academy's own words (§6).
        EntitlementFailure() && final failure =>
          RefusalView.forFailure(failure) ?? ErrorState(onRetry: onRetry, detail: failure.message),
        final failure => ErrorState(onRetry: onRetry, detail: failure?.message),
      },
      _ => skeleton ?? const DelayedLoading(skeleton: SkeletonList()),
    };
  }
}
