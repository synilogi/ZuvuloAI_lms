/// A learner buying a paid course from their academy: the order summary, the academy's own Razorpay
/// checkout, the server's verdict on the payment, and the learner's purchase history. In-app buying
/// is a build switch (`COURSE_CHECKOUT_ENABLED`), off wherever store billing rules apply.
library;

export 'application/course_purchase_controller.dart';
export 'data/course_checkout_runner.dart';
export 'data/course_purchase_api.dart';
export 'data/pending_purchase_store.dart';
export 'presentation/screens/purchases_screen.dart';
export 'presentation/widgets/course_purchase_bar.dart';
