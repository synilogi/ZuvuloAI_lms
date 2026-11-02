import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/config/app_config.dart';

/// A payment the gateway reported but the academy has not yet confirmed: Razorpay's order id,
/// payment id and signature, and who paid. Held only so a payment made just before the app was
/// killed is confirmed on the next visit to billing, rather than paid twice. It proves nothing on
/// its own — the academy verifies the signature with its secret, for the signed-in academy only.
typedef PendingPayment = ({String userId, String orderId, String paymentId, String signature});

/// Where a [PendingPayment] waits. The platform's secure store, like the session token; one at a
/// time, since only one checkout can be in flight.
abstract class PendingPaymentStore {
  Future<PendingPayment?> read();
  Future<void> write(PendingPayment payment);
  Future<void> clear();
}

class SecurePendingPaymentStore implements PendingPaymentStore {
  SecurePendingPaymentStore({required String environment, FlutterSecureStorage? storage})
    : _key = 'billing.pendingPayment.$environment',
      _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
          );

  final String _key;
  final FlutterSecureStorage _storage;

  @override
  Future<PendingPayment?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final payment = (
        userId: json['userId'] as String? ?? '',
        orderId: json['orderId'] as String? ?? '',
        paymentId: json['paymentId'] as String? ?? '',
        signature: json['signature'] as String? ?? '',
      );
      return payment.orderId.isEmpty || payment.paymentId.isEmpty ? null : payment;
    } on Object {
      // Unreadable is the same as absent: the academy's webhook still settles the payment.
      return null;
    }
  }

  /// Never throws: keeping the proof is a safeguard, and a storage failure must not stop the payment
  /// itself from being confirmed (the webhook remains the backstop).
  @override
  Future<void> write(PendingPayment payment) async {
    try {
      await _storage.write(
        key: _key,
        value: jsonEncode({
          'userId': payment.userId,
          'orderId': payment.orderId,
          'paymentId': payment.paymentId,
          'signature': payment.signature,
        }),
      );
    } on Object {
      return;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } on Object {
      return;
    }
  }
}

/// Held in memory only: for tests, and anywhere the platform store is unavailable.
class MemoryPendingPaymentStore implements PendingPaymentStore {
  PendingPayment? held;

  @override
  Future<PendingPayment?> read() async => held;

  @override
  Future<void> write(PendingPayment payment) async => held = payment;

  @override
  Future<void> clear() async => held = null;
}

final pendingPaymentStoreProvider = Provider<PendingPaymentStore>(
  (ref) => SecurePendingPaymentStore(environment: ref.watch(appConfigProvider).flavor.name),
);
