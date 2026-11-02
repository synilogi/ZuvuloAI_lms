import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Initialises date-format locale data (as `bootstrap` does) and loads every font in the app's font manifest (the bundled Fraunces / Plus Jakarta Sans and the
/// Phosphor icon fonts) so widget and golden tests render real glyphs instead of the test font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(family['family'] as String);
    for (final font in (family['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
  await initializeDateFormatting('en');
  await testMain();
}
