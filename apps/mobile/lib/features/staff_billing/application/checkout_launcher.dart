import 'package:flutter/foundation.dart';

import '../data/dto/billing.dart';

/// How a checkout can be carried out on this device (§11). The academy chooses the gateway and pins
/// it to the order; the app only decides **whether it can run that gateway here**, from the shape of
/// the `CheckoutParams` it was handed. Nothing about the payment is computed, chosen or defaulted.
enum CheckoutRoute {
  /// A gateway with a native SDK this build carries, launched in the app.
  native,

  /// No SDK, but the academy gave a page to open. Only ever `https`.
  hostedPage,

  /// Nothing this build can do with it: the payment has to be finished on the web (B9, A3).
  unsupported,
}

/// What the app will do with one checkout, and why.
@immutable
class CheckoutPlan {
  const CheckoutPlan({required this.route, required this.params, this.hostedUrl});

  final CheckoutRoute route;
  final CheckoutParams params;

  /// The page to open, for [CheckoutRoute.hostedPage] only.
  final Uri? hostedUrl;

  bool get canRunHere => route != CheckoutRoute.unsupported;

  @override
  bool operator ==(Object other) =>
      other is CheckoutPlan &&
      other.route == route &&
      other.params == params &&
      other.hostedUrl == hostedUrl;

  @override
  int get hashCode => Object.hash(route, params, hostedUrl);
}

/// A gateway this build can launch natively. A launcher is registered only when its SDK is actually
/// in the app; until one is, every provider falls through to the hosted page or to "finish this on
/// the web", which is the honest answer rather than a dead button.
@immutable
class NativeLauncher {
  const NativeLauncher({required this.provider, required this.needsKeyId});

  /// The academy's own word for the gateway, as `CheckoutParams.provider` carries it.
  final String provider;

  /// Whether the SDK cannot start without the publishable key.
  final bool needsKeyId;

  /// Whether this launcher can start [params] as they stand.
  bool canStart(CheckoutParams params) {
    if (params.provider != provider) return false;
    if (params.orderId.isEmpty) return false;
    // A gateway cannot be asked for nothing, and an amount is the academy's figure.
    if (params.amount <= 0 || params.currency.isEmpty) return false;
    if (needsKeyId && (params.keyId == null || params.keyId!.isEmpty)) return false;
    return true;
  }
}

/// The launchers this build carries: Razorpay Checkout (`razorpay_flutter`), which needs the
/// server's publishable key id for the order. Whether a build runs it at all is
/// `BILLING_CHECKOUT_ENABLED` (C4); without it the native route is never taken.
const nativeLaunchers = <NativeLauncher>[NativeLauncher(provider: 'razorpay', needsKeyId: true)];

/// Decides how one checkout can be carried out here. The order of preference is the academy's own
/// gateway first, then the page it gave, then nothing.
CheckoutPlan planCheckout(
  CheckoutParams params, {
  List<NativeLauncher> launchers = nativeLaunchers,
}) {
  for (final launcher in launchers) {
    if (launcher.canStart(params)) {
      return CheckoutPlan(route: CheckoutRoute.native, params: params);
    }
  }
  final hosted = hostedPageOf(params);
  if (hosted != null) {
    return CheckoutPlan(route: CheckoutRoute.hostedPage, params: params, hostedUrl: hosted);
  }
  return CheckoutPlan(route: CheckoutRoute.unsupported, params: params);
}

/// The page to open for a checkout with no native launcher — `https` only, so a payment is never
/// carried over a link that could be read on the way. Anything else is not opened at all.
Uri? hostedPageOf(CheckoutParams params) {
  final raw = params.redirectUrl;
  if (raw == null || raw.isEmpty) return null;
  final url = Uri.tryParse(raw);
  if (url == null || url.scheme != 'https' || url.host.isEmpty) return null;
  return url;
}

/// How long the app waits on a payment the bank has not settled, and how often it asks. The academy
/// decides whether the payment landed; this only governs how patiently the app asks it again.
const checkoutPollInterval = Duration(seconds: 5);
const checkoutPollAttempts = 12;

/// What a native gateway hands back when its checkout closes. A success proves nothing by itself: its
/// three fields go back to the academy unchanged, and only the academy's answer moves anything.
sealed class GatewayResult {
  const GatewayResult();
}

/// The gateway says it took a payment. Still to be confirmed by the academy.
class GatewayCompleted extends GatewayResult {
  const GatewayCompleted({required this.orderId, required this.paymentId, required this.signature});

  final String orderId;
  final String paymentId;
  final String signature;
}

/// The person closed the gateway, or it failed: nothing was paid.
class GatewayNotCompleted extends GatewayResult {
  const GatewayNotCompleted({this.reason});

  final String? reason;
}

/// Runs a native gateway's checkout for [params]. Only a build that carries a payment SDK provides
/// one (C4); until then [nativeCheckoutRunnerProvider] is null and a native route is never planned.
typedef NativeCheckoutRunner = Future<GatewayResult> Function(CheckoutParams params);
