import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// Width classes (§20): compact < 600, medium 600–1023, expanded ≥ 1024.
enum WindowSize {
  compact,
  medium,
  expanded;

  static WindowSize forWidth(double width) {
    if (width >= 1024) return WindowSize.expanded;
    if (width >= 600) return WindowSize.medium;
    return WindowSize.compact;
  }

  static WindowSize of(BuildContext context) => forWidth(MediaQuery.sizeOf(context).width);

  bool get isCompact => this == WindowSize.compact;

  /// Wide enough for a list and what it opens, side by side (§20).
  bool get isExpanded => this == WindowSize.expanded;

  /// Screen gutter: 16 on phones, 24 from medium up.
  double get gutter => isCompact ? Space.gutterCompact : Space.gutterMedium;
}
