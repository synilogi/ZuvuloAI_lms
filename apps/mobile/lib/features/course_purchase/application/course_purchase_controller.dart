import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/error_decoder.dart';
import '../../../core/platform/external_link.dart';
import '../../../shared/domain/user_profile.dart';
import '../../../shared/session/current_user.dart';
import '../../course_learning/course_learning.dart';
import '../../learner_home/learner_home.dart';
import '../data/course_checkout_runner.dart';
import '../data/course_purchase_api.dart';
import '../data/dto/course_purchase.dart';
import '../data/pending_purchase_store.dart';

/// What the purchase screens read (§26).
export '../../../core/network/error_decoder.dart' show CourseSaleFailure, CourseSaleProblem;
export '../data/dto/course_purchase.dart';

/// Whether this build sells courses in the app (`COURSE_CHECKOUT_ENABLED`). Off in every build that
/// reaches production: there a paid course shows its price and a neutral line, and no way to buy.
final courseCheckoutEnabledProvider = Provider<bool>(
  (ref) => ref.watch(appConfigProvider).courseCheckoutEnabled,
);

/// The gateway SDK this build runs for a course: Razorpay Checkout, in a build that sells courses.
/// `null` where it does not; a test provides its own to prove what happens with each result.
final courseCheckoutRunnerProvider = Provider<CourseCheckoutRunner?>((ref) {
  if (!ref.watch(courseCheckoutEnabledProvider)) return null;
  final checkout = RazorpayCourseCheckout();
  return checkout.run;
});

/// How patiently the app asks again about a payment the bank has not settled: every three seconds,
/// for about ninety. The server decides whether it landed; this only paces the asking.
typedef PurchasePolling = ({Duration interval, int attempts});

final purchasePollingProvider = Provider<PurchasePolling>(
  (ref) => (interval: const Duration(seconds: 3), attempts: 30),
);

/// The learner's purchases, newest first (`GET /learning/purchases`).
final coursePurchasesProvider = FutureProvider<List<CoursePurchase>>(
  (ref) => ref.watch(coursePurchaseApiProvider).purchases(),
  isAutoDispose: true,
);

/// How far buying a course has got. The app never decides that a payment succeeded: [paid] is only
/// ever reached when the server says the course is open to the learner.
enum PurchaseStage {
  idle,

  /// Asking the server to open the order.
  starting,

  /// The gateway's checkout is open.
  atGateway,

  /// Handing the gateway's payment id and signature to the server.
  confirming,

  /// The server says the bank has not settled it yet; asking again.
  waiting,

  /// Asked for as long as the app waits, and still not settled: the course opens when it is.
  stillWaiting,

  /// The checkout was finished on the academy's payment page, outside the app.
  awayAtPage,

  /// The server says the course is open.
  paid,

  /// The payment was declined, or could not be verified. Nothing opened.
  failed,

  /// The learner closed the checkout. Nothing was charged.
  cancelled,

  /// The connection dropped mid-way: the purchase is kept and asked about when the app is back.
  offline,

  /// The server would not open an order ([CoursePurchaseState.failure] says why).
  refused,

  /// This build cannot run the academy's gateway.
  unsupported,
}

@immutable
class CoursePurchaseState {
  const CoursePurchaseState({
    this.stage = PurchaseStage.idle,
    this.purchase,
    this.message,
    this.failure,
  });

  final PurchaseStage stage;

  /// The purchase in flight, as the server last described it.
  final CoursePurchase? purchase;

  /// The server's own sentence about the outcome, where it gave one.
  final String? message;

  /// Why the server refused, for [PurchaseStage.refused] and [PurchaseStage.failed].
  final AppFailure? failure;

  /// Something is in flight: the Buy button stays disabled.
  bool get busy => switch (stage) {
    PurchaseStage.starting ||
    PurchaseStage.atGateway ||
    PurchaseStage.confirming ||
    PurchaseStage.waiting => true,
    _ => false,
  };

  /// A purchase is out there that the server may still settle: "Check again" is offered.
  bool get canCheckAgain =>
      purchase != null &&
      (stage == PurchaseStage.stillWaiting ||
          stage == PurchaseStage.offline ||
          stage == PurchaseStage.awayAtPage);

  @override
  bool operator ==(Object other) =>
      other is CoursePurchaseState &&
      other.stage == stage &&
      other.purchase == purchase &&
      other.message == message &&
      other.failure == failure;

  @override
  int get hashCode => Object.hash(stage, purchase, message, failure);
}

/// Buying one course: open the order, run the gateway, hand its answer to the server, and wait for
/// the server's word. What it never does: send an amount, compute one, or treat the gateway's own
/// "success" as the course being open.
class CoursePurchaseController extends Notifier<CoursePurchaseState> {
  CoursePurchaseController(this.courseId);

  final String courseId;

  @override
  CoursePurchaseState build() => const CoursePurchaseState();

  CoursePurchaseApi get _api => ref.read(coursePurchaseApiProvider);
  PendingPurchaseStore get _store => ref.read(pendingPurchaseStoreProvider);

  void _set(CoursePurchaseState next) {
    if (ref.mounted) state = next;
  }

  /// Opens the order and carries the checkout out.
  Future<void> buy() async {
    if (state.busy) return;
    _set(const CoursePurchaseState(stage: PurchaseStage.starting));
    final CoursePurchaseStart start;
    try {
      start = await _api.start(courseId);
    } on ApiException catch (e) {
      final failure = e.failure;
      if (failure is CourseSaleFailure && failure.problem == CourseSaleProblem.alreadyEnrolled) {
        // They have it already (staff added them, or another device bought it): show the course.
        _refreshCourse();
      }
      // Nothing was ordered, so there is nothing to confirm later: the learner simply tries again.
      _set(CoursePurchaseState(stage: PurchaseStage.refused, failure: failure));
      return;
    }
    if (!ref.mounted) return;
    final purchase = start.purchase;
    if (purchase.enrolled) return _opened(purchase);

    // Kept from the moment the checkout opens, so a payment made just before the app is closed is
    // still picked up the next time it starts.
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await _store.write((userId: user.id, purchaseId: purchase.id, courseId: courseId));
    }

    final checkout = start.checkout;
    final runner = ref.read(courseCheckoutRunnerProvider);
    if (runner != null && canRunNatively(checkout)) {
      _set(CoursePurchaseState(stage: PurchaseStage.atGateway, purchase: purchase));
      final result = await runner(checkout);
      if (!ref.mounted) return;
      switch (result) {
        case CourseGatewayCompleted(:final paymentId, :final signature):
          await _confirm(purchase, paymentId: paymentId, signature: signature);
        case CourseGatewayCancelled():
          await _settleOrSay(purchase, PurchaseStage.cancelled);
        case CourseGatewayFailed(network: true):
          _set(CoursePurchaseState(stage: PurchaseStage.offline, purchase: purchase));
        case CourseGatewayFailed():
          await _settleOrSay(purchase, PurchaseStage.failed);
      }
      return;
    }

    final page = hostedCheckoutPage(checkout, allowHttp: ref.read(appConfigProvider).isDev);
    if (ref.read(courseCheckoutEnabledProvider) && page != null) {
      await ref.read(openExternalLinkProvider)(page);
      _set(CoursePurchaseState(stage: PurchaseStage.awayAtPage, purchase: purchase));
      return;
    }
    _set(CoursePurchaseState(stage: PurchaseStage.unsupported, purchase: purchase));
  }

  /// The gateway reported a payment: the server verifies it, and is asked again while the bank has
  /// not settled it.
  Future<void> _confirm(
    CoursePurchase purchase, {
    required String paymentId,
    required String signature,
  }) async {
    _set(CoursePurchaseState(stage: PurchaseStage.confirming, purchase: purchase));
    final PurchaseConfirmation answer;
    try {
      answer = await _api.confirm(purchase.id, paymentId: paymentId, signature: signature);
    } on ApiException catch (e) {
      _failedOrOffline(purchase, e.failure);
      return;
    }
    if (!ref.mounted) return;
    final outcome = answer.outcome;
    final message = outcome.message.isEmpty ? null : outcome.message;
    if (answer.purchase.enrolled) return _opened(answer.purchase, message: message);
    switch (outcome.status) {
      case PurchaseOutcomeStatus.failed:
        _set(
          CoursePurchaseState(
            stage: PurchaseStage.failed,
            purchase: answer.purchase,
            message: message,
          ),
        );
      case PurchaseOutcomeStatus.paid:
      // "Paid" without the course open is not success; ask again until the server agrees.
      case PurchaseOutcomeStatus.pending ||
          PurchaseOutcomeStatus.created ||
          PurchaseOutcomeStatus.unknown:
        await _poll(answer.purchase, message: message);
    }
  }

  /// Asks `GET /learning/purchases/:id` until the server says the course is open, the purchase is
  /// settled otherwise, or the app has waited long enough.
  Future<void> _poll(CoursePurchase purchase, {String? message}) async {
    final polling = ref.read(purchasePollingProvider);
    var current = purchase;
    for (var i = 0; i < polling.attempts; i++) {
      _set(CoursePurchaseState(stage: PurchaseStage.waiting, purchase: current, message: message));
      await Future<void>.delayed(polling.interval);
      if (!ref.mounted) return;
      try {
        current = await _api.purchase(current.id);
      } on ApiException catch (e) {
        if (e.failure is NetworkFailure || e.failure is ServerFailure) {
          _set(CoursePurchaseState(stage: PurchaseStage.offline, purchase: current));
          return;
        }
        _failedOrOffline(current, e.failure);
        return;
      }
      if (!ref.mounted) return;
      if (current.enrolled) return _opened(current);
      if (current.isSettled) return _settledWithout(current);
    }
    _set(
      CoursePurchaseState(stage: PurchaseStage.stillWaiting, purchase: current, message: message),
    );
  }

  /// The checkout closed without a payment the app can report. The server is asked once all the
  /// same — a UPI payment can land after the app was told it was cancelled.
  Future<void> _settleOrSay(CoursePurchase purchase, PurchaseStage otherwise) async {
    try {
      final current = await _api.purchase(purchase.id);
      if (!ref.mounted) return;
      if (current.enrolled) return _opened(current);
      if (current.isSettled) await _store.remove(current.id);
      _set(
        CoursePurchaseState(
          stage: otherwise,
          purchase: current,
          message: otherwise == PurchaseStage.failed ? current.failureMessage : null,
        ),
      );
    } on ApiException {
      _set(CoursePurchaseState(stage: otherwise, purchase: purchase));
    }
  }

  /// Asks the server again about the purchase in flight (after coming back online, or from the
  /// academy's payment page).
  Future<void> checkAgain() async {
    final purchase = state.purchase;
    if (purchase == null || state.busy) return;
    _set(CoursePurchaseState(stage: PurchaseStage.waiting, purchase: purchase));
    try {
      final current = await _api.purchase(purchase.id);
      if (!ref.mounted) return;
      if (current.enrolled) return _opened(current);
      if (current.isSettled) return _settledWithout(current);
      // Still open: a short wait for the bank, as after a checkout.
      await _poll(current);
    } on ApiException catch (e) {
      _set(
        CoursePurchaseState(
          stage: e.failure is NetworkFailure ? PurchaseStage.offline : PurchaseStage.stillWaiting,
          purchase: purchase,
        ),
      );
    }
  }

  /// On opening the course page: a purchase this learner left open for this course (the app was
  /// closed mid-payment) is asked about, and opens the course if the server has the money.
  Future<void> resume() async {
    if (state.stage != PurchaseStage.idle) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final held = await _store.read();
    final pending = held.where((p) => p.userId == user.id && p.courseId == courseId).firstOrNull;
    if (pending == null || !ref.mounted) return;
    try {
      final current = await _api.purchase(pending.purchaseId);
      if (!ref.mounted) return;
      if (current.enrolled) return _opened(current);
      if (current.isSettled) await _store.remove(current.id);
      // Still open: nothing to say. Buy picks the same order up again.
    } on ApiException catch (e) {
      if (e.failure is NotFoundFailure) await _store.remove(pending.purchaseId);
    }
  }

  /// Back to the plain page (the learner read the message).
  void dismiss() {
    if (state.busy) return;
    _set(const CoursePurchaseState());
  }

  void _failedOrOffline(CoursePurchase purchase, AppFailure failure) {
    if (failure is NetworkFailure || failure is ServerFailure) {
      // The purchase is kept: the server's recovery and the next check settle it.
      _set(CoursePurchaseState(stage: PurchaseStage.offline, purchase: purchase));
      return;
    }
    _set(
      CoursePurchaseState(
        stage: PurchaseStage.failed,
        purchase: purchase,
        message: failure.message,
        failure: failure,
      ),
    );
  }

  Future<void> _settledWithout(CoursePurchase purchase) async {
    await _store.remove(purchase.id);
    _set(
      CoursePurchaseState(
        stage: PurchaseStage.failed,
        purchase: purchase,
        message: purchase.failureMessage,
      ),
    );
  }

  /// The server says the course is open: forget the purchase, and re-read everything it changed.
  Future<void> _opened(CoursePurchase purchase, {String? message}) async {
    await _store.remove(purchase.id);
    _set(CoursePurchaseState(stage: PurchaseStage.paid, purchase: purchase, message: message));
    _refreshCourse();
  }

  void _refreshCourse() {
    if (!ref.mounted) return;
    ref
      ..invalidate(learnerCourseProvider(courseId))
      ..invalidate(learnerHomeProvider)
      ..invalidate(learnerCoursesProvider)
      ..invalidate(coursePurchasesProvider);
  }
}

final coursePurchaseProvider =
    NotifierProvider.family<CoursePurchaseController, CoursePurchaseState, String>(
      CoursePurchaseController.new,
      isAutoDispose: true,
    );

/// Asks the server about every purchase this learner left open on this device — on start-up once
/// they are signed in, and whenever the app comes back to the foreground. A course the server has
/// opened is shown as open everywhere; a settled purchase is forgotten. Never throws.
class CoursePurchaseRecovery {
  CoursePurchaseRecovery(this._ref);

  final Ref _ref;
  bool _running = false;

  /// Answers how many courses opened.
  Future<int> run() async {
    if (_running) return 0;
    final user = _ref.read(currentUserProvider);
    if (user == null || user.role != UserRole.student) return 0;
    _running = true;
    var opened = 0;
    try {
      final store = _ref.read(pendingPurchaseStoreProvider);
      final api = _ref.read(coursePurchaseApiProvider);
      for (final pending in await store.read()) {
        if (pending.userId != user.id) continue;
        try {
          final current = await api.purchase(pending.purchaseId);
          if (current.enrolled) {
            await store.remove(current.id);
            opened++;
            _ref
              ..invalidate(learnerCourseProvider(pending.courseId))
              ..invalidate(coursePurchasesProvider);
          } else if (current.isSettled) {
            await store.remove(current.id);
          }
        } on ApiException catch (e) {
          // Offline or a server error: asked again next time. Not theirs any more: forgotten.
          if (e.failure is NotFoundFailure) await store.remove(pending.purchaseId);
        }
      }
      if (opened > 0) {
        _ref
          ..invalidate(learnerHomeProvider)
          ..invalidate(learnerCoursesProvider);
      }
    } on Object {
      return opened;
    } finally {
      _running = false;
    }
    return opened;
  }
}

final coursePurchaseRecoveryProvider = Provider<CoursePurchaseRecovery>(CoursePurchaseRecovery.new);
