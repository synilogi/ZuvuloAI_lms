import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';

part 'course_purchase.freezed.dart';
part 'course_purchase.g.dart';

/// `CoursePurchaseStatus` (`packages/domain/src/catalog.ts`): `created` until the gateway confirms,
/// `paid` once it did (the course is open), or neither. [unknown] keeps a value added later from
/// crashing the app, and is never read as paid.
enum CoursePurchaseStatus { created, paid, failed, expired, unknown }

/// A learner's purchase of one course, as `/learning/purchases…` shows it to them. [amount] is the
/// charge in **paise**; [listPrice] the course's price in whole rupees when the order was made. Both
/// are the server's figures — the app formats them and never computes either.
@freezed
abstract class CoursePurchase with _$CoursePurchase {
  const factory CoursePurchase({
    required String id,
    @Default('') String courseId,
    @Default('') String courseTitle,
    @JsonKey(unknownEnumValue: CoursePurchaseStatus.unknown)
    @Default(CoursePurchaseStatus.unknown)
    CoursePurchaseStatus status,
    @Default(0) int amount,
    @Default('INR') String currency,
    @Default(0) int listPrice,

    /// Whether the course is open to the learner now — the only "it worked" the app believes.
    @Default(false) bool enrolled,
    String? failureMessage,

    /// Money the gateway took that opened nothing: the academy reviews it.
    @Default(false) bool needsReview,
    @NullableUtcDateTimeConverter() DateTime? createdAt,
    @NullableUtcDateTimeConverter() DateTime? paidAt,
  }) = _CoursePurchase;

  const CoursePurchase._();

  factory CoursePurchase.fromJson(Map<String, dynamic> json) => _$CoursePurchaseFromJson(json);

  /// Settled one way or the other: nothing more will happen to it without a new order.
  bool get isSettled =>
      status == CoursePurchaseStatus.paid ||
      status == CoursePurchaseStatus.failed ||
      status == CoursePurchaseStatus.expired;
}

/// Who is paying, for the gateway form's prefill only.
@freezed
abstract class CheckoutPrefill with _$CheckoutPrefill {
  const factory CheckoutPrefill({@Default('') String name, @Default('') String email}) =
      _CheckoutPrefill;

  factory CheckoutPrefill.fromJson(Map<String, dynamic> json) => _$CheckoutPrefillFromJson(json);
}

/// What the gateway's checkout is opened with, exactly as the server pinned it. [keyId] is the
/// academy's **publishable** key for this one checkout; it is never stored. [amount] is paise.
@freezed
abstract class CourseCheckout with _$CourseCheckout {
  const factory CourseCheckout({
    @Default('') String provider,
    String? keyId,
    @Default('') String orderId,
    @Default(0) int amount,
    @Default('INR') String currency,
    String? redirectUrl,
    @Default('') String description,
    CheckoutPrefill? prefill,
  }) = _CourseCheckout;

  factory CourseCheckout.fromJson(Map<String, dynamic> json) => _$CourseCheckoutFromJson(json);
}

/// `POST /learning/courses/:courseId/purchase` — the learner's open order and its checkout.
@freezed
abstract class CoursePurchaseStart with _$CoursePurchaseStart {
  const factory CoursePurchaseStart({
    required CoursePurchase purchase,
    required CourseCheckout checkout,
  }) = _CoursePurchaseStart;

  factory CoursePurchaseStart.fromJson(Map<String, dynamic> json) =>
      _$CoursePurchaseStartFromJson(json);
}

/// The server's verdict on a confirmation. `pending`: the bank has not settled it yet.
enum PurchaseOutcomeStatus { paid, failed, pending, created, unknown }

@freezed
abstract class PurchaseOutcome with _$PurchaseOutcome {
  const factory PurchaseOutcome({
    @JsonKey(unknownEnumValue: PurchaseOutcomeStatus.unknown)
    @Default(PurchaseOutcomeStatus.unknown)
    PurchaseOutcomeStatus status,
    @Default(false) bool enrolled,
    @Default('') String message,
  }) = _PurchaseOutcome;

  factory PurchaseOutcome.fromJson(Map<String, dynamic> json) => _$PurchaseOutcomeFromJson(json);
}

/// `POST /learning/purchases/:purchaseId/confirm` — the purchase as it now stands, and the verdict.
@freezed
abstract class PurchaseConfirmation with _$PurchaseConfirmation {
  const factory PurchaseConfirmation({
    required CoursePurchase purchase,
    required PurchaseOutcome outcome,
  }) = _PurchaseConfirmation;

  factory PurchaseConfirmation.fromJson(Map<String, dynamic> json) =>
      _$PurchaseConfirmationFromJson(json);
}
