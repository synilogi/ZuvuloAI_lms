import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';

AppConfig _config({
  Flavor flavor = Flavor.prod,
  String? envName,
  String api = 'https://academy.example/api',
  String web = 'https://academy.example',
}) => AppConfig.fromValues(
  flavor: flavor,
  envName: envName ?? flavor.name,
  apiBaseUrl: api,
  webBaseUrl: web,
);

void main() {
  test('reads a valid production config and trims a trailing slash', () {
    final config = _config(api: 'https://academy.example/api/');
    expect(config.apiBaseUrl.toString(), 'https://academy.example/api');
    expect(config.billingCheckoutEnabled, isFalse);
    expect(config.isDev, isFalse);
  });

  test('allows http only in the dev flavor', () {
    expect(_config(flavor: Flavor.dev, api: 'http://10.0.2.2:4100').isDev, isTrue);
    expect(
      () => _config(flavor: Flavor.staging, api: 'http://staging.example/api'),
      throwsA(isA<ConfigException>().having((e) => e.message, 'message', contains('https'))),
    );
    expect(() => _config(web: 'http://academy.example'), throwsA(isA<ConfigException>()));
  });

  test('refuses a config file from another flavor', () {
    expect(
      () => _config(flavor: Flavor.prod, envName: 'staging'),
      throwsA(
        isA<ConfigException>().having((e) => e.message, 'message', contains('config/prod.json')),
      ),
    );
  });

  test('refuses missing, relative or credential-bearing URLs', () {
    expect(() => _config(api: ''), throwsA(isA<ConfigException>()));
    expect(() => _config(api: '/api'), throwsA(isA<ConfigException>()));
    expect(
      () => _config(api: 'https://user:pw@academy.example/api'),
      throwsA(isA<ConfigException>()),
    );
    expect(() => _config(api: 'https://academy.example/api?x=1'), throwsA(isA<ConfigException>()));
  });

  test('without dart-defines the environment config fails fast with a readable message', () {
    expect(
      () => AppConfig.fromEnvironment(Flavor.dev),
      throwsA(isA<ConfigException>().having((e) => e.message, 'message', contains('dart-define'))),
    );
  });

  test('the default entry point falls back to the default server when no defines are passed', () {
    final config = AppConfig.devFromEnvironmentOrLocal();
    expect(config.flavor, Flavor.dev);
    expect(config.apiBaseUrl, Uri.parse(kDefaultApiBaseUrl));
    expect(config.webBaseUrl, Uri.parse(kDefaultWebBaseUrl));
  });
}
