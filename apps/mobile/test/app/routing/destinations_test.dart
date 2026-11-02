import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/routing/route_access.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/app/routing/shells/destinations.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';

/// The shells are data; these are the invariants the widget cannot check for itself. A tab without
/// a branch index crashed silently once — the gesture handler swallowed the null check.
void main() {
  final layouts = {
    'learner': (layout: learnerLayout(), role: UserRole.student),
    'instructor': (layout: staffLayout(UserRole.instructor), role: UserRole.instructor),
    'admin': (layout: staffLayout(UserRole.admin), role: UserRole.admin),
  };

  layouts.forEach((name, entry) {
    group(name, () {
      test('every tab has a branch, and they are distinct', () {
        final branches = [for (final tab in entry.layout.tabs) tab.branch];
        expect(branches, everyElement(isNotNull), reason: 'a tab without a branch cannot navigate');
        expect(branches.toSet(), hasLength(branches.length));
      });

      test('at most five buttons in the bar, "More" included', () {
        final buttons = entry.layout.tabs.length + (entry.layout.hasMore ? 1 : 0);
        expect(buttons, inInclusiveRange(4, 5));
      });

      test('a page that is a root of a tab shares that tab\'s branch', () {
        final branches = {for (final tab in entry.layout.tabs) tab.branch};
        for (final page in entry.layout.pages.where((p) => p.branch != null)) {
          expect(branches, contains(page.branch), reason: page.route);
        }
      });

      test('every destination points at a route the app has, and the role may see it', () {
        for (final destination in [
          ...entry.layout.tabs,
          ...entry.layout.overflow,
          ...entry.layout.pages,
        ]) {
          expect(isKnownAppRoute(destination.route), isTrue, reason: destination.route);
          final section = sectionOf(destination.route);
          expect(section, isNotNull, reason: destination.route);
          expect(
            canSee(entry.role, section!),
            isTrue,
            reason: '${destination.route} is not for a ${entry.role.name}',
          );
        }
      });

      test('no destination appears twice', () {
        final routes = [
          for (final d in [...entry.layout.tabs, ...entry.layout.overflow, ...entry.layout.pages])
            d.route,
        ];
        expect(routes.toSet(), hasLength(routes.length));
      });
    });
  });

  test('a learner has five tabs and no "More": Courses is the catalogue', () {
    final layout = learnerLayout();
    expect(layout.hasMore, isFalse);
    expect(
      [for (final tab in layout.tabs) tab.route],
      [AppRoutes.home, AppRoutes.explore, AppRoutes.live, AppRoutes.assessments, AppRoutes.profile],
    );
  });

  test('staff keep four tabs and "More"', () {
    for (final role in [UserRole.instructor, UserRole.admin]) {
      final layout = staffLayout(role);
      expect(layout.tabs, hasLength(4), reason: role.name);
      expect(layout.hasMore, isTrue, reason: role.name);
    }
  });

  group('what each person is actually offered', () {
    const instructor = UserProfile(
      id: 'i1',
      name: 'I',
      email: 'i@b.test',
      role: UserRole.instructor,
      descriptor: 'Instructor',
    );
    final fullAdmin = UserProfile(
      id: 'a1',
      name: 'A',
      email: 'a@b.test',
      role: UserRole.admin,
      descriptor: 'Academy admin',
      permissions: PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
    );

    test('an instructor is never offered a destination the backend would refuse', () {
      final layout = staffLayout(UserRole.instructor);
      final offered = [
        ...layout.visible(layout.tabs, showUnbuilt: true, profile: instructor),
        ...layout.visible(layout.overflow, showUnbuilt: true, profile: instructor),
      ];
      expect(offered, isNotEmpty);
      for (final destination in offered) {
        expect(
          canOpen(instructor, destination.route),
          isTrue,
          reason: '${destination.route} needs ${requiredCapability(destination.route)}',
        );
      }
      // Billing is retired: it is offered to nobody.
      expect(offered.map((d) => d.route), isNot(contains(AppRoutes.staffBilling)));
    });

    test('every offer to a fully granted admin is openable', () {
      final layout = staffLayout(UserRole.admin);
      final offered = [
        ...layout.visible(layout.tabs, showUnbuilt: true, profile: fullAdmin),
        ...layout.visible(layout.overflow, showUnbuilt: true, profile: fullAdmin),
      ];
      for (final destination in offered) {
        expect(canOpen(fullAdmin, destination.route), isTrue, reason: destination.route);
      }
    });

    test('an admin with no grants is offered only what any staff member may open', () {
      const bare = UserProfile(
        id: 'a2',
        name: 'A',
        email: 'a2@b.test',
        role: UserRole.admin,
        descriptor: 'Academy admin',
      );
      final layout = staffLayout(UserRole.admin);
      final offered = layout.visible(layout.tabs, showUnbuilt: true, profile: bare);
      // Live checks the role alone (`requireRole('instructor', 'admin')` on the API); every tab
      // behind a grant is withheld.
      expect([for (final d in offered) d.route], [AppRoutes.staffLive]);
      for (final destination in offered) {
        expect(canOpen(bare, destination.route), isTrue, reason: destination.route);
      }
    });
  });

  test('unbuilt destinations are hidden when a build does not show them', () {
    // Granted everything, so only `built` decides what is hidden.
    final admin = UserProfile(
      id: 'a1',
      name: 'A',
      email: 'a@b.test',
      role: UserRole.admin,
      descriptor: 'Academy admin',
      permissions: PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
    );
    final layout = staffLayout(UserRole.admin);
    final shown = layout.visible(layout.overflow, showUnbuilt: false, profile: admin);
    expect(shown, isNotEmpty);
    expect(shown.every((d) => d.built), isTrue);
    expect(shown.length, lessThan(layout.overflow.length), reason: 'some are not built yet');
    expect(
      layout.visible(layout.overflow, showUnbuilt: true, profile: admin).length,
      layout.overflow.length,
    );
  });
}
