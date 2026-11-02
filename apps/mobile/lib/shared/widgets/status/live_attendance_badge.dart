import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../domain/live_class.dart';
import 'status_badge.dart';

/// A [LiveAttendance] record as a badge, in the same words for learners and staff: "Joined",
/// "Missed", or "Opened the link" — which carries no tick, since the academy did not see anyone
/// attend an outside meeting.
class LiveAttendanceBadge extends StatelessWidget {
  const LiveAttendanceBadge(this.record, {super.key});

  final LiveAttendance record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (record) {
      LiveAttendance.joined => StatusBadge(
        StatusKind.completed,
        labelOverride: l10n.liveJoinedBadge,
      ),
      LiveAttendance.missed => StatusBadge(
        StatusKind.notSubmitted,
        labelOverride: l10n.liveMissedBadge,
      ),
      LiveAttendance.openedLink => StatusBadge(
        StatusKind.submitted,
        labelOverride: l10n.liveOpenedLinkBadge,
      ),
    };
  }
}
