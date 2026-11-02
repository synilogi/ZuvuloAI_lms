import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/certificates/certificates.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _detail({String status = 'issued', String? revokedReason}) {
  final raw =
      jsonDecode(jsonEncode(fixture('learning/certificate-issued.json'))) as Map<String, dynamic>;
  final certificate = raw['certificate']! as Map<String, dynamic>;
  certificate['status'] = status;
  if (status == 'pending') {
    certificate
      ..remove('issuedAt')
      ..['credentialId'] = '';
  }
  if (revokedReason != null) certificate['revokedReason'] = revokedReason;
  return raw;
}

void main() {
  late FakeAdapter adapter;
  late List<({String text, String? subject})> shared;

  setUp(() {
    adapter = FakeAdapter();
    shared = [];
  });

  Future<GoRouter> pumpDetail(WidgetTester tester, {String id = 'c1'}) => pumpPublicRouter(
    tester,
    adapter: adapter,
    signedInAs: learner(),
    initialLocation: AppRoutes.certificate(id),
    size: const Size(400, 1600),
    shareText: ({required String text, String? subject}) async {
      shared.add((text: text, subject: subject));
    },
    routes: [
      GoRoute(
        path: AppRoutes.certificatePattern,
        builder: (_, state) => Scaffold(
          body: SafeArea(
            child: CertificateDetailScreen(
              certificateId: state.pathParameters['certificateId'] ?? '',
            ),
          ),
        ),
      ),
      GoRoute(path: AppRoutes.certificates, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.verifyCredentialPattern, builder: (_, _) => const Placeholder()),
    ],
  );

  testWidgets('an issued certificate is drawn on the canvas with the template\'s own fields', (
    tester,
  ) async {
    adapter.enqueueJson(_detail());

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.byType(CertificateCanvas), findsOneWidget);
    final canvas = tester.widget<CertificateCanvas>(find.byType(CertificateCanvas));
    expect(canvas.data.heading, 'Certificate of Completion');
    expect(canvas.data.statement, 'has completed the course of study in');
    expect(canvas.data.learnerName, 'Ananya Rao');
    expect(canvas.data.courseTitle, 'The 27 Nakshatras in Depth');
    expect(canvas.data.credentialId, 'SA-JY-2026-00142');
    expect(canvas.data.accent, CertificateAccent.emerald);
    // The template says to print both, so both are on the paper.
    expect(canvas.data.details, ['91%', '6 hours']);
    expect(canvas.data.signatories.map((s) => s.name), ['Dr. Meenakshi Iyer', 'Kavita Menon']);
    expect(canvas.data.issuedOnLabel, isNotNull);
    expect(canvas.semanticLabel, contains('SA-JY-2026-00142'));
  });

  testWidgets('a template that prints neither score nor hours puts neither on the paper', (
    tester,
  ) async {
    final row = _detail();
    (row['template']! as Map<String, dynamic>)
      ..['showScore'] = false
      ..['showHours'] = false;
    adapter.enqueueJson(row);

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(tester.widget<CertificateCanvas>(find.byType(CertificateCanvas)).data.details, isEmpty);
  });

  testWidgets('the details list is what the academy recorded', (tester) async {
    adapter.enqueueJson(_detail());

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('Certificate details'), findsOneWidget);
    expect(find.text('Ananya Rao'), findsWidgets);
    expect(find.text('Intermediate'), findsOneWidget);
    expect(find.text('SA-JY-2026-00142'), findsWidgets);
    expect(find.text('91%'), findsWidgets);
    expect(find.text('Verified 5 times'), findsOneWidget);
  });

  testWidgets('sharing hands over the public verification link and nothing else', (tester) async {
    adapter.enqueueJson(_detail());

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'Share verification link'));
    await tester.pumpAndSettle();

    expect(shared, hasLength(1));
    expect(shared.single.text, 'https://web.test/verify/SA-JY-2026-00142');
    expect(shared.single.subject, contains('Certificate in The 27 Nakshatras in Depth'));
    // Nothing about the learner but their certificate goes out.
    expect(shared.single.text, isNot(contains('@')));
  });

  testWidgets('the verification page opens in the app', (tester) async {
    adapter.enqueueJson(_detail());

    final router = await pumpDetail(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'Open the verification page'));
    await tester.pumpAndSettle();

    expect(locationOf(router), '/verify/SA-JY-2026-00142');
  });

  testWidgets('a pending certificate is claimed here, and the academy issues it', (tester) async {
    adapter.enqueueJson(_detail(status: 'pending'));

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('You have earned this. Claim it to add it to your wallet.'), findsWidgets);
    expect(find.widgetWithText(AppButton, 'Share verification link'), findsNothing);

    adapter
      ..enqueueJson(_detail())
      ..enqueueJson(_detail());
    await tester.tap(find.widgetWithText(AppButton, 'Claim certificate'));
    await tester.pumpAndSettle();

    expect(adapter.requests.map((r) => r.path), contains(endsWith('/claim')));
    expect(find.text('Certificate issued'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Share verification link'), findsOneWidget);
  });

  testWidgets('a withdrawn certificate says so, and offers nothing to share', (tester) async {
    adapter.enqueueJson(_detail(status: 'revoked', revokedReason: 'Issued in error.'));

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('Withdrawn by the LMS'), findsOneWidget);
    expect(find.text('Issued in error.'), findsOneWidget);
    expect(find.byType(StickyActionBar), findsNothing);
  });

  testWidgets('a certificate that is not there offers the way back', (tester) async {
    adapter.enqueueJson({'message': 'Certificate not found.'}, status: 404);

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundView), findsOneWidget);
  });
}
