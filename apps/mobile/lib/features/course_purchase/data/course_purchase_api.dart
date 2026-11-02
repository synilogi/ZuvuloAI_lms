import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import 'dto/course_purchase.dart';

/// `apps/api/src/routes/courseSales.ts` — a learner buying a paid course from their academy. The app
/// names only the course: the amount, the currency, the academy and the learner are the server's,
/// and nothing here sends any of them.
class CoursePurchaseApi {
  CoursePurchaseApi(this._client);

  final ApiClient _client;

  /// Opens the learner's order for [courseId], or the open one again. 409 `ALREADY_ENROLLED`,
  /// `COURSE_NOT_FOR_SALE` or `PAYMENTS_NOT_SET_UP` say why not.
  Future<CoursePurchaseStart> start(String courseId) async {
    const endpoint = 'POST /learning/courses/:courseId/purchase';
    final body = await _client.post(
      ApiPath.of(['learning', 'courses', ApiPath.id(courseId), 'purchase']),
    );
    return parseResponse(
      endpoint,
      body,
      (b) => CoursePurchaseStart.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Hands the gateway's payment id and signature to the server, which checks them and then asks
  /// the gateway itself before anything opens.
  Future<PurchaseConfirmation> confirm(
    String purchaseId, {
    required String paymentId,
    required String signature,
  }) async {
    const endpoint = 'POST /learning/purchases/:purchaseId/confirm';
    final body = await _client.post(
      ApiPath.of(['learning', 'purchases', ApiPath.id(purchaseId), 'confirm']),
      body: {'paymentId': paymentId, 'signature': signature},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => PurchaseConfirmation.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Where a purchase stands. While it is open the server asks the gateway first, so this is also
  /// how a payment made before the app closed is picked up.
  Future<CoursePurchase> purchase(String purchaseId) async {
    const endpoint = 'GET /learning/purchases/:purchaseId';
    final body = await _client.get(ApiPath.of(['learning', 'purchases', ApiPath.id(purchaseId)]));
    return parseResponse(endpoint, body, (b) => CoursePurchase.fromJson(asJsonObject(endpoint, b)));
  }

  /// The learner's purchases, newest first.
  Future<List<CoursePurchase>> purchases() async {
    const endpoint = 'GET /learning/purchases';
    final body = await _client.get('/learning/purchases');
    return parseResponse(endpoint, body, (b) {
      final rows = asJsonObject(endpoint, b)['rows'];
      return [
        for (final row in asJsonList(endpoint, rows))
          CoursePurchase.fromJson(row as Map<String, dynamic>),
      ];
    });
  }
}

final coursePurchaseApiProvider = Provider<CoursePurchaseApi>(
  (ref) => CoursePurchaseApi(ref.watch(apiClientProvider)),
);
