import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/features/course_learning/course_learning.dart';
import 'package:syniastrolms_mobile/features/course_purchase/course_purchase.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/pricing.dart';
import '../../helpers/public_harness.dart';
import '../../helpers/test_config.dart';

const _courseId = 'cmudqd8g30035mmgzwtgr0mcl';
const _title = 'Jaimini Astrology: Chara Karakas';

Map<String, dynamic> _detail(String pricing) => withPricing(
  jsonDecode(jsonEncode(fixture('learning/course-detail-not-enrolled.json')))
      as Map<String, dynamic>,
  pricing,
);

Map<String, dynamic> _purchase({String status = 'created', bool enrolled = false}) => {
  'id': 'p_1',
  'courseId': _courseId,
  'courseTitle': _title,
  'status': status,
  'amount': 499900,
  'currency': 'INR',
  'listPrice': 4999,
  'enrolled': enrolled,
  'createdAt': '2026-10-23T05:00:00.000Z',
  if (status == 'paid') 'paidAt': '2026-10-23T05:02:00.000Z',
};

void main() {
  late FakeAdapter adapter;
  late bool enrolled;
  late Map<String, dynamic> startAnswer;
  late int startStatus;

  setUp(() {
    adapter = FakeAdapter();
    enrolled = false;
    startStatus = 201;
    startAnswer = {
      'purchase': _purchase(),
      'checkout': {
        'provider': 'razorpay',
        'keyId': 'rzp_test_public',
        'orderId': 'order_1',
        'amount': 499900,
        'currency': 'INR',
        'description': _title,
      },
    };
  });

  void serve(Map<String, dynamic> detail) {
    adapter.handler = (options) async {
      final path = options.path;
      if (path == '/catalog/instructors') {
        return FakeAdapter.jsonResponse(fixture('catalog/instructors.json'));
      }
      if (path == '/learning/courses/$_courseId/purchase') {
        return FakeAdapter.jsonResponse(startAnswer, status: startStatus);
      }
      if (path == '/learning/purchases/p_1/confirm') {
        enrolled = true;
        return FakeAdapter.jsonResponse({
          'purchase': _purchase(status: 'paid', enrolled: true),
          'outcome': {
            'status': 'paid',
            'enrolled': true,
            'message': 'Payment confirmed. The course is open.',
          },
        });
      }
      if (path == '/learning/purchases/p_1') return FakeAdapter.jsonResponse(_purchase());
      if (path == '/learning/courses/$_courseId') {
        return FakeAdapter.jsonResponse({...detail, 'enrolled': enrolled});
      }
      throw StateError('unexpected ${options.method} $path');
    };
  }

  Future<void> pumpOverview(
    WidgetTester tester, {
    AppConfig? config,
    CourseCheckoutRunner? runner,
  }) async {
    await pumpPublicRouter(
      tester,
      adapter: adapter,
      signedInAs: learner(),
      config: config,
      courseCheckoutRunner: runner,
      initialLocation: AppRoutes.learnCourse(_courseId),
      routes: [
        GoRoute(
          path: AppRoutes.learnCoursePattern,
          builder: (_, state) => Scaffold(
            body: SafeArea(
              child: CourseOverviewScreen(courseId: state.pathParameters['courseId'] ?? ''),
            ),
          ),
        ),
        GoRoute(path: AppRoutes.explore, builder: (_, _) => const Placeholder()),
      ],
    );
    await tester.pumpAndSettle();
  }

  bool asked(String suffix) => adapter.requests.any((r) => r.path.endsWith(suffix));

  testWidgets('without in-app selling, a paid course shows its price and a neutral line only', (
    tester,
  ) async {
    serve(_detail('paid'));
    await pumpOverview(tester);

    expect(
      find.descendant(of: find.byType(StickyActionBar), matching: find.text('₹4,999')),
      findsOneWidget,
    );
    expect(find.text('This course can’t be bought in the app.'), findsOneWidget);
    expect(find.text('Enrol'), findsNothing);
    expect(find.textContaining('Buy course'), findsNothing);
    expect(find.byType(AppButton), findsNothing, reason: 'no way in, and no link elsewhere');
    for (final word in ['web', 'website', 'browser', 'online']) {
      expect(find.textContaining(word), findsNothing, reason: 'nothing points elsewhere to buy');
    }
    expect(asked('/purchase'), isFalse);
  });

  testWidgets(
    'a paid course is bought: summary, the gateway, and open only on the server\'s word',
    (tester) async {
      serve(_detail('paid'));
      final runs = <CourseCheckout>[];
      await pumpOverview(
        tester,
        config: testConfig(courseCheckoutEnabled: true),
        runner: (checkout) async {
          runs.add(checkout);
          return const CourseGatewayCompleted(paymentId: 'pay_1', signature: 'sig_1');
        },
      );

      expect(find.text('Enrol'), findsNothing, reason: 'a paid course is never joined for free');
      await tester.tap(find.widgetWithText(AppButton, 'Buy course · ₹4,999'));
      await tester.pumpAndSettle();

      // The order summary: the course, the final amount, all-inclusive.
      expect(find.text('Order summary'), findsOneWidget);
      expect(find.text('All-inclusive price'), findsOneWidget);
      expect(find.text(_title), findsWidgets);
      expect(asked('/purchase'), isFalse, reason: 'nothing is ordered before the learner pays');

      await tester.tap(find.widgetWithText(AppButton, 'Pay ₹4,999'));
      await tester.pumpAndSettle();

      expect(runs.single.orderId, 'order_1');
      expect(asked('/confirm'), isTrue);
      expect(find.text('Payment confirmed. The course is open.'), findsWidgets);
      // The course was read again and is now the learner's: no bar to buy it.
      expect(find.textContaining('Buy course'), findsNothing);
    },
  );

  testWidgets('a cancelled checkout says nothing was charged, and offers to try again', (
    tester,
  ) async {
    serve(_detail('paid'));
    await pumpOverview(
      tester,
      config: testConfig(courseCheckoutEnabled: true),
      runner: (_) async => const CourseGatewayCancelled(),
    );

    await tester.tap(find.widgetWithText(AppButton, 'Buy course · ₹4,999'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Pay ₹4,999'));
    await tester.pumpAndSettle();

    expect(find.text('Payment cancelled. You weren’t charged.'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Try again'), findsOneWidget);
    expect(asked('/confirm'), isFalse);
  });

  testWidgets('an academy without online payments says so', (tester) async {
    serve(_detail('paid'));
    startStatus = 409;
    startAnswer = {
      'message': 'This LMS doesn’t take online payments yet.',
      'code': 'PAYMENTS_NOT_SET_UP',
    };
    await pumpOverview(
      tester,
      config: testConfig(courseCheckoutEnabled: true),
      runner: (_) async => throw StateError('no checkout should open'),
    );

    await tester.tap(find.widgetWithText(AppButton, 'Buy course · ₹4,999'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Pay ₹4,999'));
    await tester.pumpAndSettle();

    expect(find.text('Online payments aren’t available yet.'), findsOneWidget);
  });

  testWidgets('a course whose price nobody decided is not open, and offers no way in', (
    tester,
  ) async {
    serve(_detail('unset'));
    await pumpOverview(tester, config: testConfig(courseCheckoutEnabled: true));

    expect(find.text('Not open for enrolment yet'), findsOneWidget);
    expect(find.text('Enrol'), findsNothing);
    expect(find.textContaining('Buy course'), findsNothing);
    expect(find.text('₹4,999'), findsNothing);
  });

  testWidgets('the purchase history shows the course, amount, status and date', (tester) async {
    adapter.handler = (_) async => FakeAdapter.jsonResponse({
      'rows': [
        _purchase(status: 'paid', enrolled: true),
        {..._purchase(status: 'expired'), 'id': 'p_0', 'courseTitle': 'Class 10 Science'},
      ],
    });

    await pumpPublic(
      tester,
      const Scaffold(body: PurchasesScreen()),
      adapter: adapter,
      signedInAs: learner(),
    );
    await tester.pumpAndSettle();

    expect(find.text(_title), findsOneWidget);
    expect(find.text('Class 10 Science'), findsOneWidget);
    expect(find.text('₹4,999'), findsNWidgets(2), reason: 'the paise the server charged');
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('23 Oct 2026'), findsNWidgets(2));
  });

  testWidgets('no purchases yet says so', (tester) async {
    adapter.handler = (_) async => FakeAdapter.jsonResponse({'rows': <Object>[]});

    await pumpPublic(
      tester,
      const Scaffold(body: PurchasesScreen()),
      adapter: adapter,
      signedInAs: learner(),
    );
    await tester.pumpAndSettle();

    expect(find.text('No purchases yet'), findsOneWidget);
  });
}
