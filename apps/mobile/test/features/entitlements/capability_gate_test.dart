import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/auth/capabilities.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/shared/entitlements/entitlements.dart';

import '../../helpers/pump.dart';

UserProfile _profile(UserRole role, {List<PermissionKey> permissions = const []}) => UserProfile(
  id: 'u1',
  name: 'A',
  email: 'a@b.test',
  role: role,
  descriptor: 'x',
  permissions: permissions,
);

void main() {
  Future<void> pumpGate(
    WidgetTester tester, {
    required UserProfile? profile,
    required Capability capability,
    Widget? fallback,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWithValue(profile)],
        child: themedHarness(
          CapabilityGate(
            capability: capability,
            fallback: fallback,
            child: const Text('Suspend learner'),
          ),
          scroll: false,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('offers the control to someone who holds the capability', (tester) async {
    await pumpGate(
      tester,
      profile: _profile(UserRole.admin, permissions: const [PermissionKey.learnersSuspend]),
      capability: Capability.suspendLearners,
    );

    expect(find.text('Suspend learner'), findsOneWidget);
  });

  testWidgets('hides it from an instructor, who can never hold an admin-only key', (tester) async {
    await pumpGate(
      tester,
      profile: _profile(UserRole.instructor),
      capability: Capability.suspendLearners,
    );

    expect(find.text('Suspend learner'), findsNothing);
  });

  testWidgets('hides it from an admin without the grant', (tester) async {
    await pumpGate(
      tester,
      profile: _profile(UserRole.admin),
      capability: Capability.suspendLearners,
    );

    expect(find.text('Suspend learner'), findsNothing);
  });

  testWidgets('shows the fallback where the control should keep its place', (tester) async {
    await pumpGate(
      tester,
      profile: _profile(UserRole.instructor),
      capability: Capability.suspendLearners,
      fallback: const Text('Ask your academy admin.'),
    );

    expect(find.text('Suspend learner'), findsNothing);
    expect(find.text('Ask your academy admin.'), findsOneWidget);
  });

  testWidgets('an instructor still gets the staff capabilities', (tester) async {
    await pumpGate(
      tester,
      profile: _profile(UserRole.instructor),
      capability: Capability.gradeSubmissions,
    );

    expect(find.text('Suspend learner'), findsOneWidget);
  });
}
