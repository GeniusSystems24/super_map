// ============================================================
// core/widgets/status_pill.dart
// ------------------------------------------------------------
// A semantic status pill: 12px radius, 8/4 padding, uppercase 10/700 text in a
// semantic color over a +20% tint of that color. Tones map to the brand
// semantic palette.
// ============================================================

import 'package:flutter/widgets.dart';

import '../extensions/context_extensions.dart';
import '../theme/super_text_styles.dart';
import '../theme/super_tokens.dart';

/// The semantic intent of a [StatusPill].
enum PillTone { neutral, accent, success, warning, danger }

/// A small uppercase status pill.
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.tone = PillTone.neutral});

  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final fg = switch (tone) {
      PillTone.neutral => t.fg3,
      PillTone.accent => SuperTokens.accent,
      PillTone.success => SuperTokens.success,
      PillTone.warning => SuperTokens.warning,
      PillTone.danger => SuperTokens.danger,
    };
    final bg = tone == PillTone.neutral ? t.hover : t.tintFill(fg, 0.20);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SuperTokens.space2,
        vertical: SuperTokens.space1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(SuperTokens.radiusPill),
      ),
      child: Text(label.toUpperCase(), style: SuperText.pill.copyWith(color: fg)),
    );
  }
}
