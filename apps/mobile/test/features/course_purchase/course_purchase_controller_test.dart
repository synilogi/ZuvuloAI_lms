import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/features/course_purchase/course_purchase.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

const _course = 'c_maths';
const _purchase = 'p_1';

Map<String, dynamic> _purchaseJson({
  String status = 'created',
  bool enrolled = false,
  String? failureMessage,
}) => {
  'id': _purchase,
  'courseId': _course,
  'courseTitle': 'Class 10 Mathematics',
  'status': status,
  'amount': 299900,
  'currency': 'INR',
  'listPrice': 2999,
  'enrolled': enrolled,
  'failureMessage': ?failureMessage,
  'createdAt': '2026-10-23T05:00:00.000Z',
};

Map<String, dynamic> _start() => {
  'purchase': _purchaseJson(),
  'checkout': {
    'provider': 'razorpay',
    'keyId': 'rzp_test_public',
    'orderId': 'order_1',
    'amount': 299900,
    'currency': 'INR',
    'description': 'Class 10 Mathematics',
    'prefill': {'name': 'Ananya Rao', 'email': 'learner@example.test'},
  },
};

Map<String, dynamic> _confirmation(String status, {bool enrolled = false, String? message}) => {
  'purchase': _purchaseJson(status: enrolled ? 'paid' : 'created', enrolled: enrolled),
  'outcome': {'status': status, 'enrolled': enrolled, 'message': message ?? 'Said by the server.'},
};

/// The routes this flow calls, answered in turn: each list is consumed front to back, and its last
/// answer repeats. A [DioExceptionType] in a list is a dropped connection.
class _Server {
  _Server(this.adapter);

  final FakeAdapter adapter;
  List<Object> starts = [_start()];
  List<Object> confirms = [];
  List<Object> statuses = [];
  int startStatus = 201;
  int confirmStatus = 200;

  int get startCalls => _calls('POST', '/purchase');
  int get confirmCalls => _calls('POST', '/confirm');
  int get statusCalls => adapter.requests
      .where((r) => r.method == 'GET' && r.path.startsWith('/learning/purchases/'))
      .length;

  int _calls(String method, String suffix) =>
      adapter.requests.where((r) => r.method == method && r.path.endsWith(suffix)).length;

  Object _next(List<Object> answers, int index) =>
      answers[index < answers.length ? index : answers.length - 1];

  void install() {
    adapter.handler = (options) async {
      final path = options.path;
      Object answer;
      var status = 200;
      if (options.method == 'POST' && path == '/learning/courses/$_course/purchase') {
        answer = _next(starts, startCalls - 1);
        status = startStatus;
      } else if (options.method == 'POST' && path == '/learning/purchases/$_purchase/confirm') {
        answer = _next(confirms, confirmCalls - 1);
        status = confirmStatus;
      } else if (options.method == 'GET' && path.startsWith('/learning/purchases/')) {
        answer = _next(statuses, statusCalls - 1);
      } else if (options.method == 'GET' && path.startsWith('/learning/')) {
        // The screens the controller re-reads once the course opens.
        answer = <String, dynamic>{};
      } else {
        throw StateError('unexpected ${options.method} $path');
      }
      if (answer is DioExceptionType) {
        throw DioException(requestOptions: options, type: answer);
      }
      return FakeAdapter.jsonResponse(answer, status: status);
    };
  }
}

void main() {
  late FakeAdapter adapter;
  late _Server server;
  late MemoryPendingPurchaseStore store;
  late List<CourseCheckout> opened;
  late FutureOr<CourseGatewayResult> Function() gateway;

  setUp(() {
    adapter = FakeAdapter();
    server = _Server(adapter);
    store = MemoryPendingPurchaseStore();
    opened = [];
    gateway = () => const CourseGatewayCompleted(paymentId: 'pay_1', signature: 'sig_1');
  });

  ProviderContainer container() {
    server.install();
    final c = ProviderContainer(
      retry: noProviderRetry,
      overrides: publicScope(
        adapter: adapter,
        signedInAs: learner(),
        pendingPurchases: store,
        courseCheckoutRunner: (checkout) async {
          opened.add(checkout);
          return gateway();
        },
        child: const SizedBox.shrink(),
      ).overrides,
    );
    addTearDown(c.dispose);
    c.listen(coursePurchaseProvider(_course), (_, _) {});
    return c;
  }

  CoursePurchaseController controller(ProviderContainer c) =>
      c.read(coursePurchaseProvider(_course).notifier);
  CoursePurchaseState stateOf(ProviderContainer c) => c.read(coursePurchaseProvider(_course));

  test('start → checkout → confirm: open only once the server says the course is open', () async {
    server.confirms = [_confirmation('paid', enrolled: true)];
    final c = container();

    await controller(c).buy();

    expect(stateOf(c).stage, PurchaseStage.paid);
    // The app named only the course; the gateway ran the server's order as it was.
    final start = adapter.requests.firstWhere((r) => r.path.endsWith('/purchase'));
    expect(start.data, isNull, reason: 'no amount, price or academy is sent');
    expect(opened.single.orderId, 'order_1');
    expect(opened.single.amount, 299900);
    final confirm = adapter.requests.firstWhere((r) => r.path.endsWith('/confirm'));
    expect(confirm.data, {'paymentId': 'pay_1', 'signature': 'sig_1'});
    expect(store.held, isEmpty, reason: 'nothing left to recover');
  });

  test('a declined payment says the server\'s words and opens nothing', () async {
    server.confirms = [
      _confirmation('failed', message: 'The payment was declined. Nothing was charged.'),
    ];
    final c = container();

    await controller(c).buy();

    expect(stateOf(c).stage, PurchaseStage.failed);
    expect(stateOf(c).message, 'The payment was declined. Nothing was charged.');
  });

  test('a signature that does not verify is a failure, not a success', () async {
    server
      ..confirms = [
        {'message': 'This payment could not be verified.', 'code': 'PAYMENT_FAILED'},
      ]
      ..confirmStatus = 400;
    final c = container();

    await controller(c).buy();

    expect(stateOf(c).stage, PurchaseStage.failed);
    expect(stateOf(c).failure, isA<PaymentFailure>());
    expect(stateOf(c).message, 'This payment could not be verified.');
  });

  test('cancelling the checkout asks the server once, then says nothing was charged', () async {
    gateway = () => const CourseGatewayCancelled();
    server.statuses = [_purchaseJson()];
    final c = container();

    await controller(c).buy();

    expect(stateOf(c).stage, PurchaseStage.cancelled);
    expect(server.confirmCalls, 0);
    expect(server.statusCalls, 1);
    // The order is still open at the gateway: kept, so a late UPI payment is still picked up.
    expect(store.held.single.purchaseId, _purchase);
  });

  test('a cancelled checkout whose payment landed anyway opens the course', () async {
    gateway = () => const CourseGatewayCancelled();
    server.statuses = [_purchaseJson(status: 'paid', enrolled: true)];
    final c = container();

    await controller(c).buy();

    expect(stateOf(c).stage, PurchaseStage.paid);
  });

  test('pending → asked again → paid', () async {
    server
      ..confirms = [_confirmation('pending')]
      ..statuses = [_purchaseJson(), _purchaseJson(status: 'paid', enrolled: true)];
    final c = container();
    final stages = <PurchaseStage>[];
    c.listen(coursePurchaseProvider(_course), (_, next) => stages.add(next.stage));

    await controller(c).buy();

    expect(
      stages,
      containsAllInOrder([PurchaseStage.confirming, PurchaseStage.waiting, PurchaseStage.paid]),
    );
    expect(server.statusCalls, 2);
  });

  test('"paid" without the course open is not success: the app keeps asking', () async {
    server
      ..confirms = [_confirmation('paid')]
      ..statuses = [_purchaseJson()];
    final c = container();

    await controller(c).buy();

    expect(stateOf(c).stage, PurchaseStage.stillWaiting);
    expect(server.statusCalls, 3, reason: 'the harness polls three times');
    expect(store.held, hasLength(1), reason: 'kept until the server settles it');
  });

  test(
    'losing the connection while confirming keeps the purchase, and checks again later',
    () async {
      server
        ..confirms = [DioExceptionType.connectionError]
        ..statuses = [_purchaseJson(status: 'paid', enrolled: true)];
      final c = container();

      await controller(c).buy();

      expect(stateOf(c).stage, PurchaseStage.offline);
      expect(stateOf(c).canCheckAgain, isTrue);
      expect(store.held.single.purchaseId, _purchase);

      await controller(c).checkAgain();

      expect(stateOf(c).stage, PurchaseStage.paid);
      expect(store.held, isEmpty);
    },
  );

  test('the gateway losing the connection is offline, not failed', () async {
    gateway = () => const CourseGatewayFailed(network: true);
    final c = container();

    await controller(c).buy();

    expect(stateOf(c).stage, PurchaseStage.offline);
    expect(server.confirmCalls, 0);
  });

  test('a gateway failure asks the server, then says it did not go through', () async {
    gateway = () => const CourseGatewayFailed();
    server.statuses = [_purchaseJson(failureMessage: 'Card declined by the bank.')];
    final c = container();

    await controller(c).buy();

    expect(stateOf(c).stage, PurchaseStage.failed);
    expect(stateOf(c).message, 'Card declined by the bank.');
  });

  for (final (code, problem) in [
    ('PAYMENTS_NOT_SET_UP', CourseSaleProblem.paymentsNotSetUp),
    ('COURSE_NOT_FOR_SALE', CourseSaleProblem.notForSale),
    ('ALREADY_ENROLLED', CourseSaleProblem.alreadyEnrolled),
  ]) {
    test('a refused order ($code) opens no checkout', () async {
      server
        ..starts = [
          {'message': 'Said by the server.', 'code': code},
        ]
        ..startStatus = 409;
      final c = container();

      await controller(c).buy();

      expect(stateOf(c).stage, PurchaseStage.refused);
      expect(
        stateOf(c).failure,
        isA<CourseSaleFailure>().having((f) => f.problem, 'problem', problem),
      );
      expect(opened, isEmpty);
      expect(store.held, isEmpty);
    });
  }

  test('no second order while one is starting', () async {
    final gate = Completer<CourseGatewayResult>();
    gateway = () => gate.future;
    server.confirms = [_confirmation('paid', enrolled: true)];
    final c = container();

    final first = controller(c).buy();
    await Future<void>.delayed(Duration.zero);
    expect(stateOf(c).busy, isTrue);
    await controller(c).buy();
    gate.complete(const CourseGatewayCompleted(paymentId: 'pay_1', signature: 'sig_1'));
    await first;

    expect(server.startCalls, 1);
    expect(opened, hasLength(1));
  });

  test('the purchase is kept from the moment the checkout opens', () async {
    final gate = Completer<CourseGatewayResult>();
    gateway = () => gate.future;
    final c = container();

    final run = controller(c).buy();
    for (var i = 0; i < 100 && opened.isEmpty; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(stateOf(c).stage, PurchaseStage.atGateway);
    expect(store.held.single, (userId: 'u_learner', purchaseId: _purchase, courseId: _course));
    gate.complete(const CourseGatewayCancelled());
    server.statuses = [_purchaseJson()];
    await run;
  });

  group('after the app was closed mid-payment', () {
    test('opening the course asks about its open purchase, and opens it if paid', () async {
      store.held.add((userId: 'u_learner', purchaseId: _purchase, courseId: _course));
      server.statuses = [_purchaseJson(status: 'paid', enrolled: true)];
      final c = container();

      await controller(c).resume();

      expect(stateOf(c).stage, PurchaseStage.paid);
      expect(store.held, isEmpty);
    });

    test('an expired one is forgotten quietly', () async {
      store.held.add((userId: 'u_learner', purchaseId: _purchase, courseId: _course));
      server.statuses = [_purchaseJson(status: 'expired')];
      final c = container();

      await controller(c).resume();

      expect(stateOf(c).stage, PurchaseStage.idle);
      expect(store.held, isEmpty);
    });

    test('someone else\'s purchase on this device is never asked about', () async {
      store.held.add((userId: 'u_other', purchaseId: _purchase, courseId: _course));
      final c = container();

      await controller(c).resume();

      expect(server.statusCalls, 0);
      expect(store.held, hasLength(1));
    });

    test('recovery on resume settles each of the learner\'s open purchases', () async {
      store.held.addAll([
        (userId: 'u_learner', purchaseId: _purchase, courseId: _course),
        (userId: 'u_learner', purchaseId: 'p_2', courseId: 'c_science'),
        (userId: 'u_learner', purchaseId: 'p_3', courseId: 'c_english'),
        (userId: 'u_other', purchaseId: 'p_4', courseId: 'c_hindi'),
      ]);
      final c = container();
      adapter.handler = (options) async => switch (options.path) {
        '/learning/purchases/$_purchase' => FakeAdapter.jsonResponse(
          _purchaseJson(status: 'paid', enrolled: true),
        ),
        '/learning/purchases/p_2' => FakeAdapter.jsonResponse({
          ..._purchaseJson(status: 'expired'),
          'id': 'p_2',
        }),
        '/learning/purchases/p_3' => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
        _ => throw StateError('unexpected ${options.path}'),
      };

      final opened = await c.read(coursePurchaseRecoveryProvider).run();

      expect(opened, 1);
      expect([for (final p in store.held) p.purchaseId], ['p_3', 'p_4']);
      expect(
        adapter.requests.map((r) => r.path),
        isNot(contains('/learning/purchases/p_4')),
        reason: 'another learner\'s purchase',
      );
    });
  });

  test('the purchase history lists what the server returned', () async {
    final c = container();
    adapter.handler = (_) async => FakeAdapter.jsonResponse({
      'rows': [
        _purchaseJson(status: 'paid', enrolled: true),
        {..._purchaseJson(status: 'expired'), 'id': 'p_0'},
      ],
    });
    c.listen(coursePurchasesProvider, (_, _) {});

    final rows = await c.read(coursePurchasesProvider.future);

    expect(
      [for (final r in rows) r.status],
      [CoursePurchaseStatus.paid, CoursePurchaseStatus.expired],
    );
    expect(adapter.lastRequest.path, '/learning/purchases');
    expect(jsonEncode(rows.first.toJson()), contains('299900'));
  });
}
