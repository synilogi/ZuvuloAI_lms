import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/storage/preferences.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the dev build launches to the welcome screen with its real config', (tester) async {
    // Run with --dart-define-from-file=config/dev.json (tool/verify.sh does).
    await initializeDateFormatting('en');
    final config = AppConfig.fromEnvironment(Flavor.dev);
    final preferences = Preferences(await SharedPreferences.getInstance());

    await tester.pumpWidget(appRoot(config: config, preferences: preferences));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(config.apiBaseUrl.toString(), 'http://10.0.2.2:4100');
  });
}
