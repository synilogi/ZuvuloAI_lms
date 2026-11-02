import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/config/app_config.dart';

/// A course purchase whose checkout was opened but which the server has not settled: whose it is,
/// the purchase, and its course. Only the ids — never an amount, a key or a signature — so the app
/// can ask `GET /learning/purchases/:id` again after it was closed mid-payment. It proves nothing:
/// the server alone says whether the course opened.
typedef PendingCoursePurchase = ({String userId, String purchaseId, String courseId});

/// Where [PendingCoursePurchase]s wait, one per course at most.
abstract class PendingPurchaseStore {
  Future<List<PendingCoursePurchase>> read();
  Future<void> write(PendingCoursePurchase purchase);
  Future<void> remove(String purchaseId);
}

/// The platform's secure store, like the session token and the billing checkout. Never throws:
/// keeping the ids is a safeguard, and the server's recovery job settles a payment regardless.
class SecurePendingPurchaseStore implements PendingPurchaseStore {
  SecurePendingPurchaseStore({required String environment, FlutterSecureStorage? storage})
    : _key = 'courses.pendingPurchases.$environment',
      _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
          );

  final String _key;
  final FlutterSecureStorage _storage;

  @override
  Future<List<PendingCoursePurchase>> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return const [];
      return decodePendingPurchases(raw);
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> write(PendingCoursePurchase purchase) async {
    try {
      final held = await read();
      await _storage.write(
        key: _key,
        value: encodePendingPurchases([
          for (final p in held)
            if (p.purchaseId != purchase.purchaseId && p.courseId != purchase.courseId) p,
          purchase,
        ]),
      );
    } on Object {
      return;
    }
  }

  @override
  Future<void> remove(String purchaseId) async {
    try {
      final left = [
        for (final p in await read())
          if (p.purchaseId != purchaseId) p,
      ];
      if (left.isEmpty) {
        await _storage.delete(key: _key);
      } else {
        await _storage.write(key: _key, value: encodePendingPurchases(left));
      }
    } on Object {
      return;
    }
  }
}

/// The stored form: a JSON list of `{userId, purchaseId, courseId}`.
String encodePendingPurchases(List<PendingCoursePurchase> purchases) => jsonEncode([
  for (final p in purchases)
    {'userId': p.userId, 'purchaseId': p.purchaseId, 'courseId': p.courseId},
]);

/// Reads [encodePendingPurchases]' output; anything unreadable is left out.
List<PendingCoursePurchase> decodePendingPurchases(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! List) return const [];
  return [
    for (final row in decoded)
      if (row is Map &&
          row['userId'] is String &&
          row['purchaseId'] is String &&
          (row['purchaseId'] as String).isNotEmpty &&
          row['courseId'] is String)
        (
          userId: row['userId'] as String,
          purchaseId: row['purchaseId'] as String,
          courseId: row['courseId'] as String,
        ),
  ];
}

/// Held in memory only: for tests, and anywhere the platform store is unavailable.
class MemoryPendingPurchaseStore implements PendingPurchaseStore {
  final List<PendingCoursePurchase> held = [];

  @override
  Future<List<PendingCoursePurchase>> read() async => List.of(held);

  @override
  Future<void> write(PendingCoursePurchase purchase) async {
    held
      ..removeWhere((p) => p.purchaseId == purchase.purchaseId || p.courseId == purchase.courseId)
      ..add(purchase);
  }

  @override
  Future<void> remove(String purchaseId) async =>
      held.removeWhere((p) => p.purchaseId == purchaseId);
}

final pendingPurchaseStoreProvider = Provider<PendingPurchaseStore>(
  (ref) => SecurePendingPurchaseStore(environment: ref.watch(appConfigProvider).flavor.name),
);
