// ============================================================
// core/widgets/field_shell.dart
// ------------------------------------------------------------
// The shared foundation for every GeniusLink form field (text / numeric /
// attachment …). Renders the uppercase label (with required asterisk), the
// control slot, an optional suffix error badge, and a hint / error line
// beneath. Direction- and density-aware. The control itself is supplied by the
// concrete field — FieldShell owns only the chrome around it.
// ============================================================

import 'package:flutter/widgets.dart';

import '../extensions/context_extensions.dart';
import '../theme/super_text_styles.dart';
import '../theme/super_tokens.dart';

/// Vertical density of a field.
enum FieldDensity { comfortable, compact }

/// The label + control + hint/error chrome around a form control.
class FieldShell extends StatelessWidget {
  const FieldShell({
    super.key,
    this.label,
    this.required = false,
    required this.child,
    this.hint,
    this.error,
    this.density = FieldDensity.comfortable,
    this.disabled = false,
  });

  /// Uppercase field label (rendered ALL CAPS). Null hides the label row.
  final String? label;

  /// Appends a red required asterisk to the label.
  final bool required;

  /// The control (an input, a drop zone…). FieldShell never styles its inside.
  final Widget child;

  /// Helper text under the control when there is no [error].
  final String? hint;

  /// Error message — when non-null, replaces the hint and tints in danger.
  final String? error;

  final FieldDensity density;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final gap = density == FieldDensity.compact ? SuperTokens.space1 : SuperTokens.space2;

    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            _Label(text: label!, required: required, color: t.fg2),
            SizedBox(height: gap),
          ],
          child,
          if (error != null || hint != null) ...[
            SizedBox(height: gap),
            Text(
              error ?? hint!,
              style: SuperText.caption.copyWith(
                color: error != null ? SuperTokens.danger : t.fg3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.required, required this.color});

  final String text;
  final bool required;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = SuperText.label.copyWith(color: color);
    if (!required) return Text(text.toUpperCase(), style: style);
    return Text.rich(
      TextSpan(
        text: text.toUpperCase(),
        style: style,
        children: [
          TextSpan(
            text: ' *',
            style: style.copyWith(color: SuperTokens.danger),
          ),
        ],
      ),
    );
  }
}
