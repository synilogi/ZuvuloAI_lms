// The host side of the UI tour: saves each screenshot the device sends to $UI_TOUR_OUT.
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final out = Directory(Platform.environment['UI_TOUR_OUT'] ?? 'build/ui_tour')
    ..createSync(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      File('${out.path}/$name.png').writeAsBytesSync(bytes);
      return true;
    },
  );
}
