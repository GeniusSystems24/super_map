// ============================================================
// core/widgets/hairline.dart
// ------------------------------------------------------------
// A 1px solid hairline divider in the theme border color. GeniusLink borders
// are engraved-metal hairlines, never shadows-as-separators.
// ============================================================

import 'package:flutter/widgets.dart';

import '../extensions/context_extensions.dart';

/// A 1px divider. Horizontal by default; pass [vertical] for a column rule.
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.vertical = false, this.color, this.length});

  final bool vertical;
  final Color? color;

  /// Optional fixed extent along the divider's main axis (else it expands).
  final double? length;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.superTheme.border;
    return vertical
        ? Container(width: 1, height: length, color: c)
        : Container(height: 1, width: length, color: c);
  }
}
