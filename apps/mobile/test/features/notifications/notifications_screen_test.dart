import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/notifications/notifications.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _list({String name = 'notifications/list.json'}) =>
    jsonDecode(jsonEncode(fixture(name))) as Map<String, dynamic>;

/// An instructor, for the staff side of the same centre.
UserProfile _instructor() => const UserProfile(
  id: 'u_staff',
  name: 'Dr. Meenakshi Iyer',
  email: 'staff@example.test',
  role: UserRole.instructor,
  descriptor: 'Instructor',
);

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  /// Answers every request by path, because the bell polls alongside the screen.
  void answering({Map<String, dynamic>? list, Object? count, Object? error, int status = 200}) {
    adapter.handler = (options) async {
      if (error != null && options.method == 'POST') {
        return FakeAdapter.jsonResponse(error, status: status);
      }
      if (options.path.endsWith('/read-all') || options.path.endsWith('/clear')) {
        return FakeAdapter.jsonResponse(count ?? 0);
      }
      if (options.method == 'POST') return FakeAdapter.noContent();
      if (options.path.startsWith('/notifications/') && !options.path.contains('settings')) {
        final page = list ?? _list();
        final wanted = options.path.split('/').last;
        final row = (page['rows']! as List<dynamic>).cast<Map<String, dynamic>>().firstWhere(
          (r) => r['id'] == wanted,
          orElse: () => (page['rows']! as List<dynamic>).first as Map<String, dynamic>,
        );
        return FakeAdapter.jsonResponse({
          'notification': {...row, 'readAt': DateTime.now().toUtc().toIso8601String()},
          'related': const <Object>[],
          'channels': const {'app': true, 'email': true, 'sms': false},
        });
      }
      return FakeAdapter.jsonResponse(list ?? _list());
    };
  }

  Future<GoRouter> pumpCentre(WidgetTester tester, {UserProfile? signedInAs}) => pumpPublicRouter(
    tester,
    adapter: adapter,
    signedInAs: signedInAs ?? learner(),
    initialLocation: AppRoutes.notifications,
    size: const Size(400, 1400),
    routes: [
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const Scaffold(body: SafeArea(child: NotificationsScreen())),
      ),
      GoRoute(
        path: AppRoutes.notificationPattern,
        builder: (_, state) => Scaffold(
          body: SafeArea(
            child: NotificationDetailScreen(
              notificationId: state.pathParameters['notificationId'] ?? '',
            ),
          ),
        ),
      ),
      GoRoute(path: AppRoutes.certificatePattern, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.assignmentPattern, builder: (_, _) => const Placeholder()),
    ],
  );

  testWidgets('every notice is listed with its category, and the counts are the academy\'s', (
    tester,
  ) async {
    answering();

    await pumpCentre(tester);
    await tester.pumpAndSettle();

    expect(find.byType(NotificationRow), findsNWidgets(5));
    expect(find.textContaining('has been graded'), findsOneWidget);
    expect(find.text('Certificates'), findsWidgets);
    // The chip bar carries the academy's own per-category unread counts.
    expect(find.byType(NotificationCategoryBar), findsOneWidget);
  });

  testWidgets('opening one reads it in full, with its facts and the way on', (tester) async {
    answering();

    final router = await pumpCentre(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('has been graded'));
    await tester.pumpAndSettle();

    expect(locationOf(router), startsWith('/notifications/'));
    expect(find.text('Score'), findsOneWidget);
    expect(find.text('84 / 100'), findsOneWidget);
    expect(find.text('Dr. Meenakshi Iyer'), findsWidgets);
    expect(find.text('Sent to: the app, email'), findsOneWidget);
  });

  testWidgets('a notice\'s action opens the app\'s own route, never a URL', (tester) async {
    answering();

    final router = await pumpCentre(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('has been graded'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'Read the feedback'));
    await tester.pumpAndSettle();

    expect(locationOf(router), startsWith('/assignments/'));
  });

  testWidgets('an action the app does not know is shown, and leads nowhere', (tester) async {
    final page = _list();
    final row = (page['rows']! as List<dynamic>).cast<Map<String, dynamic>>().firstWhere(
      (r) => '${r['title']}'.contains('graded'),
    );
    row['action'] = {'label': 'Open the console', 'to': '/ops/console'};
    answering(list: page);

    final router = await pumpCentre(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('has been graded'));
    await tester.pumpAndSettle();

    expect(find.text('Open the console'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Open the console'), findsNothing);
    expect(locationOf(router), startsWith('/notifications/'));
  });

  testWidgets('a staff notice points into the staff side', (tester) async {
    answering(list: _list(name: 'notifications/staff-list.json'));

    await pumpCentre(tester, signedInAs: _instructor());
    await tester.pumpAndSettle();

    expect(find.textContaining('submitted'), findsOneWidget);
    expect(find.byType(NotificationRow), findsOneWidget);
  });

  testWidgets('marking everything read says how many the academy changed', (tester) async {
    answering(count: 5);

    await pumpCentre(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.more).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark all read').last);
    await tester.pumpAndSettle();

    expect(adapter.requests.map((r) => r.path), contains('/notifications/read-all'));
    expect(find.text('5 marked read'), findsOneWidget);
  });

  testWidgets('removing one offers an undo that puts it back on the server', (tester) async {
    answering();

    await pumpCentre(tester);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(NotificationRow).first, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(adapter.requests.map((r) => r.path), contains('/notifications/remove'));
    expect(find.text('Notification removed'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    final restore = adapter.requests.firstWhere((r) => r.path.endsWith('/restore'));
    final sent = ((restore.data! as Map)['notifications']! as List).single as Map;
    expect(
      sent['id'],
      isNotEmpty,
      reason: 'the whole notification goes back, as the route takes it',
    );
  });

  testWidgets('clearing asks first, and says how many the academy removed', (tester) async {
    answering(count: 5);

    await pumpCentre(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.more).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear').last);
    await tester.pumpAndSettle();

    expect(find.text('Clear these notifications?'), findsOneWidget);
    expect(find.textContaining('5 notifications will be removed.'), findsOneWidget);

    // Clearing cannot be undone, so the dialog asks for an acknowledgement first (§22.5).
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AppDialog), matching: find.text('Clear')));
    await tester.pumpAndSettle();

    expect(adapter.requests.map((r) => r.path), contains('/notifications/clear'));
    expect(find.text('5 cleared'), findsOneWidget);
  });

  testWidgets('a learner with nothing to read is told so', (tester) async {
    answering(
      list: {'rows': const <Object>[], 'total': 0, 'unread': 0, 'counts': const <String, int>{}},
    );

    await pumpCentre(tester);
    await tester.pumpAndSettle();

    expect(find.text("You're all caught up"), findsOneWidget);
  });

  testWidgets('a failed read offers a retry', (tester) async {
    adapter
      ..enqueueJson({'message': 'Server error.'}, status: 500)
      ..handler = null;

    await pumpCentre(tester);
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);

    answering();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationRow), findsNWidgets(5));
  });
}
