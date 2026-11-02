import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'dto/course_purchase.dart';

/// What the gateway's checkout hands back when it closes. A success proves nothing by itself: its
/// payment id and signature go to the server unchanged, and only the server's answer opens a course.
sealed class CourseGatewayResult {
  const CourseGatewayResult();
}

/// The gateway says it took a payment. Still to be confirmed by the server.
final class CourseGatewayCompleted extends CourseGatewayResult {
  const CourseGatewayCompleted({required this.paymentId, required this.signature});

  final String paymentId;
  final String signature;
}

/// The learner closed the checkout (Razorpay `PAYMENT_CANCELLED`), or it handed the payment off to
/// an external wallet the app does not drive. Nothing was paid here — the server is asked once all
/// the same, in case the bank settles it anyway.
final class CourseGatewayCancelled extends CourseGatewayResult {
  const CourseGatewayCancelled();
}

/// The checkout failed. [network] when the phone lost its connection on the way.
final class CourseGatewayFailed extends CourseGatewayResult {
  const CourseGatewayFailed({this.network = false});

  final bool network;
}

/// Runs the gateway's checkout for one order the server opened.
typedef CourseCheckoutRunner = Future<CourseGatewayResult> Function(CourseCheckout checkout);

/// Whether this build can run [checkout] with its own SDK: Razorpay, with the server's order, a
/// publishable key and an amount.
bool canRunNatively(CourseCheckout checkout) =>
    checkout.provider == 'razorpay' &&
    checkout.orderId.isNotEmpty &&
    (checkout.keyId ?? '').isNotEmpty &&
    checkout.amount > 0 &&
    checkout.currency.isNotEmpty;

/// The page a checkout with no native SDK is finished on: `https` only, or `http` in a dev build
/// (the local sandbox gateway). Anything else is not opened at all.
Uri? hostedCheckoutPage(CourseCheckout checkout, {required bool allowHttp}) {
  final raw = checkout.redirectUrl;
  if (raw == null || raw.isEmpty) return null;
  final url = Uri.tryParse(raw);
  if (url == null || url.host.isEmpty) return null;
  if (url.scheme == 'https' || (allowHttp && url.scheme == 'http')) return url;
  return null;
}

/// Razorpay Checkout (`razorpay_flutter`), opened with the server's order exactly as it pinned it.
/// The money settles to the academy's own Razorpay account; only its publishable key id reaches
/// the app, for this one checkout, and is never stored.
class RazorpayCourseCheckout {
  RazorpayCourseCheckout({Razorpay Function()? sdk}) : _sdk = sdk ?? Razorpay.new;

  final Razorpay Function() _sdk;

  /// The options Razorpay is opened with.
  static Map<String, dynamic> optionsFor(CourseCheckout checkout) => {
    'key': checkout.keyId,
    'order_id': checkout.orderId,
    'amount': checkout.amount,
    'currency': checkout.currency,
    if (checkout.description.isNotEmpty) 'description': checkout.description,
    if (checkout.prefill case final prefill?)
      'prefill': {'name': prefill.name, 'email': prefill.email},
    'retry': {'enabled': true, 'max_count': 3},
  };

  Future<CourseGatewayResult> run(CourseCheckout checkout) {
    final razorpay = _sdk();
    final done = Completer<CourseGatewayResult>();

    void finish(CourseGatewayResult result) {
      if (done.isCompleted) return;
      razorpay.clear();
      done.complete(result);
    }

    razorpay
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
        final paymentId = r.paymentId ?? '';
        final signature = r.signature ?? '';
        // A success without the proof the server checks is not a payment the app can report; the
        // server still finds it on the order when it is asked.
        finish(
          paymentId.isEmpty || signature.isEmpty
              ? const CourseGatewayFailed()
              : CourseGatewayCompleted(paymentId: paymentId, signature: signature),
        );
      })
      ..on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
        finish(switch (r.code) {
          Razorpay.PAYMENT_CANCELLED => const CourseGatewayCancelled(),
          Razorpay.NETWORK_ERROR => const CourseGatewayFailed(network: true),
          _ => const CourseGatewayFailed(),
        });
      })
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse _) {
        finish(const CourseGatewayCancelled());
      });

    try {
      razorpay.open(optionsFor(checkout));
    } on Object {
      finish(const CourseGatewayFailed());
    }
    return done.future;
  }
}
