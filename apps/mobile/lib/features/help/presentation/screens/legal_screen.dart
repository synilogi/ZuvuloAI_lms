import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/platform/external_link.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';

/// Which policy a legal screen shows, and where the web publishes it (`apps/web` serves
/// `/privacy` and `/terms`).
enum LegalDocument {
  privacy('/privacy'),
  terms('/terms');

  const LegalDocument(this.webPath);

  final String webPath;
}

/// The policy as the web publishes it, asked for without the site's header and footer
/// (`?embed=app`, `MarketingChrome` in `apps/web`): the app supplies its own title bar.
Uri legalPageUrl(Uri webBaseUrl, LegalDocument document) => webBaseUrl.replace(
  path: '${webBaseUrl.path}${document.webPath}',
  queryParameters: const {'embed': 'app'},
);

/// Whether a page the policy links to opens inside the app: only another policy on the same site.
/// Anything else — the rest of the website, another site, an email address — leaves for the
/// browser or mail app, so the in-app view never becomes a browser.
bool legalPageStaysInApp(Uri target, Uri webBaseUrl) =>
    target.scheme == webBaseUrl.scheme &&
    target.host == webBaseUrl.host &&
    target.port == webBaseUrl.port &&
    LegalDocument.values.any((d) => target.path == '${webBaseUrl.path}${d.webPath}');

/// Draws the page at a URL. The platform's web view in the app; a test provides its own.
typedef LegalPageView = Widget Function(Uri url);

final legalPageViewProvider = Provider<LegalPageView>(
  (ref) =>
      (url) => _LegalWebView(url: url),
);

/// `/legal/privacy` and `/legal/terms`: the policy in force, shown inside the app. The web publishes
/// one text, so what a person reads is always the current version — the app ships no copy that
/// could fall out of date, and there is no API for it.
class LegalScreen extends ConsumerWidget {
  const LegalScreen({required this.document, super.key});

  final LegalDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final title = switch (document) {
      LegalDocument.privacy => l10n.legalPrivacyTitle,
      LegalDocument.terms => l10n.legalTermsTitle,
    };
    final url = legalPageUrl(ref.watch(appConfigProvider).webBaseUrl, document);

    return UpPopScope(
      fallback: AppRoutes.welcome,
      child: Scaffold(
        appBar: CommonAppBar(
          leading: upButton(context, fallback: AppRoutes.welcome),
          title: title,
        ),
        body: SafeArea(child: ref.watch(legalPageViewProvider)(url)),
      ),
    );
  }
}

class _LegalWebView extends ConsumerStatefulWidget {
  const _LegalWebView({required this.url});

  final Uri url;

  @override
  ConsumerState<_LegalWebView> createState() => _LegalWebViewState();
}

class _LegalWebViewState extends ConsumerState<_LegalWebView> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final web = ref.read(appConfigProvider).webBaseUrl;
    _controller = WebViewController()
      // The site is a single-page app: without scripts there is no text to show.
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              if (mounted) setState(() => _failed = true);
            }
          },
          onNavigationRequest: (request) {
            if (!request.isMainFrame) return NavigationDecision.navigate;
            final target = Uri.tryParse(request.url);
            if (target != null && legalPageStaysInApp(target, web)) {
              return NavigationDecision.navigate;
            }
            if (target != null) ref.read(openExternalLinkProvider)(target);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(widget.url);
  }

  void _retry() {
    setState(() {
      _failed = false;
      _loading = true;
    });
    _controller.loadRequest(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return ErrorState(onRetry: _retry);
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2, color: context.colors.accent),
          ),
      ],
    );
  }
}
