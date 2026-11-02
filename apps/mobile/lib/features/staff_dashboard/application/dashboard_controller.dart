import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/dashboard.dart';
import '../../../shared/domain/user_profile.dart';
import '../../../shared/session/current_user.dart';
import '../data/dashboard_api.dart';

/// The dashboard models the screen reads (§18, §26).
export '../../../shared/domain/dashboard.dart';

/// Which figures are on screen. An instructor has only their own; an academy admin may look at
/// the academy or at one instructor.
@immutable
class DashboardView {
  const DashboardView({this.instructorId});

  /// Set only by an admin picking one instructor.
  final String? instructorId;

  bool get isAcademy => instructorId == null;

  @override
  bool operator ==(Object other) => other is DashboardView && other.instructorId == instructorId;

  @override
  int get hashCode => instructorId.hashCode;
}

class DashboardViewController extends Notifier<DashboardView> {
  @override
  DashboardView build() => const DashboardView();

  void showAcademy() => state = const DashboardView();

  void showInstructor(String instructorId) => state = DashboardView(instructorId: instructorId);
}

final dashboardViewProvider = NotifierProvider<DashboardViewController, DashboardView>(
  DashboardViewController.new,
  isAutoDispose: true,
);

/// Whether this account may look at anyone but themselves. The route scopes an instructor's
/// dashboard to their own account whatever it is asked for, so only an academy admin has a choice.
bool canChooseScope(UserProfile? profile) => profile?.role == UserRole.admin;

/// The snapshot for whoever is signed in and whatever they are looking at. An instructor's request
/// carries no scope at all: the route decides from their own account (§7).
final dashboardProvider = FutureProvider<DashboardSnapshot>((ref) {
  final admin = canChooseScope(ref.watch(currentUserProvider));
  final view = ref.watch(dashboardViewProvider);
  if (!admin) return ref.watch(dashboardApiProvider).snapshot();
  return ref
      .watch(dashboardApiProvider)
      .snapshot(scope: view.isAcademy ? 'academy' : 'instructor', instructorId: view.instructorId);
}, isAutoDispose: true);

/// Course titles by id, for the performance list. A title the academy has not given this account
/// simply leaves that row unnamed rather than showing an id.
final dashboardCourseTitlesProvider = FutureProvider<Map<String, String>>(
  (ref) => ref.watch(dashboardApiProvider).courseTitles(),
  isAutoDispose: true,
);

/// The academy's instructors, for the admin's scope picker.
final dashboardInstructorsProvider = FutureProvider<List<({String id, String name})>>(
  (ref) => ref.watch(dashboardApiProvider).instructors(),
  isAutoDispose: true,
);
