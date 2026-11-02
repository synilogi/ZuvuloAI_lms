import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/network/error_decoder.dart';
import 'package:syniastrolms_mobile/features/course_purchase/course_purchase.dart';
import 'package:syniastrolms_mobile/features/public_catalog/public_catalog.dart';
import 'package:syniastrolms_mobile/l10n/generated/app_localizations_en.dart';
import 'package:syniastrolms_mobile/shared/domain/people.dart';

/// A catalogue course with the pricing under test.
Course _course({String? pricing, Map<String, dynamic>? price}) => Course.fromJson({
  'id': 'c1',
  'slug': 'c1',
  'title': 'Class 10 Mathematics',
  'levelId': 'l1',
  'categoryId': 'k1',
  'pricing': ?pricing,
  'price': ?price,
});

const _inr = {'amount': 2999, 'currency': 'INR'};

void main() {
  group('how a course is joined (courseSale in packages/domain)', () {
    test('free is free, whatever price it carries', () {
      expect(_course(pricing: 'free').sale, const FreeCourseSale());
      expect(_course(pricing: 'free', price: _inr).sale, const FreeCourseSale());
    });

    test('paid with a valid whole-rupee INR price is for sale at that price', () {
      expect(
        _course(pricing: 'paid', price: _inr).sale,
        const PaidCourseSale(Price(amount: 2999, currency: 'INR')),
      );
      expect(
        _course(pricing: 'paid', price: {'amount': 1, 'currency': 'INR'}).sale,
        isA<PaidCourseSale>(),
      );
      expect(
        _course(pricing: 'paid', price: {'amount': 500000, 'currency': 'INR'}).sale,
        isA<PaidCourseSale>(),
      );
    });

    test('a paid course without a valid price is never free: it is not open', () {
      for (final price in <Map<String, dynamic>?>[
        null,
        {'amount': 0, 'currency': 'INR'},
        {'amount': -5, 'currency': 'INR'},
        {'amount': 600000, 'currency': 'INR'},
        {'amount': 2999, 'currency': 'USD'},
      ]) {
        expect(
          _course(pricing: 'paid', price: price).sale,
          const UnavailableCourseSale(),
          reason: '$price',
        );
      }
    });

    test('unset, and a value from a later server, are not open to anyone', () {
      expect(_course(pricing: 'unset', price: _inr).sale, const UnavailableCourseSale());
      expect(_course(pricing: 'by-invitation', price: _inr).sale, const UnavailableCourseSale());
    });

    test('a course from before pricing existed reads as the domain does', () {
      expect(
        _course(price: _inr).sale,
        const UnavailableCourseSale(),
        reason: 'a price, no decision',
      );
      expect(_course().sale, const FreeCourseSale(), reason: 'no price at all');
    });

    test('the price label says Free, the price, or that it is not open yet', () {
      final l10n = AppLocalizationsEn();
      expect(coursePriceLabel(l10n, _course(pricing: 'free', price: _inr)), 'Free');
      expect(coursePriceLabel(l10n, _course(pricing: 'paid', price: _inr)), '₹2,999');
      expect(coursePriceLabel(l10n, _course(pricing: 'unset', price: _inr)), 'Not open yet');
    });
  });

  group('the purchase routes as the API answers them', () {
    test('a started purchase: the order in paise, the checkout with only a publishable key', () {
      final start = CoursePurchaseStart.fromJson({
        'purchase': {
          'id': 'p1',
          'courseId': 'c1',
          'courseTitle': 'Class 10 Mathematics',
          'status': 'created',
          'amount': 299900,
          'currency': 'INR',
          'listPrice': 2999,
          'enrolled': false,
          'createdAt': '2026-10-23T05:00:00.000Z',
        },
        'checkout': {
          'provider': 'razorpay',
          'keyId': 'rzp_test_public',
          'orderId': 'order_1',
          'amount': 299900,
          'currency': 'INR',
          'description': 'Class 10 Mathematics',
          'prefill': {'name': 'Ananya Rao', 'email': 'learner@example.test'},
        },
      });
      expect(start.purchase.status, CoursePurchaseStatus.created);
      expect(start.purchase.amount, 299900);
      expect(start.purchase.listPrice, 2999);
      expect(start.purchase.isSettled, isFalse);
      expect(start.purchase.createdAt, DateTime.utc(2026, 10, 23, 5));
      expect(start.checkout.orderId, 'order_1');
      expect(start.checkout.prefill?.email, 'learner@example.test');
      expect(canRunNatively(start.checkout), isTrue);
    });

    test('a confirmation carries the server\'s verdict; an unknown status is never paid', () {
      final answer = PurchaseConfirmation.fromJson({
        'purchase': {
          'id': 'p1',
          'status': 'paid',
          'enrolled': true,
          'paidAt': '2026-10-23T05:01:00.000Z',
        },
        'outcome': {
          'status': 'paid',
          'enrolled': true,
          'message': 'Payment confirmed. The course is open.',
        },
      });
      expect(answer.outcome.status, PurchaseOutcomeStatus.paid);
      expect(answer.purchase.isSettled, isTrue);
      expect(answer.purchase.paidAt, isNotNull);

      final later = CoursePurchase.fromJson({'id': 'p2', 'status': 'refund-pending'});
      expect(later.status, CoursePurchaseStatus.unknown);
      expect(later.enrolled, isFalse);
      expect(later.isSettled, isFalse);
      expect(
        PurchaseOutcome.fromJson({'status': 'something-new'}).status,
        PurchaseOutcomeStatus.unknown,
      );
    });

    test('a review flag and a failure message are read', () {
      final p = CoursePurchase.fromJson({
        'id': 'p3',
        'status': 'created',
        'failureMessage': 'Card declined.',
        'needsReview': true,
      });
      expect(p.failureMessage, 'Card declined.');
      expect(p.needsReview, isTrue);
    });

    test('only an https page (http in dev) is opened for a hosted checkout', () {
      const http = CourseCheckout(
        provider: 'sandbox',
        redirectUrl: 'http://localhost:5173/sandbox-checkout/o1',
      );
      const https = CourseCheckout(provider: 'other', redirectUrl: 'https://pay.example/o1');
      expect(hostedCheckoutPage(https, allowHttp: false), Uri.parse('https://pay.example/o1'));
      expect(hostedCheckoutPage(http, allowHttp: false), isNull);
      expect(hostedCheckoutPage(http, allowHttp: true), isNotNull);
      expect(canRunNatively(http), isFalse);
      expect(
        canRunNatively(const CourseCheckout(provider: 'razorpay', orderId: 'o', amount: 1)),
        isFalse,
        reason: 'no key id',
      );
    });

    test('the Razorpay options are the server\'s order exactly', () {
      const checkout = CourseCheckout(
        provider: 'razorpay',
        keyId: 'rzp_test_public',
        orderId: 'order_1',
        amount: 299900,
        description: 'Class 10 Mathematics',
        prefill: CheckoutPrefill(name: 'Ananya Rao', email: 'learner@example.test'),
      );
      final options = RazorpayCourseCheckout.optionsFor(checkout);
      expect(options['key'], 'rzp_test_public');
      expect(options['order_id'], 'order_1');
      expect(options['amount'], 299900);
      expect(options['currency'], 'INR');
      expect(options['prefill'], {'name': 'Ananya Rao', 'email': 'learner@example.test'});
    });
  });

  group('the refusals the course routes send', () {
    test('each course-sale code decodes to its own problem, still a conflict', () {
      for (final (code, problem) in [
        ('COURSE_PURCHASE_REQUIRED', CourseSaleProblem.purchaseRequired),
        ('COURSE_NOT_FOR_SALE', CourseSaleProblem.notForSale),
        ('PAYMENTS_NOT_SET_UP', CourseSaleProblem.paymentsNotSetUp),
        ('ALREADY_ENROLLED', CourseSaleProblem.alreadyEnrolled),
      ]) {
        final failure = ErrorDecoder.fromResponse(409, {
          'message': 'Said by the server.',
          'code': code,
        });
        expect(failure, isA<CourseSaleFailure>().having((f) => f.problem, 'problem', problem));
        expect(failure, isA<ConflictFailure>().having((f) => f.code, 'code', code));
        expect(failure.message, 'Said by the server.');
      }
    });

    test('another 409 stays a plain conflict', () {
      final failure = ErrorDecoder.fromResponse(409, {'message': 'Busy.', 'code': 'CONFLICT'});
      expect(failure, isNot(isA<CourseSaleFailure>()));
      expect(failure, isA<ConflictFailure>());
    });

    test('a signature that did not verify is a payment failure with the server\'s words', () {
      final failure = ErrorDecoder.fromResponse(400, {
        'message': 'Not verified.',
        'code': 'PAYMENT_FAILED',
      });
      expect(failure, isA<PaymentFailure>().having((f) => f.message, 'message', 'Not verified.'));
      expect(ErrorDecoder.fromResponse(400, {'message': 'Bad.'}), isA<ValidationFailure>());
    });
  });

  test('an enrolment opened by a purchase reads as purchased', () {
    final enrollment = Enrollment.fromJson({
      'id': 'e1',
      'studentId': 's1',
      'courseId': 'c1',
      'source': 'purchase',
    });
    expect(enrollment.source, EnrollmentSource.purchase);
    expect(
      Enrollment.fromJson({'id': 'e2', 'source': 'a-later-source'}).source,
      EnrollmentSource.unknown,
    );
  });

  test('the pending purchases are stored as ids only, and anything unreadable is dropped', () {
    const held = (userId: 'u1', purchaseId: 'p1', courseId: 'c1');
    final raw = encodePendingPurchases([held]);
    expect(decodePendingPurchases(raw), [held]);
    expect(raw, isNot(contains('rzp_')));
    expect(decodePendingPurchases('[{"userId":"u1"},{"purchaseId":""},3]'), isEmpty);
    expect(decodePendingPurchases('{}'), isEmpty);
  });

  test('a build without the define sells nothing in the app', () {
    final config = AppConfig.fromValues(
      flavor: Flavor.prod,
      envName: 'prod',
      apiBaseUrl: 'https://academy.example/api',
      webBaseUrl: 'https://academy.example',
    );
    expect(config.courseCheckoutEnabled, isFalse);
  });
}
