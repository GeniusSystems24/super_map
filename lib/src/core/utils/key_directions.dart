// ============================================================
// core/utils/key_directions.dart
// ------------------------------------------------------------
// Direction-aware keyboard helpers shared by every component that navigates a
// horizontal axis with the arrow keys (table, tree, tab bar, sidebar).
//
// Navigation state is a logical index, but in an RTL layout that index axis is
// mirrored on screen. A naive `arrowRight -> index + 1` therefore moves the
// highlight to the *left* in Arabic. These helpers keep the **visual** meaning
// of the key intact in both directions.
// ============================================================

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Resolves a horizontal arrow [key] to a logical index *step* for text [dir].
/// Returns `+1` / `-1` for right/left (mirrored under RTL), else `0`.
int horizontalStep(LogicalKeyboardKey key, TextDirection dir) {
  final rtl = dir == TextDirection.rtl;
  if (key == LogicalKeyboardKey.arrowRight) return rtl ? -1 : 1;
  if (key == LogicalKeyboardKey.arrowLeft) return rtl ? 1 : -1;
  return 0;
}

/// True when a horizontal arrow [key] points *toward deeper nesting* for [dir]
/// — the arrow a tree treats as expand / step-in (right in LTR, left in RTL).
bool arrowGoesInto(LogicalKeyboardKey key, TextDirection dir) =>
    horizontalStep(key, dir) > 0;

/// True when the platform's primary command modifier is held (⌘ on macOS,
/// Ctrl elsewhere). Use for copy/paste/select-all/undo shortcuts.
bool isCommandPressed(Set<LogicalKeyboardKey> pressed) {
  return pressed.contains(LogicalKeyboardKey.metaLeft) ||
      pressed.contains(LogicalKeyboardKey.metaRight) ||
      pressed.contains(LogicalKeyboardKey.controlLeft) ||
      pressed.contains(LogicalKeyboardKey.controlRight);
}
