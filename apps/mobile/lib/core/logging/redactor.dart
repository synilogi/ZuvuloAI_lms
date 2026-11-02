/// Masks secrets before anything is logged or reported (modules.md §18), mirroring the backend's
/// `lib/observe.ts`: values under a sensitive key are dropped, and token-, key-, card- and
/// reset-link-shaped text is masked wherever it appears.
abstract final class Redactor {
  static const redacted = '[redacted]';

  /// A key whose value is never written, whatever it holds.
  static final _sensitiveKey = RegExp(
    r'pass(word|wd|phrase)?$|password|secret|token|authori[sz]ation|cookie|api[-_]?key|'
    r'private[-_]?key|signature|card[-_]?number|^card$|^pan$|^cvv|^cvc|^otp$|^pin$|credential|hash$',
    caseSensitive: false,
  );

  /// Patterns masked inside any string; the most specific first.
  static final List<(RegExp, String Function(Match))> _sensitiveText = [
    (
      RegExp(r'eyJ[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{5,}'),
      (_) => '[redacted-token]',
    ),
    (
      RegExp(r'\b(Bearer|Basic)\s+[A-Za-z0-9._~+/=-]{8,}', caseSensitive: false),
      (m) => '${m[1]} $redacted',
    ),
    (RegExp(r'\b(?:sk|rk|pk)_(?:live|test)_[A-Za-z0-9]{8,}'), (_) => '[redacted-key]'),
    (RegExp(r'\bwhsec_[A-Za-z0-9]{8,}'), (_) => '[redacted-key]'),
    (RegExp(r'\brzp_(?:live|test)_[A-Za-z0-9]{8,}'), (_) => '[redacted-key]'),
    (
      RegExp(r'''([?&](?:token|code|key|signature|sig)=)[^&\s"']+''', caseSensitive: false),
      (m) => '${m[1]}$redacted',
    ),
    (
      RegExp(
        r'(/(?:reset-password|invite|accept-invite|verify-email)/)[A-Za-z0-9._~-]{12,}',
        caseSensitive: false,
      ),
      (m) => '${m[1]}$redacted',
    ),
    (
      RegExp(
        r'''((?:password|passwd|secret|api[-_]?key|token)["']?\s*[=:]\s*["']?)[^\s&,;"']+''',
        caseSensitive: false,
      ),
      (m) => '${m[1]}$redacted',
    ),
    (RegExp(r'\b\d(?:[ -]?\d){12,18}\b'), (_) => '[redacted-card]'),
  ];

  static bool isSensitiveKey(String key) => _sensitiveKey.hasMatch(key);

  static String redactText(String text) {
    var out = text;
    for (final (pattern, replace) in _sensitiveText) {
      out = out.replaceAllMapped(pattern, replace);
    }
    return out;
  }

  /// A deep copy of [value] that is safe to log: sensitive keys become `[redacted]`, strings are
  /// masked, collections are capped at 50 items and 6 levels.
  static Object? redact(Object? value, [int depth = 0]) {
    if (depth > 6) return '[truncated]';
    return switch (value) {
      null || num() || bool() => value,
      String() => redactText(value),
      DateTime() => value.toUtc().toIso8601String(),
      Map<Object?, Object?>() => {
        for (final entry in value.entries)
          '${entry.key}': isSensitiveKey('${entry.key}')
              ? redacted
              : redact(entry.value, depth + 1),
      },
      Iterable<Object?>() => [for (final v in value.take(50)) redact(v, depth + 1)],
      _ => redactText(value.toString()),
    };
  }
}
