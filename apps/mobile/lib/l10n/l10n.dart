import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// `context.l10n.actionRetry` — every user-facing string comes from `app_en.arb` (§21).
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
