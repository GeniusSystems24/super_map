// ============================================================
// core/theme/super_tokens.dart
// ------------------------------------------------------------
// Theme-INDEPENDENT brand constants for the GeniusLink design system — the
// values that never change between light and dark: the accent + semantic
// palette, the raw neutral ramps, font families, radii, the 4px spacing scale,
// control metrics, motion curves, and elevation. Swappable surfaces (the
// colors that flip dark <-> light) live in `SuperThemeData`.
//
// Ported from `colors_and_type.css`.
// ============================================================

import 'package:flutter/widgets.dart';

/// Immutable brand constants. Never instantiated — `SuperTokens.accent`, etc.
abstract final class SuperTokens {
  // ── Brand + semantic palette ──────────────────────────────────────────────
  /// The single dominant electric-royal-blue accent.
  static const Color accent = Color(0xFF4A7CFF);
  static const Color accentHover = Color(0xFF5E8DFF); // +6% lightness on hover
  static const Color accentPressed = Color(0xFF3D6DEB); // darkens on press

  static const Color success = Color(0xFF1DB88A); // green — ledger / balance
  static const Color warning = Color(0xFFF97316); // orange — notes / docs
  static const Color danger = Color(0xFFEF4444); // red — destructive / errors

  // ── Typography ─────────────────────────────────────────────────────────────
  static const String displayFont = 'Manrope'; // H1 page titles, watermark
  static const String bodyFont = 'Inter'; // headings, body, labels, captions
  static const String monoFont = 'JetBrainsMono'; // numerics, serials, audit
  static const String arabicFont = 'NotoNaskhArabic'; // Arabic glyphs

  // ── Radii ───────────────────────────────────────────────────────────────────
  static const double radiusControl = 4; // inputs, buttons
  static const double radiusMd = 6;
  static const double radiusCard = 8; // section cards (default)
  static const double radiusPill = 12; // status pills, section-marker bar

  // ── Spacing scale (4px base unit) ────────────────────────────────────────────
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space16 = 64;
  static const double space20 = 80;

  // ── Control metrics ──────────────────────────────────────────────────────────
  static const double controlHeight = 40; // inputs + buttons
  static const double iconButton = 32; // 32x32 icon buttons
  static const double markerWidth = 4; // section-marker bar width
  static const double markerHeight = 40; // section-marker bar height
  static const double contentColumn = 680; // centered page content width

  // ── Motion ───────────────────────────────────────────────────────────────────
  static const Duration durFast = Duration(milliseconds: 100);
  static const Duration durBase = Duration(milliseconds: 150); // color/bg
  static const Duration durExpand = Duration(milliseconds: 200); // accordion
  static const Curve curveStandard = Cubic(0.4, 0, 0.2, 1); // ease
  static const Curve curveOut = Cubic(0, 0, 0.2, 1); // ease-out

  // ── Section-marker bar intent colors ─────────────────────────────────────────
  /// Blue — primary identity / definition / details sections.
  static const Color markerIdentity = accent;

  /// Green — financial / balance / ledger / transfer sections.
  static const Color markerLedger = success;

  /// Orange — notes / compliance / documentation / additional info.
  static const Color markerNotes = warning;
}

/// The three intents a section-marker bar can express.
enum SuperMarker {
  /// Blue — identity / definition / details.
  identity(SuperTokens.markerIdentity),

  /// Green — financial / balance / ledger / transfer.
  ledger(SuperTokens.markerLedger),

  /// Orange — notes / compliance / documentation.
  notes(SuperTokens.markerNotes);

  const SuperMarker(this.color);

  /// The bar fill color for this intent.
  final Color color;
}
