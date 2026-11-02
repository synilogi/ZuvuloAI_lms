import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_instructors/staff_instructors.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

/// D34: instructors who registered themselves wait in the admin's Instructors screen until the
/// admin approves or rejects them. The server scopes and decides; the screen only asks.
Map<String, dynamic> _directory() =>
    jsonDecode(jsonEncode(fixture('staff/instructors.json'))) as Map<String, dynamic>;

UserProfile _admin({List<PermissionKey>? permissions}) => UserProfile(
  id: 'u_admin',
  name: 'Kavita Menon',
  email: 'admin@example.test',
  role: UserRole.admin,
  descriptor: 'Admin',
  permissions:
      permissions ?? PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

const _request = {
  'id': 'ins_req_1',
  'name': 'Ravi Shastri',
  'email': 'ravi@example.test',
  'title': 'Instructor',
  'status': 'pending',
  'requestedAt': '2026-10-08T06:30:00.000Z',
  'lms': 'SyniastroLMS',
};

void main() {
  late FakeAdapter adapter;
  late List<Map<String, dynamic>> pending;

  setUp(() {
    adapter = FakeAdapter();
    pending = [Map<String, dynamic>.from(_request)];
    adapter.handler = (options) async {
      if (options.path == '/instructors/requests') return FakeAdapter.jsonResponse(pending);
      if (options.path.endsWith('/approve') || options.path.endsWith('/reject')) {
        final approved = options.path.endsWith('/approve');
        pending = [];
        return FakeAdapter.jsonResponse({
          'id': 'ins_req_1',
          'status': approved ? 'active' : 'rejected',
        });
      }
      return FakeAdapter.jsonResponse(_directory());
    };
  });

  Future<void> pump(WidgetTester tester, {UserProfile? signedInAs}) async {
    await pumpPublicRouter(
      tester,
      adapter: adapter,
      signedInAs: signedInAs ?? _admin(),
      initialLocation: AppRoutes.staffInstructors,
      size: const Size(400, 6000),
      routes: [
        GoRoute(
          path: AppRoutes.staffInstructors,
          builder: (_, _) => const Scaffold(body: SafeArea(child: InstructorsScreen())),
        ),
        GoRoute(path: AppRoutes.staffInstructorPattern, builder: (_, _) => const Placeholder()),
        GoRoute(path: AppRoutes.staffInstructorInvite, builder: (_, _) => const Placeholder()),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a pending request shows its name, email, date and status, with the decisions', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Pending instructor requests (1)'), findsOneWidget);
    expect(find.text('Ravi Shastri'), findsOneWidget);
    expect(find.text('ravi@example.test'), findsOneWidget);
    expect(find.text('Registered 8 Oct 2026 · Pending'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Approve'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Reject'), findsOneWidget);
  });

  testWidgets('approving asks the academy, says so, and the request leaves the list', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(AppButton, 'Approve'));
    await tester.pumpAndSettle();

    final post = adapter.requests.singleWhere((r) => r.method == 'POST');
    expect(post.path, '/instructors/requests/ins_req_1/approve');
    expect(post.data, isNull, reason: 'the academy and the outcome are the server\'s');
    expect(find.text('Ravi Shastri is now an instructor and can sign in.'), findsOneWidget);
    expect(find.textContaining('Pending instructor requests'), findsNothing);
  });

  testWidgets('rejecting asks first, then the academy', (tester) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(AppButton, 'Reject'));
    await tester.pumpAndSettle();
    expect(find.text('Reject Ravi Shastri?'), findsOneWidget);
    expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);

    final confirm = find.descendant(of: find.byType(AppDialog), matching: find.text('Reject'));
    expect(confirm, findsOneWidget);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(
      adapter.requests.singleWhere((r) => r.method == 'POST').path,
      '/instructors/requests/ins_req_1/reject',
    );
    expect(find.text("Ravi Shastri's request was rejected."), findsOneWidget);
  });

  testWidgets('an admin without instructors.manage is shown no requests and asks for none', (
    tester,
  ) async {
    await pump(tester, signedInAs: _admin(permissions: const [PermissionKey.instructorsView]));

    expect(find.textContaining('Pending instructor requests'), findsNothing);
    expect(adapter.requests.where((r) => r.path == '/instructors/requests'), isEmpty);
  });
}
