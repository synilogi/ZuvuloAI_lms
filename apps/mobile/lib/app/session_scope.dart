import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../features/assessments/assessments.dart';
import '../features/assignments/assignments.dart';
import '../features/certificates/certificates.dart';
import '../features/learner_home/learner_home.dart';
import '../features/media/media.dart';
import '../features/notifications/notifications.dart';
import '../features/public_catalog/public_catalog.dart';
import '../features/staff_billing/staff_billing.dart';
import '../shared/session/current_user.dart';

/// The providers that hold one person's server data — or their token — and outlive the screen that
/// read them. Each belongs to whoever was signed in when it was read: the learner's home, courses,
/// assignments and assessments, their rank ladder, the catalogue of *their* Admin's LMS, the media
/// headers carrying their token, the bell's count, and per-person onboarding flags (§8.4).
///
/// Screen-scoped (auto-disposed) providers are not listed: they go with their screen.
final List<ProviderOrFamily> sessionScopedProviders = [
  learnerHomeProvider,
  learnerCoursesProvider,
  assignmentsProvider,
  assessmentsProvider,
  rankLadderProvider,
  catalogLevelsProvider,
  catalogCategoriesProvider,
  catalogInstructorsProvider,
  catalogCoursesProvider,
  catalogFilterProvider,
  catalogSearchProvider,
  mediaAuthHeadersProvider,
  unreadCountProvider,
  trialOfferDismissedProvider,
];

/// Drops every session-scoped provider when the signed-in person changes — signing out, or someone
/// else (perhaps of another Admin's LMS) signing in on this device — so nothing of the last person is
/// shown to the next. Called from the app root's listener, outside any build.
void listenForSessionChange(WidgetRef ref) {
  ref.listen<String?>(currentUserProvider.select((profile) => profile?.id), (previous, next) {
    if (previous == next) return;
    for (final provider in sessionScopedProviders) {
      ref.invalidate(provider);
    }
  });
}
