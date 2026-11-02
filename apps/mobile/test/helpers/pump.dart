import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/theme/theme.dart';
import 'package:syniastrolms_mobile/l10n/l10n.dart';

/// Wraps [child] in the app's theme and localizations on a scrolling page.
Widget themedHarness(
  Widget child, {
  bool dark = false,
  double textScale = 1,
  bool reduceMotion = false,
  bool scroll = true,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale), disableAnimations: reduceMotion),
      child: app!,
    ),
    home: Scaffold(
      body: scroll
          ? SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)
          : Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

/// Pumps [child] at phone width (compact, 360 dp) unless [size] says otherwise.
Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  double textScale = 1,
  bool reduceMotion = false,
  Size size = const Size(360, 800),
  bool scroll = true,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    themedHarness(
      child,
      dark: dark,
      textScale: textScale,
      reduceMotion: reduceMotion,
      scroll: scroll,
    ),
  );
  await tester.pump(const Duration(milliseconds: 700));
}

/// Asserts the widget found by [finder] is at least 48×48 dp (§19).
void expectMinTapTarget(WidgetTester tester, Finder finder, {double min = 48}) {
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(min), reason: 'tap target width ${size.width}');
  expect(size.height, greaterThanOrEqualTo(min), reason: 'tap target height ${size.height}');
}
