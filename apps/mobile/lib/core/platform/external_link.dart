import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a link outside the app. A platform capability behind a provider, so a test can see
/// exactly what would be opened. Only the policies are shown in a web view, inside the app
/// (`LegalScreen`); every other link leaves for the browser (§13).
///
/// The default ([openInBrowser]) resolves to whether anything on the phone took the link; a caller
/// that must say so when nothing did reads it through [openedExternally].
typedef OpenExternalLink = Future<void> Function(Uri link);

final openExternalLinkProvider = Provider<OpenExternalLink>((ref) => openInBrowser);

/// The platform's own browser or app for this link. False when there is none to open it with.
Future<bool> openInBrowser(Uri link) => launchUrl(link, mode: LaunchMode.externalApplication);

/// Opens [link] with [open], and says whether it left the app. An opener that answers `false` — the
/// default does when no app on the phone can take the link — or throws a platform error did not
/// open it; one that answers nothing at all (a test's stand-in) counts as having opened it.
Future<bool> openedExternally(OpenExternalLink open, Uri link) async {
  try {
    final Object? answer = await (open(link) as Future<Object?>);
    return answer != false;
  } on PlatformException {
    return false;
  }
}
