// ============================================================
// core/constants/super_constants.dart
// ------------------------------------------------------------
// Misc kit-wide constants not tied to color or spacing (those live in
// SuperTokens). Keyboard hit-target floors, breakpoints, and clamp limits.
// ============================================================

/// Kit-wide non-visual constants.
abstract final class SuperConstants {
  /// Minimum interactive hit target (accessibility floor).
  static const double minHitTarget = 44;

  /// Column resize clamp (shared by tables).
  static const double columnMinWidth = 64;
  static const double columnMaxWidth = 520;

  /// Responsive breakpoints for the navigation sidebar.
  static const double sidebarExpandedMin = 1200; // >= expanded
  static const double sidebarRailMin = 768; //     >= rail, else drawer

  /// Default debounce for async suggestion / search fetches.
  static const Duration searchDebounce = Duration(milliseconds: 220);
}
