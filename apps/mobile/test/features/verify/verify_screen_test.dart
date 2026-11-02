import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/features/verify/verify.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _valid() =>
    jsonDecode(jsonEncode(fixture('certificates/verify-valid.json'))) as Map<String, dynamic>;

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  group('the form', () {
    testWidgets('refuses an empty credential ID before spending a request', (tester) async {
      await pumpPublic(tester, const VerifyScreen(), adapter: adapter);

      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a credential ID.'), findsOneWidget);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('holds the field to the length the API accepts', (tester) async {
      await pumpPublic(tester, const VerifyScreen(), adapter: adapter);

      await tester.enterText(find.byType(TextField), 'x' * 80);
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text.length, 64);
      // The field itself stops at 64, so the rule can only be broken from outside the UI.
      expect(CredentialId.isWellFormed('x' * 64), isTrue);
      expect(CredentialId.isWellFormed('x' * 65), isFalse);
      expect(CredentialId.isWellFormed('   '), isFalse);
      expect(adapter.requests, isEmpty);
    });

    test('the ID is sent exactly as typed, trimmed but not re-cased', () {
      expect(CredentialId.normalise('  sa-jy-2026-00142 '), 'sa-jy-2026-00142');
    });
  });

  testWidgets('a well-formed ID opens its result', (tester) async {
    adapter.enqueueJson(_valid());
    final router = await pumpPublicRouter(
      tester,
      adapter: adapter,
      initialLocation: '/verify',
      routes: [
        GoRoute(path: '/verify', builder: (_, _) => const VerifyScreen()),
        GoRoute(
          path: '/verify/:credentialId',
          builder: (_, state) =>
              VerifyResultScreen(credentialId: state.pathParameters['credentialId']!),
        ),
      ],
    );

    await tester.enterText(find.byType(TextField), 'SA-JY-2026-00142');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(locationOf(router), '/verify/SA-JY-2026-00142');
    expect(find.text('This certificate is valid'), findsOneWidget);
  });

  group('the result', () {
    testWidgets('a valid certificate shows who earned it, for what', (tester) async {
      adapter.enqueueJson(_valid());

      await pumpPublic(
        tester,
        const VerifyResultScreen(credentialId: 'SA-JY-2026-00142'),
        adapter: adapter,
      );
      await tester.pumpAndSettle();

      expect(find.text('This certificate is valid'), findsOneWidget);
      expect(find.text('Ananya Rao'), findsOneWidget);
      expect(find.text('The 27 Nakshatras in Depth'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
      expect(find.text('91%'), findsOneWidget);
      expect(find.text('6 hours'), findsOneWidget);
      expect(find.text('Credential ID SA-JY-2026-00142'), findsOneWidget);
    });

    testWidgets('the email the route sends is never on screen', (tester) async {
      final raw = _valid();
      (raw['student']! as Map<String, dynamic>)['email'] = 'ananya@syniastrolms.test';
      adapter.enqueueJson(raw);

      await pumpPublic(
        tester,
        const VerifyResultScreen(credentialId: 'SA-JY-2026-00142'),
        adapter: adapter,
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('a revoked certificate says so, with the academy\'s reason', (tester) async {
      final raw = _valid();
      (raw['certificate']! as Map<String, dynamic>)
        ..['status'] = 'revoked'
        ..['revokedReason'] = 'Issued in error.';
      adapter.enqueueJson(raw);

      await pumpPublic(
        tester,
        const VerifyResultScreen(credentialId: 'SA-JY-2026-00142'),
        adapter: adapter,
      );
      await tester.pumpAndSettle();

      expect(find.text('This certificate has been revoked'), findsOneWidget);
      expect(find.text('Issued in error.'), findsOneWidget);
    });

    testWidgets('an expired certificate uses the server\'s verdict and date', (tester) async {
      final raw = _valid()
        ..['expired'] = true
        ..['validUntil'] = '2026-03-31T00:00:00.000Z';
      adapter.enqueueJson(raw);

      await pumpPublic(
        tester,
        const VerifyResultScreen(credentialId: 'SA-JY-2026-00142'),
        adapter: adapter,
      );
      await tester.pumpAndSettle();

      expect(find.text('This certificate has expired'), findsOneWidget);
      expect(find.textContaining('31 Mar 2026'), findsWidgets);
    });

    testWidgets('an unknown ID shows the same not-found as a pending one', (tester) async {
      adapter.enqueueJson(fixture('errors/verify-not-found.json'), status: 404);

      await pumpPublic(tester, const VerifyResultScreen(credentialId: 'NOPE-1'), adapter: adapter);
      await tester.pumpAndSettle();

      expect(find.text('No certificate found for this ID'), findsOneWidget);
      expect(find.text('Check another ID'), findsOneWidget);
    });
  });
}
