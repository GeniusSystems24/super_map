// ============================================================
// core/theme/super_text_styles.dart
// ------------------------------------------------------------
// The GeniusLink type ramp as ready-made TextStyles. Three faces, no
// exceptions: Manrope (display), Inter (the workhorse), JetBrains Mono
// (numerics). Color is left null so each style inherits the surrounding
// `fg*` token — pass `.copyWith(color: t.fg1)` at the call site.
// ============================================================

import 'package:flutter/widgets.dart';

import 'super_tokens.dart';

/// Named text styles. Colorless by design — apply an `fg*` token at use.
abstract final class SuperText {
  /// H1 page title — Manrope 26 / 700 / -0.025em. The only thing that tightens.
  static const TextStyle h1 = TextStyle(
    fontFamily: SuperTokens.displayFont,
    fontSize: 26,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.65,
  );

  /// Section heading — Inter 16 / 700.
  static const TextStyle heading = TextStyle(
    fontFamily: SuperTokens.bodyFont,
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );

  /// Body copy — Inter 14 / 400.
  static const TextStyle body = TextStyle(
    fontFamily: SuperTokens.bodyFont,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  /// Eyebrow / form label / table header — Inter 11 / 700 ALL CAPS, 0.05em.
  /// (Caller upper-cases the text; tracking widens for breadcrumbs to 0.15em.)
  static const TextStyle label = TextStyle(
    fontFamily: SuperTokens.bodyFont,
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.55, // ~0.05em
  );

  /// Breadcrumb / eyebrow — wider tracking variant of [label] (~0.15em).
  static const TextStyle eyebrow = TextStyle(
    fontFamily: SuperTokens.bodyFont,
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.65,
  );

  /// Placeholder / caption — Inter 12 / 400.
  static const TextStyle caption = TextStyle(
    fontFamily: SuperTokens.bodyFont,
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w400,
  );

  /// Button text — Inter 14 / 600.
  static const TextStyle button = TextStyle(
    fontFamily: SuperTokens.bodyFont,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  /// Numerics / serials / references — JetBrains Mono 14 / 400.
  static const TextStyle mono = TextStyle(
    fontFamily: SuperTokens.monoFont,
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w400,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Small status-pill text — Inter 10 / 700 ALL CAPS.
  static const TextStyle pill = TextStyle(
    fontFamily: SuperTokens.bodyFont,
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
}
