import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/network/token_store.dart';

/// A validated config pointing at a fake host, for tests that never touch the network.
/// [billingCheckoutEnabled] stands for a build approved to take payments (C4); off, as shipped.
/// [courseCheckoutEnabled] stands for a build that sells courses in the app; off, as shipped.
AppConfig testConfig({
  String api = 'https://api.test/api',
  bool billingCheckoutEnabled = false,
  bool courseCheckoutEnabled = false,
}) => AppConfig.fromValues(
  flavor: Flavor.prod,
  envName: 'prod',
  apiBaseUrl: api,
  webBaseUrl: 'https://web.test',
  billingCheckoutEnabled: billingCheckoutEnabled,
  courseCheckoutEnabled: courseCheckoutEnabled,
);

/// A token store whose value the test can change.
class FakeTokenStore implements TokenStore {
  FakeTokenStore([this.token]);

  String? token;
  int reads = 0;

  @override
  Future<String?> read() async {
    reads++;
    return token;
  }
}
