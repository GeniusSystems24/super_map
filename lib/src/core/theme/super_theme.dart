// ============================================================
// core/theme/super_theme.dart
// ------------------------------------------------------------
// The shared GeniusLink ThemeExtension. Instance fields are the swappable
// surfaces that flip dark <-> light (and lerp on theme change); brand constants
// live in `SuperTokens`. Every component reads its colors from here so the whole
// kit themes from a single source.
//
//   MaterialApp(
//     theme:      ThemeData(extensions: const [SuperThemeData.light]),
//     darkTheme:  ThemeData(extensions: const [SuperThemeData.dark]),
//   );
//   final t = SuperThemeData.of(context);   // falls back to .dark
// ============================================================

import 'package:flutter/material.dart';

import 'super_tokens.dart';

@immutable
class SuperThemeData extends ThemeExtension<SuperThemeData> {
  // ── Swappable surfaces (dark <-> light) ──
  final Color bg; //           page background
  final Color surface; //      card / panel fill
  final Color inputBg; //      input / editing field fill
  final Color hover; //        hover tint
  final Color border; //       hairline borders
  final Color borderStrong; // outer frame / strong dividers
  final Color fg1; //          primary text
  final Color fg2; //          secondary / heading emphasis
  final Color fg3; //          tertiary / subtitles / hints
  final Color fg4; //          quaternary / placeholders / disabled
  final Brightness brightness;

  const SuperThemeData({
    required this.bg,
    required this.surface,
    required this.inputBg,
    required this.hover,
    required this.border,
    required this.borderStrong,
    required this.fg1,
    required this.fg2,
    required this.fg3,
    required this.fg4,
    required this.brightness,
  });

  // ── Card elevation ──
  /// Dark-mode card shadow — lifts panels off the near-black page.
  static const List<BoxShadow> cardShadowDark = [
    BoxShadow(color: Color(0x40000000), blurRadius: 50, spreadRadius: -12, offset: Offset(0, 25)),
  ];

  /// Light-mode card shadow — a subtler two-step stack.
  static const List<BoxShadow> cardShadowLight = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// Overlay / popover shadow (menus, flyouts, suggestion lists).
  static const List<BoxShadow> popShadow = [
    BoxShadow(color: Color(0x59000000), blurRadius: 24, spreadRadius: -6, offset: Offset(0, 10)),
  ];

  /// The card shadow appropriate for this theme's brightness.
  List<BoxShadow> get cardShadow => brightness == Brightness.dark ? cardShadowDark : cardShadowLight;

  // ── Presets ──
  static const SuperThemeData dark = SuperThemeData(
    bg: Color(0xFF111318),
    surface: Color(0xFF1E2025),
    inputBg: Color(0xFF33353A),
    hover: Color(0xFF2F3540),
    border: Color(0x6643464F),
    borderStrong: Color(0xFF434654),
    fg1: Color(0xFFE2E2E9),
    fg2: Color(0xFFC3C6D7),
    fg3: Color(0xFF8D90A0),
    fg4: Color(0xFF5A5D68),
    brightness: Brightness.dark,
  );

  static const SuperThemeData light = SuperThemeData(
    bg: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    inputBg: Color(0xFFF1F3F8),
    hover: Color(0xFFEEF1F7),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFC2C6D6),
    fg1: Color(0xFF0F172A),
    fg2: Color(0xFF424754),
    fg3: Color(0xFF64748B),
    fg4: Color(0xFFAEB4C2),
    brightness: Brightness.light,
  );

  /// Reads the registered extension, falling back to [dark] (the default theme).
  static SuperThemeData of(BuildContext context) =>
      Theme.of(context).extension<SuperThemeData>() ?? dark;

  /// A selection / accent tint at [pct] opacity blended over [surface]
  /// (mirrors the web `color-mix(... accent N%, surface)` highlight).
  Color selectionFill([double pct = 0.10]) =>
      Color.alphaBlend(SuperTokens.accent.withOpacity(pct), surface);

  /// A semantic [base] color softened to a pill background over [surface].
  Color tintFill(Color base, [double pct = 0.20]) =>
      Color.alphaBlend(base.withOpacity(pct), surface);

  @override
  SuperThemeData copyWith({
    Color? bg,
    Color? surface,
    Color? inputBg,
    Color? hover,
    Color? border,
    Color? borderStrong,
    Color? fg1,
    Color? fg2,
    Color? fg3,
    Color? fg4,
    Brightness? brightness,
  }) =>
      SuperThemeData(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        inputBg: inputBg ?? this.inputBg,
        hover: hover ?? this.hover,
        border: border ?? this.border,
        borderStrong: borderStrong ?? this.borderStrong,
        fg1: fg1 ?? this.fg1,
        fg2: fg2 ?? this.fg2,
        fg3: fg3 ?? this.fg3,
        fg4: fg4 ?? this.fg4,
        brightness: brightness ?? this.brightness,
      );

  @override
  SuperThemeData lerp(ThemeExtension<SuperThemeData>? other, double t) {
    if (other is! SuperThemeData) return this;
    return SuperThemeData(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      fg1: Color.lerp(fg1, other.fg1, t)!,
      fg2: Color.lerp(fg2, other.fg2, t)!,
      fg3: Color.lerp(fg3, other.fg3, t)!,
      fg4: Color.lerp(fg4, other.fg4, t)!,
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }
}
