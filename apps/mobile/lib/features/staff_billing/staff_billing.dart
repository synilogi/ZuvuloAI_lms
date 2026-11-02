/// The academy's own subscription: what it is on, what it is using, its invoices and payments, the
/// plans on sale, and a provider-agnostic checkout the academy itself drives (FLUTTER-027) — and the
/// plan-aware workspace built on it: the free trial a new academy starts itself, the choose-a-plan
/// screen, and the gate a module shows when the plan does not open it.
library;

export 'application/checkout_launcher.dart';
export 'application/staff_billing_controller.dart';
export 'application/trial_controller.dart';
export 'data/dto/billing.dart';
export 'data/staff_billing_api.dart';
export 'presentation/screens/billing_screen.dart';
export 'presentation/screens/choose_plan_screen.dart';
export 'presentation/screens/invoice_screen.dart';
export 'presentation/screens/plan_gate_screen.dart';
export 'presentation/screens/plans_screen.dart';
export 'presentation/widgets/billing_parts.dart';
export 'presentation/widgets/checkout_parts.dart';
export 'presentation/widgets/onboarding_parts.dart';
