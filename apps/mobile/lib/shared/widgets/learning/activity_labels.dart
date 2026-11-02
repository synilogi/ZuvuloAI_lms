import 'package:flutter/widgets.dart';

import '../../../l10n/l10n.dart';
import '../../domain/activity.dart';
import '../icons/app_icons.dart';

/// The academy's own name for something a learner did, and the icon that goes with it. Shared,
/// because the learner reads their own activity and staff read theirs from the same `ActivityKind`.
String activityLabel(AppLocalizations l10n, ActivityKind kind) => switch (kind) {
  ActivityKind.enrolled => l10n.activityEnrolled,
  ActivityKind.lessonCompleted => l10n.activityLessonCompleted,
  ActivityKind.chapterCompleted => l10n.activityChapterCompleted,
  ActivityKind.liveAttended => l10n.activityLiveAttended,
  ActivityKind.assignmentSubmitted => l10n.activityAssignmentSubmitted,
  ActivityKind.assessmentPassed => l10n.activityAssessmentPassed,
  ActivityKind.certificateIssued => l10n.activityCertificateIssued,
  ActivityKind.rankAchieved => l10n.activityRankAchieved,
  ActivityKind.unknown => l10n.profileActivityTitle,
};

IconData activityIcon(ActivityKind kind) => switch (kind) {
  ActivityKind.enrolled => AppIcons.people,
  ActivityKind.lessonCompleted || ActivityKind.chapterCompleted => AppIcons.check,
  ActivityKind.liveAttended => AppIcons.live,
  ActivityKind.assignmentSubmitted => AppIcons.assignment,
  ActivityKind.assessmentPassed => AppIcons.quiz,
  ActivityKind.certificateIssued => AppIcons.certificate,
  ActivityKind.rankAchieved => AppIcons.rank,
  ActivityKind.unknown => AppIcons.notifications,
};
