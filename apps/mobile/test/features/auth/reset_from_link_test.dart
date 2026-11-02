import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

/// A reset link usually *opens* the app on the reset screen, so nothing sits beneath it. Its "Sign in"
/// must still reach the sign-in form (LIVE E2E AUTH-023 found the button did nothing).
const _token = '3f9a1c7e20b84d65af0e2d19c8b73540e6a92f14bc385d70a1fe6b29d4c80713';

void main() {
  testWidgets('after a reset opened from a link, Sign in reaches the sign-in form', (tester) async {
    final adapter = FakeAdapter()
      ..handler = (options) async => options.path.contains('/auth/reset-password/')
          ? FakeAdapter.jsonResponse({'valid': true})
          : FakeAdapter.jsonResponse({'ok': true});
    await pumpPublicRouter(
      tester,
      adapter: adapter,
      initialLocation: AppRoutes.resetPassword(_token),
      routes: [
        GoRoute(path: AppRoutes.welcome, builder: (_, _) => const Text('screen:welcome')),
        GoRoute(path: AppRoutes.login, builder: (_, _) => const Text('screen:login')),
        GoRoute(
          path: AppRoutes.resetPasswordPattern,
          builder: (_, state) => ResetPasswordScreen(token: state.pathParameters['token']!),
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'a-new-password-1');
    await tester.enterText(find.byType(TextField).at(1), 'a-new-password-1');
    await tester.tap(find.widgetWithText(AppButton, 'Save password'));
    await tester.pumpAndSettle();
    expect(find.text('Password updated'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('screen:login'), findsOneWidget);
  });
}
