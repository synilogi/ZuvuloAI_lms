import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/theme.dart';
import '../l10n/l10n.dart';

/// Shown instead of the app when the build's configuration is invalid (§24). Dev builds show the
/// reason so the developer can fix the run command; other builds show only the title.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({required this.message, required this.showDetail, super.key});

  final String message;
  final bool showDetail;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Space.s5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(context.l10n.configErrorTitle, style: context.type.titleL),
                  ),
                  if (showDetail) ...[
                    const SizedBox(height: Space.s3),
                    SelectableText(message, style: context.type.bodyM),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
