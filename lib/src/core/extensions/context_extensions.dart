// ============================================================
// core/extensions/context_extensions.dart
// ------------------------------------------------------------
// Ergonomic BuildContext accessors for theme + direction. Keeps call sites
// terse: `context.superTheme.fg1`, `context.isRtl`.
// ============================================================

import 'package:flutter/widgets.dart';

import '../theme/super_theme.dart';

extension SuperContextX on BuildContext {
  /// The registered [SuperThemeData] (falls back to the dark preset).
  SuperThemeData get superTheme => SuperThemeData.of(this);

  /// The ambient text direction.
  TextDirection get direction => Directionality.of(this);

  /// True when laid out right-to-left (Arabic).
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}
