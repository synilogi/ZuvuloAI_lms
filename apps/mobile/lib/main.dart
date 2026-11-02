import 'app/bootstrap.dart';
import 'core/config/app_config.dart';
import 'core/config/flavor.dart';
import 'main_dev.dart' show devRoutes;

/// The default entry point: plain `flutter run` builds the dev flavor (pubspec `default-flavor`)
/// and, with no define file, runs against `kDefaultApiBaseUrl` (lib/core/config/app_config.dart). Staging and prod are only
/// ever built from their own `main_<flavor>.dart`.
void main() =>
    bootstrap(Flavor.dev, devRoutes: devRoutes, readConfig: AppConfig.devFromEnvironmentOrLocal);
