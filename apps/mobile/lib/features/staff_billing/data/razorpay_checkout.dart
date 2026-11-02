import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../application/checkout_launcher.dart';
import 'dto/billing.dart';

/// Who is paying, for the checkout's prefill only. The academy, the plan and the amount are the
/// server's order (`CheckoutParams`); nothing here can change what is charged.
typedef CheckoutPayer = ({String name, String email});

/// The Razorpay Checkout SDK, run for one order the academy opened (`POST /tenant/billing/…`).
///
/// The SDK's answer is never taken as payment: a success carries the order id, payment id and
/// signature back to the academy (`/tenant/billing/checkout/confirm`), which verifies the signature
/// with its own secret and settles the invoice. A cancel or failure is "not paid" and changes
/// nothing. Only the publishable key id comes from the server, for this one checkout; no secret is
/// ever in the app.
class RazorpayCheckout {
  RazorpayCheckout({Razorpay Function()? sdk, this.merchantName = 'ZuviloAI'})
    : _sdk = sdk ?? Razorpay.new;

  final Razorpay Function() _sdk;
  final String merchantName;

  /// The options Razorpay is opened with: the server's order, as it pinned it.
  static Map<String, dynamic> optionsFor(
    CheckoutParams params, {
    required String merchantName,
    CheckoutPayer? payer,
    String? description,
  }) => {
    'key': params.keyId,
    'order_id': params.orderId,
    'amount': params.amount,
    'currency': params.currency,
    'name': merchantName,
    if (description != null && description.isNotEmpty) 'description': description,
    if (payer != null) 'prefill': {'name': payer.name, 'email': payer.email},
    // UPI, cards, netbanking and wallets are whatever the merchant account enables.
    'retry': {'enabled': true, 'max_count': 3},
  };

  /// Opens the checkout and waits for the person to finish, cancel, or fail.
  Future<GatewayResult> run(CheckoutParams params, {CheckoutPayer? payer, String? description}) {
    final razorpay = _sdk();
    final done = Completer<GatewayResult>();

    void finish(GatewayResult result) {
      if (done.isCompleted) return;
      razorpay.clear();
      done.complete(result);
    }

    razorpay
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
        final orderId = r.orderId ?? '';
        final paymentId = r.paymentId ?? '';
        final signature = r.signature ?? '';
        // A success without the proof the server checks is not a payment the app can report.
        finish(
          orderId.isEmpty || paymentId.isEmpty || signature.isEmpty
              ? const GatewayNotCompleted(reason: 'incomplete-response')
              : GatewayCompleted(orderId: orderId, paymentId: paymentId, signature: signature),
        );
      })
      ..on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
        finish(
          GatewayNotCompleted(
            reason: r.code == Razorpay.PAYMENT_CANCELLED ? 'cancelled' : 'failed',
          ),
        );
      })
      // No external wallets are configured, so this only fires if Razorpay hands one off: that
      // wallet's payment is not this order's, and the academy's webhook settles it if it happens.
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse _) {
        finish(const GatewayNotCompleted(reason: 'external-wallet'));
      });

    try {
      razorpay.open(
        optionsFor(params, merchantName: merchantName, payer: payer, description: description),
      );
    } on Object {
      finish(const GatewayNotCompleted(reason: 'failed'));
    }
    return done.future;
  }
}
