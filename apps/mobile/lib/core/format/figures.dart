/// How the app writes a figure the server counted (§22.7). No rounding decisions live here beyond
/// presentation: the value itself is always the server's.
library;

/// A figure as a person reads it: no trailing `.0`, and one decimal on a rate.
String formatFigure(num value) =>
    value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);
