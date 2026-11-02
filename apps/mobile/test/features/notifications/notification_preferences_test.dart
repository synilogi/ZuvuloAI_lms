import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/notifications/notifications.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _settings() =>
    jsonDecode(jsonEncode(fixture('notifications/settings.json'))) as Map<String, dynamic>;

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  /// Answers by path: the bell polls while the preferences are open.
  void answering({Map<String, dynamic>? settings, Object? refusal}) {
    adapter.handler = (options) async {
      if (options.method == 'PUT' && refusal != null) {
        return FakeAdapter.jsonResponse(refusal, status: 409);
      }
      if (options.path.contains('/settings/me')) {
        return FakeAdapter.jsonResponse(settings ?? _settings());
      }
      return FakeAdapter.jsonResponse({
        'rows': const <Object>[],
        'total': 0,
        'unread': 0,
        'counts': const <String, int>{},
      });
    };
  }

  Future<void> pumpPreferences(WidgetTester tester) => pumpPublic(
    tester,
    const Scaffold(body: SafeArea(child: NotificationPreferencesScreen())),
    adapter: adapter,
    signedInAs: learner(),
    size: const Size(400, 2400),
  );

  testWidgets('every category the academy sends can be switched, except what it locks', (
    tester,
  ) async {
    answering();

    await pumpPreferences(tester);
    await tester.pumpAndSettle();

    expect(find.text('What you hear about'), findsOneWidget);
    expect(find.text('Courses'), findsWidgets);
    expect(find.text('Account'), findsWidgets);
    // Account notices: the app and email switches are locked on, as the server requires.
    final locked = tester
        .widgetList<AppSwitchRow>(find.byType(AppSwitchRow))
        .where((row) => row.lockedReason != null)
        .toList();
    expect(locked, isNotEmpty);
    expect(
      locked.map((row) => row.lockedReason),
      contains('Account and security notices stay on in the app and by email.'),
    );
    // A locked row draws a switch that cannot be moved, whatever is passed to it.
    final lockedSwitch = tester.widget<SwitchListTile>(
      find
          .descendant(
            of: find.byWidget(locked.firstWhere((row) => row.lockedReason!.startsWith('Account'))),
            matching: find.byType(SwitchListTile),
          )
          .first,
    );
    expect(lockedSwitch.onChanged, isNull);
    expect(lockedSwitch.value, isTrue);
  });

  testWidgets('SMS is shown as something the academy cannot do yet, never as a working channel', (
    tester,
  ) async {
    answering();

    await pumpPreferences(tester);
    await tester.pumpAndSettle();

    final sms = tester
        .widgetList<AppSwitchRow>(find.byType(AppSwitchRow))
        .where((row) => row.title == 'SMS')
        .toList();

    expect(sms, hasLength(notificationCategories.length));
    expect(
      sms.every((row) => row.lockedReason == 'Your LMS cannot send text messages yet.'),
      isTrue,
    );
    for (final row in sms) {
      final tile = tester.widget<SwitchListTile>(
        find.descendant(of: find.byWidget(row), matching: find.byType(SwitchListTile)).first,
      );
      expect(tile.onChanged, isNull, reason: 'there is no transport behind it');
    }
  });

  testWidgets('nothing can be saved until something changes, and then it is', (tester) async {
    answering();

    await pumpPreferences(tester);
    await tester.pumpAndSettle();

    AppButton save() => tester.widget<AppButton>(find.widgetWithText(AppButton, 'Save'));
    expect(save().onPressed, isNull, reason: 'nothing has changed yet');

    await tester.tap(find.text('Once a week'));
    await tester.pumpAndSettle();
    expect(save().onPressed, isNotNull);

    answering(settings: {..._settings(), 'emailDigest': 'weekly'});
    await tester.tap(find.widgetWithText(AppButton, 'Save'));
    await tester.pumpAndSettle();

    final put = adapter.requests.firstWhere((r) => r.method == 'PUT');
    expect((put.data! as Map)['emailDigest'], 'weekly');
    expect(find.text('Settings saved'), findsOneWidget);
    expect(save().onPressed, isNull, reason: 'what is on screen is what the academy holds');
  });

  testWidgets('quiet hours the academy would refuse are caught before anything is sent', (
    tester,
  ) async {
    answering(
      settings: {
        ..._settings(),
        'quietHours': const {'enabled': true, 'from': '22:00', 'to': '22:00'},
      },
    );

    await pumpPreferences(tester);
    await tester.pumpAndSettle();

    // Turning quiet hours off and on again is the only edit; the times are the academy's own.
    await tester.tap(find.text('Once a week'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Quiet hours need different start and end times.'), findsWidgets);
    expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
  });

  testWidgets('the academy\'s own refusal is shown against the settings', (tester) async {
    answering(
      refusal: {
        'message': 'Check your notification settings.',
        'issues': [
          {'field': 'categories', 'message': 'Account and security notices stay on.'},
        ],
      },
    );

    await pumpPreferences(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Once a day'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Account and security notices stay on.'), findsOneWidget);
    expect(find.byType(FormErrorSummary), findsOneWidget);
  });
}
