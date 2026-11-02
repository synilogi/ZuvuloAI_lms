import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

/// Turns the `/media/<id>` path the backend returns into a full URL on the API host, and refuses
/// anything pointing elsewhere: the bearer token must never be attached to another host (§13, §18).
class MediaUrlResolver {
  const MediaUrlResolver(this._apiBase);

  final Uri _apiBase;

  /// The absolute URL for a stored file, or null when [url] is not one of ours.
  Uri? resolve(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('/')) {
      if (url.startsWith('//')) return null;
      return _apiBase.replace(path: '${_apiBase.path}$url');
    }
    final parsed = Uri.tryParse(url);
    if (parsed == null || !parsed.hasScheme) return null;
    // An absolute URL is only ours when it is the API host, over the same scheme and port.
    final sameOrigin =
        parsed.scheme == _apiBase.scheme &&
        parsed.host == _apiBase.host &&
        parsed.port == _apiBase.port;
    return sameOrigin ? parsed : null;
  }

  /// Whether the bearer token may be sent to [url].
  bool isOurs(String? url) => resolve(url) != null;
}

final mediaUrlResolverProvider = Provider<MediaUrlResolver>(
  (ref) => MediaUrlResolver(ref.watch(appConfigProvider).apiBaseUrl),
);
