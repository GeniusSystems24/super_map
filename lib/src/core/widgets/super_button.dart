// ============================================================
// core/widgets/super_button.dart
// ------------------------------------------------------------
// The GeniusLink button family. Primary (solid blue), secondary (outlined),
// and icon (32x32). Hover lightens the primary ~6% / fills the secondary;
// press scales to 0.98 and darkens; disabled drops to 40% opacity. 150ms ease.
// ============================================================

import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/super_text_styles.dart';
import '../theme/super_tokens.dart';

enum SuperButtonVariant { primary, secondary }

/// A primary or secondary text button with brand hover/press states.
class SuperButton extends StatefulWidget {
  const SuperButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SuperButtonVariant.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final SuperButtonVariant variant;
  final Widget? icon;

  bool get _enabled => onPressed != null;

  @override
  State<SuperButton> createState() => _SuperButtonState();
}

class _SuperButtonState extends State<SuperButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final primary = widget.variant == SuperButtonVariant.primary;

    Color bg;
    Color fg;
    Border? border;
    if (primary) {
      bg = _down
          ? SuperTokens.accentPressed
          : _hover
              ? SuperTokens.accentHover
              : SuperTokens.accent;
      fg = const Color(0xFFFFFFFF);
    } else {
      bg = _hover ? t.hover : const Color(0x00000000);
      fg = t.fg1;
      border = Border.all(color: t.borderStrong);
    }

    final child = AnimatedScale(
      scale: _down ? 0.98 : 1,
      duration: SuperTokens.durFast,
      curve: SuperTokens.curveStandard,
      child: AnimatedContainer(
        duration: SuperTokens.durBase,
        curve: SuperTokens.curveStandard,
        height: SuperTokens.controlHeight,
        padding: const EdgeInsets.symmetric(horizontal: SuperTokens.space4),
        decoration: BoxDecoration(
          color: bg,
          border: border,
          borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              IconTheme.merge(
                data: IconThemeData(color: fg, size: 16),
                child: widget.icon!,
              ),
              const SizedBox(width: SuperTokens.space2),
            ],
            Text(widget.label, style: SuperText.button.copyWith(color: fg)),
          ],
        ),
      ),
    );

    return Opacity(
      opacity: widget._enabled ? 1 : 0.4,
      child: MouseRegion(
        cursor: widget._enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTapDown: widget._enabled ? (_) => setState(() => _down = true) : null,
          onTapUp: widget._enabled ? (_) => setState(() => _down = false) : null,
          onTapCancel: widget._enabled ? () => setState(() => _down = false) : null,
          onTap: widget.onPressed,
          child: child,
        ),
      ),
    );
  }
}

/// A 32x32 icon button — current bg tints to inputBg on hover, 4px radius.
class SuperIconButton extends StatefulWidget {
  const SuperIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.danger = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  /// When true, the icon trades neutral for danger red on hover.
  final bool danger;

  @override
  State<SuperIconButton> createState() => _SuperIconButtonState();
}

class _SuperIconButtonState extends State<SuperIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.superTheme;
    final enabled = widget.onPressed != null;
    final fg = (_hover && widget.danger) ? SuperTokens.danger : t.fg2;

    Widget button = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: SuperTokens.durBase,
          width: SuperTokens.iconButton,
          height: SuperTokens.iconButton,
          decoration: BoxDecoration(
            color: _hover ? t.inputBg : const Color(0x00000000),
            borderRadius: BorderRadius.circular(SuperTokens.radiusControl),
          ),
          child: Icon(widget.icon, size: 16, color: fg),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }
    return Opacity(opacity: enabled ? 1 : 0.4, child: button);
  }
}
