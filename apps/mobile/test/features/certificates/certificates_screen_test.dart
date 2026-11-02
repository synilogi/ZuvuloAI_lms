import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/certificates/certificates.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _detail({String status = 'issued'}) {
  final raw =
      jsonDecode(jsonEncode(fixture('learning/certificate-issued.json'))) as Map<String, dynamic>;
  final certificate = raw['certificate']! as Map<String, dynamic>;
  certificate['status'] = status;
  if (status == 'pending') {
    certificate
      ..remove('issuedAt')
      ..['credentialId'] = '';
  }
  return raw;
}

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  Future<GoRouter> pumpWallet(WidgetTester tester) => pumpPublicRouter(
    tester,
    adapter: adapter,
    signedInAs: learner(),
    initialLocation: AppRoutes.certificates,
    routes: [
      GoRoute(
        path: AppRoutes.certificates,
        builder: (_, _) => const Scaffold(body: SafeArea(child: CertificatesScreen())),
      ),
      GoRoute(path: AppRoutes.certificatePattern, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.learnCoursePattern, builder: (_, _) => const Placeholder()),
    ],
  );

  testWidgets('the wallet shows what is issued and what is still being worked towards', (
    tester,
  ) async {
    adapter.enqueueJson(fixture('learning/certificates.json'));

    await pumpWallet(tester);
    await tester.pumpAndSettle();

    // "Issued" is both the section and the badge on the card under it.
    expect(find.widgetWithText(SectionHeader, 'Issued'), findsOneWidget);
    expect(find.widgetWithText(SectionHeader, 'Working towards'), findsOneWidget);
    expect(find.text('Certificate in The 27 Nakshatras in Depth'), findsOneWidget);
    expect(find.text('Credential ID SA-JY-2026-00142'), findsOneWidget);
    expect(find.byType(CertificateWalletCard), findsOneWidget);
    expect(find.byType(WorkingTowardsCard), findsNWidgets(2));
    // The academy's own criteria, with the figures it counted.
    expect(find.text('Course progress'), findsNWidgets(2));
    expect(find.text('38% of 100%'), findsOneWidget);
    expect(find.text('83% of 60%'), findsOneWidget);
    // Nothing waiting to be claimed, so no claim button.
    expect(find.text('Claim certificate'), findsNothing);
  });

  testWidgets('a certificate waiting to be claimed offers the claim, and the academy issues it', (
    tester,
  ) async {
    adapter.enqueueJson({
      'pending': [_detail(status: 'pending')],
      'issued': const <Object>[],
      'working': const <Object>[],
    });

    await pumpWallet(tester);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(SectionHeader, 'Pending'), findsOneWidget);
    expect(find.text('You have earned this. Claim it to add it to your wallet.'), findsOneWidget);

    adapter
      ..enqueueJson(_detail())
      ..enqueueJson({
        'issued': [_detail()],
      });
    await tester.tap(find.widgetWithText(AppButton, 'Claim certificate'));
    await tester.pumpAndSettle();

    expect(adapter.requests.map((r) => r.path), contains(endsWith('/claim')));
    expect(find.widgetWithText(SectionHeader, 'Issued'), findsOneWidget);
    expect(find.text('Credential ID SA-JY-2026-00142'), findsOneWidget);
    expect(find.text('Claim certificate'), findsNothing);
  });

  testWidgets('a refused claim is reported in the academy\'s words', (tester) async {
    adapter.enqueueJson({
      'pending': [_detail(status: 'pending')],
    });

    await pumpWallet(tester);
    await tester.pumpAndSettle();

    adapter.enqueueJson({'message': 'Certificate not found.'}, status: 404);
    await tester.tap(find.widgetWithText(AppButton, 'Claim certificate'));
    await tester.pumpAndSettle();

    expect(find.text('Certificate not found.'), findsOneWidget);
  });

  testWidgets('tapping a certificate opens it', (tester) async {
    adapter.enqueueJson(fixture('learning/certificates.json'));

    final router = await pumpWallet(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Certificate in The 27 Nakshatras in Depth'));
    await tester.pumpAndSettle();

    expect(locationOf(router), startsWith('/certificates/'));
  });

  testWidgets('a learner with nothing yet is told how to earn one', (tester) async {
    adapter.enqueueJson(const <String, Object>{});

    await pumpWallet(tester);
    await tester.pumpAndSettle();

    expect(find.text('No certificates yet'), findsOneWidget);
    expect(find.text('Complete a course to earn your first certificate.'), findsOneWidget);
  });

  testWidgets('a failed read offers a retry', (tester) async {
    adapter
      ..enqueueJson({'message': 'Server error.'}, status: 500)
      ..enqueueJson(fixture('learning/certificates.json'));

    await pumpWallet(tester);
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(CertificateWalletCard), findsOneWidget);
  });
}
