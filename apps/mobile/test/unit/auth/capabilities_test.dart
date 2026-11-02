import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/auth/capabilities.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';

UserProfile _profile(UserRole role, {List<PermissionKey> permissions = const []}) => UserProfile(
  id: 'u1',
  name: 'A',
  email: 'a@b.test',
  role: role,
  descriptor: 'x',
  permissions: permissions,
);

/// The keys `requirePermission` guards — an instructor can never pass these, whatever they hold
/// (apps/api/src/lib/permissions.ts; verified route by route for FLUTTER-006).
const _adminOnlyKeys = {
  PermissionKey.learnersSuspend,
  PermissionKey.instructorsManage,
  PermissionKey.instructorsStatus,
  PermissionKey.catalogCategoriesManage,
  PermissionKey.certificatesTemplatesManage,
  PermissionKey.certificatesRevoke,
  PermissionKey.reportsInstructorsView,
  PermissionKey.settingsEdit,
  // `/tenant/*` reads use requirePermission('settings.view') — billing is admin-only.
  PermissionKey.settingsView,
};

void main() {
  test('the table matches the backend guards key for key', () {
    for (final capability in Capability.values) {
      expect(
        capability.adminOnly,
        _adminOnlyKeys.contains(capability.key),
        reason: '${capability.name} (${capability.key.wire})',
      );
    }
  });

  test('every capability names a real permission key, and none is reused', () {
    final keys = [for (final c in Capability.values) c.key];
    expect(keys, isNot(contains(PermissionKey.unknown)));
    expect(keys.toSet(), hasLength(keys.length));
  });

  group('instructor', () {
    final instructor = _profile(UserRole.instructor);

    test('passes every staff capability on role alone', () {
      for (final capability in Capability.values.where((c) => !c.adminOnly)) {
        expect(can(instructor, capability), isTrue, reason: capability.name);
      }
      expect(can(instructor, Capability.viewReports), isTrue);
      expect(can(instructor, Capability.viewInstructors), isTrue);
      expect(can(instructor, Capability.issueCertificates), isTrue);
    });

    test('never passes an admin-only capability, even if the profile lists the key', () {
      final withKeys = _profile(UserRole.instructor, permissions: PermissionKey.values.toList());
      for (final capability in Capability.values.where((c) => c.adminOnly)) {
        expect(can(instructor, capability), isFalse, reason: capability.name);
        expect(can(withKeys, capability), isFalse, reason: '${capability.name} with the key');
      }
    });
  });

  group('academy admin', () {
    test('holds exactly the granted keys', () {
      final admin = _profile(
        UserRole.admin,
        permissions: const [PermissionKey.catalogView, PermissionKey.settingsView],
      );

      expect(can(admin, Capability.viewCourses), isTrue);
      expect(can(admin, Capability.viewBilling), isTrue);
      expect(can(admin, Capability.editCourses), isFalse);
      expect(can(admin, Capability.suspendLearners), isFalse);
      expect(capabilitiesOf(admin), {Capability.viewCourses, Capability.viewBilling});
    });

    test('no grants means nothing, never everything', () {
      final bare = _profile(UserRole.admin);
      for (final capability in Capability.values) {
        expect(can(bare, capability), isFalse, reason: capability.name);
      }
    });

    test('a fully backfilled admin holds every capability', () {
      final full = _profile(
        UserRole.admin,
        permissions: PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
      );
      expect(capabilitiesOf(full), Capability.values.toSet());
    });

    test('an unknown key from a newer backend grants nothing', () {
      final odd = _profile(UserRole.admin, permissions: const [PermissionKey.unknown]);
      expect(capabilitiesOf(odd), isEmpty);
    });
  });

  test('learners, super admins and signed-out people hold none', () {
    for (final profile in [
      _profile(UserRole.student, permissions: PermissionKey.values.toList()),
      _profile(UserRole.superadmin, permissions: PermissionKey.values.toList()),
      _profile(UserRole.unknown),
      null,
    ]) {
      expect(capabilitiesOf(profile), isEmpty, reason: '${profile?.role}');
    }
  });
}
