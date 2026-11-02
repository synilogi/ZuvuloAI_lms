import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';

/// Runs [open] — asking the academy for the way in and handing it to the Jitsi SDK — behind a quiet
/// black screen with a small loader, so going into a class reads as one dark step from the button to
/// the call: no flash of the schedule between them. The screen cannot be dismissed, and it closes
/// once [open] has finished, by which time the SDK's own (black) activity is on top; on a refusal or
/// an error it closes and the screen behind shows the reason as before.
Future<T> withLiveRoomJoining<T>(BuildContext context, Future<T> Function() open) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var showing = true;
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black,
    useSafeArea: false,
    builder: (_) => const PopScope(canPop: false, child: LiveRoomJoiningView()),
  );
  // Not awaited: it closes when [open] is done, not when someone taps.
  unawaited(navigator.push(route).whenComplete(() => showing = false));
  try {
    return await open();
  } finally {
    if (showing) navigator.removeRoute(route);
  }
}

/// The joining screen: black, one small loader and one line.
class LiveRoomJoiningView extends StatelessWidget {
  const LiveRoomJoiningView({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Semantics(
          liveRegion: true,
          label: context.l10n.liveConnecting,
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.liveConnecting,
                  style: context.type.bodyS.copyWith(color: Colors.white.withValues(alpha: 0.72)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
