import 'package:intl/intl.dart';

/// Money is an integer count of the currency's minor unit (paise for INR) — never a `double`
/// (`packages/domain/src/money.ts`, modules.md §10.4, §21). This file only formats what the server
/// sent; it never adds, taxes or converts amounts.
abstract final class Money {
  static final _currencyCode = RegExp(r'^[A-Z]{3}$');

  /// Minor-unit digits of [currency] from the ISO 4217 data `intl` carries: 2 for INR/USD, 0 for
  /// JPY, 3 for KWD; 2 for a code it does not know.
  static int digits(String currency) =>
      NumberFormat.currency(locale: 'en', name: currency).decimalDigits ?? 2;

  /// Formats [minor] units of [currency] with Indian digit grouping: `format(399900, 'INR')` is
  /// `₹3,999.00`. The major/minor split is integer arithmetic; nothing passes through a fraction.
  /// [dropZeroFraction] renders whole amounts without decimals (`₹3,999`), as the web does for prices.
  static String format(
    int minor,
    String currency, {
    String locale = 'en_IN',
    bool dropZeroFraction = false,
  }) {
    final code = currency.toUpperCase();
    final knownShape = _currencyCode.hasMatch(code);
    final d = knownShape ? digits(code) : 2;
    final unit = _pow10(d);
    final negative = minor < 0;
    final abs = minor.abs();
    final major = abs ~/ unit;
    final fraction = abs % unit;

    final grouped = NumberFormat.decimalPattern(locale).format(major);
    final decimalSeparator = NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
    final showFraction = d > 0 && !(dropZeroFraction && fraction == 0);
    final amount = showFraction
        ? '$grouped$decimalSeparator${fraction.toString().padLeft(d, '0')}'
        : grouped;

    final symbol = knownShape
        ? NumberFormat.simpleCurrency(locale: locale, name: code).currencySymbol
        : code;
    // A code intl has no symbol for comes back as the code itself: write it as "ZZZ 12.00".
    final body = symbol == code ? '$code $amount' : '$symbol$amount';
    return negative ? '-$body' : body;
  }

  /// Formats a price stored in **whole major units** (rupees), which is how the catalogue keeps
  /// `Course.price.amount`: the academy setting behind it is validated "between ₹0 and ₹5,00,000"
  /// (`packages/domain/src/settings.ts`) and the web renders it with `formatINR` — plain rupees,
  /// no decimals (clarification A2, settled 23 Sep 2026). Subscription and invoice amounts are a
  /// different thing entirely and stay in minor units, through [format].
  static String formatMajor(int major, String currency, {String locale = 'en_IN'}) {
    final code = currency.toUpperCase();
    final d = _currencyCode.hasMatch(code) ? digits(code) : 2;
    return format(major * _pow10(d), code, locale: locale, dropZeroFraction: true);
  }

  static int _pow10(int n) {
    var v = 1;
    for (var i = 0; i < n; i++) {
      v *= 10;
    }
    return v;
  }
}

/// Whole-number counts with Indian grouping ("1,00,000"), matching the web's `formatCount`.
String formatCount(int n, {String locale = 'en_IN'}) =>
    NumberFormat.decimalPattern(locale).format(n);
